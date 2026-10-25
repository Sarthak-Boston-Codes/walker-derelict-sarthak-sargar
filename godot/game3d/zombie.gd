extends CharacterBody3D
## An infected. Paths to the player on the navmesh (with avoidance so packs
## spread out), winds up and swipes when close, flashes and staggers when
## shot, topples and sinks when killed.

signal died(zombie: Node3D)

const ModelTable := preload("res://game3d/model_table.gd")
const ActorAnim := preload("res://game3d/actor_anim.gd")
const Fx := preload("res://game3d/fx.gd")
const Sfx := preload("res://game3d/sfx.gd")
const Phys := preload("res://game3d/phys.gd")

const TYPES := {
	"shambler": {"model": "zombie_shambler", "hp": 4.0, "speed": 1.9, "damage": 18.0, "windup": 0.5, "reach": 1.35, "stagger": 0.35},
	"runner": {"model": "zombie_runner", "hp": 2.0, "speed": 4.4, "damage": 9.0, "windup": 0.25, "reach": 1.2, "stagger": 0.18},
}
const REPATH := 0.3
const AMMO_DROP_CHANCE := 0.3
const PUSH_IMPULSE := 7.0 # per physics frame; enough to shove a barrel aside
const STUCK_CHECK := 1.5 # seconds between progress checks
const STUCK_MIN_MOVE := 0.4 # metres expected per check while chasing
const Pickup := preload("res://game3d/pickup.gd")
const ATTACK_COOLDOWN := 0.9
const RISE_TIME := 0.7

enum State { RISING, CHASE, WINDUP, RECOVER, DEAD }

var kind := "shambler"
var hp := 1.0
var state := State.RISING

var _stats: Dictionary
var _agent: NavigationAgent3D
var _model: Node3D
var _player: Node3D
var _repath_left := 0.0
var _state_left := RISE_TIME
var _stagger_left := 0.0
var _flash_left := 0.0
var _walk_phase := randf() * TAU
var _knock := Vector3.ZERO
var _safe_velocity := Vector3.ZERO
var _stuck_check := STUCK_CHECK
var _stuck_from := Vector3.ZERO
var _sidestep := Vector3.ZERO
var _sidestep_left := 0.0
var _flash_mat := StandardMaterial3D.new()


func _ready() -> void:
	add_to_group("zombies")
	_stats = TYPES[kind]
	hp = _stats.hp
	collision_layer = Phys.ZOMBIE
	collision_mask = Phys.WORLD | Phys.PLAYER | Phys.ZOMBIE | Phys.PROP
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.7
	cs.shape = shape
	cs.position.y = 0.85
	add_child(cs)
	_model = ModelTable.make(_stats.model)
	add_child(_model)
	_agent = NavigationAgent3D.new()
	_agent.path_desired_distance = 0.7
	_agent.target_desired_distance = 0.8
	_agent.radius = 0.45
	_agent.height = 1.7
	_agent.max_speed = _stats.speed * 1.2
	_agent.avoidance_enabled = true
	_agent.neighbor_distance = 4.0
	_agent.velocity_computed.connect(func(v: Vector3) -> void: _safe_velocity = v)
	add_child(_agent)
	_flash_mat.albedo_color = Color(1, 1, 1, 0.8)
	_flash_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_player = get_tree().get_first_node_in_group("player")
	# Claw up out of the floor.
	_model.position.y = -1.6
	Fx.dust(global_position, 16)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return
	_tick_state(delta)
	var desired := Vector3.ZERO
	if state == State.CHASE and _stagger_left <= 0.0 and _player_alive():
		desired = _chase_velocity(delta)
	_agent.velocity = desired
	var move := _safe_velocity if desired != Vector3.ZERO else Vector3.ZERO
	_knock = _knock.move_toward(Vector3.ZERO, 18.0 * delta)
	velocity = Vector3(move.x, velocity.y, move.z) + _knock
	velocity.y = 0.0 if is_on_floor() else velocity.y - 20.0 * delta
	move_and_slide()
	_push_bodies()
	_face(desired if desired != Vector3.ZERO else _to_player(), delta)


func _process(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_set_overlay(null)
	if state == State.DEAD:
		return
	var speed := Vector2(velocity.x, velocity.z).length()
	_walk_phase += speed * delta * (2.6 if kind == "shambler" else 2.0)
	ActorAnim.walk(_model, _walk_phase, clampf(speed / _stats.speed, 0.0, 1.0), false)
	ModelTable.play_anim(_model, ["run", "walk"] if speed > 0.3 else ["idle"])


func _tick_state(delta: float) -> void:
	_stagger_left -= delta
	_state_left -= delta
	match state:
		State.RISING:
			_model.position.y = lerpf(-1.6, 0.0, 1.0 - clampf(_state_left / RISE_TIME, 0.0, 1.0))
			if _state_left <= 0.0:
				_model.position.y = 0.0
				state = State.CHASE
		State.CHASE:
			if _player_alive() and _to_player().length() < _stats.reach and _stagger_left <= 0.0:
				state = State.WINDUP
				_state_left = _stats.windup
				_arms(0.9)
				Sfx.play_at("SFX-DOWN", global_position, 0.5 if kind == "shambler" else 0.7, -6.0) # growl
		State.WINDUP:
			if _state_left <= 0.0:
				_arms(-0.5)
				if _player_alive() and _to_player().length() < _stats.reach + 0.45:
					_player.take_damage(_stats.damage, global_position)
				state = State.RECOVER
				_state_left = ATTACK_COOLDOWN
		State.RECOVER:
			if _state_left <= 0.0:
				_arms(0.0)
				state = State.CHASE


func _chase_velocity(delta: float) -> Vector3:
	var to_player := _to_player()
	# Wedged on a prop or another zombie: step sideways for a moment.
	_stuck_check -= delta
	if _stuck_check <= 0.0:
		_stuck_check = STUCK_CHECK
		if global_position.distance_to(_stuck_from) < STUCK_MIN_MOVE and to_player.length() > _stats.reach + 0.5:
			var side := to_player.normalized().cross(Vector3.UP) * (1.0 if randf() < 0.5 else -1.0)
			_sidestep = (side + to_player.normalized() * 0.3).normalized() * _stats.speed
			_sidestep_left = 0.7
			_repath_left = 0.0
		_stuck_from = global_position
	if _sidestep_left > 0.0:
		_sidestep_left -= delta
		return _sidestep
	# Close and in plain sight: go straight for them (navmesh corners make
	# the last metre look robotic).
	if to_player.length() < 3.0:
		return to_player.normalized() * _stats.speed
	_repath_left -= delta
	if _repath_left <= 0.0:
		_repath_left = REPATH * randf_range(0.8, 1.2)
		_agent.target_position = _player.global_position
	if _agent.is_navigation_finished():
		return to_player.normalized() * _stats.speed
	var next := _agent.get_next_path_position() - global_position
	next.y = 0.0
	return next.normalized() * _stats.speed if next.length() > 0.01 else Vector3.ZERO


func _to_player() -> Vector3:
	if not is_instance_valid(_player):
		return Vector3.ZERO
	var d := _player.global_position - global_position
	d.y = 0.0
	return d


func _player_alive() -> bool:
	return is_instance_valid(_player) and _player.alive


func _face(dir: Vector3, delta: float) -> void:
	if dir.length() < 0.05:
		return
	var yaw := atan2(-dir.x, -dir.z)
	_model.rotation.y = lerp_angle(_model.rotation.y, yaw, 1.0 - exp(-10.0 * delta))


## Attack pose: raise (x > 0), strike (x < 0) or rest (0). Placeholders
## swing their arm pivots; rigless real models rear back and lunge instead.
func _arms(x: float) -> void:
	var found := false
	for arm in ["ArmL", "ArmR"]:
		var n := _model.find_child(arm, true, false) as Node3D
		if n:
			found = true
			n.create_tween().tween_property(n, "rotation:x", x, 0.12)
	if not found and _model.get_child_count() > 0:
		var body := _model.get_child(0) as Node3D
		body.create_tween().tween_property(body, "position:z", x * (0.18 if x > 0.0 else 0.6), 0.12)


func _push_bodies() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var body := c.get_collider() as RigidBody3D
		if body:
			var push := -c.get_normal()
			push.y = 0.0
			body.apply_central_impulse(push.normalized() * PUSH_IMPULSE)


## Bullet / blast entry point.
func hit(damage: float, point: Vector3, dir: Vector3, _normal: Vector3) -> void:
	if state == State.DEAD:
		return
	hp -= damage
	var flat := Vector3(dir.x, 0, dir.z).normalized()
	Fx.blood(point, flat)
	_flash_left = 0.08
	_set_overlay(_flash_mat)
	_knock = flat * (2.5 if kind == "shambler" else 4.0)
	_stagger_left = _stats.stagger
	if state == State.WINDUP:
		state = State.RECOVER # a hit interrupts the swipe
		_state_left = 0.3
		_arms(0.0)
	if hp <= 0.0:
		_die(flat)


func _die(dir: Vector3) -> void:
	state = State.DEAD
	remove_from_group("zombies")
	collision_layer = 0
	collision_mask = Phys.WORLD
	_agent.avoidance_enabled = false
	Sfx.play_at("SFX-DOWN", global_position, 1.0 if kind == "shambler" else 1.25)
	Fx.blood(global_position + Vector3.UP * 1.0, dir, 30)
	Fx.decal(global_position + dir * 0.8, randf_range(1.6, 2.4))
	died.emit(self)
	if randf() < AMMO_DROP_CHANCE:
		var ammo := Pickup.new()
		ammo.kind = "ammo"
		ammo.amount = Vector2i(5, 9)
		get_parent().add_child(ammo)
		ammo.global_position = global_position + dir * 0.4
	# Topple away from the shot, then sink into the floor.
	var away := atan2(-dir.x, -dir.z)
	_model.rotation.y = away + PI
	var t := create_tween()
	t.tween_property(_model, "rotation:x", deg_to_rad(85.0), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(self, "global_position", global_position + dir * 0.6, 0.45)
	for e in _model.find_children("Eye", "MeshInstance3D", true, false):
		var em := (e as MeshInstance3D).material_override as StandardMaterial3D
		create_tween().tween_property(em, "emission_energy_multiplier", 0.0, 0.8)
	for g in _model.find_children("EyeGlow", "OmniLight3D", true, false):
		create_tween().tween_property(g, "light_energy", 0.0, 0.8)
	t.tween_interval(3.0)
	t.tween_property(_model, "position:y", -0.8, 1.5)
	t.tween_callback(queue_free)


func _set_overlay(m: Material) -> void:
	for mi in ModelTable.meshes_of(_model):
		mi.material_overlay = m
