extends CharacterBody3D
## The survivor: WASD to move, mouse to aim, hold left click to fire,
## R to reload, F to toggle the flashlight.
##
## Anything a bullet can damage implements
##   hit(damage: float, point: Vector3, dir: Vector3, normal: Vector3)

signal health_changed(hp: float, max_hp: float)
signal ammo_changed(mag: int, reserve: int)
signal reload_changed(active: bool)
signal hurt
signal died

const ModelTable := preload("res://game3d/model_table.gd")
const ActorAnim := preload("res://game3d/actor_anim.gd")
const Fx := preload("res://game3d/fx.gd")
const Sfx := preload("res://game3d/sfx.gd")
const Phys := preload("res://game3d/phys.gd")

const SPEED := 5.2
const ACCEL := 16.0
const TURN_SPEED := 22.0
const MAX_HP := 100.0
const MAG_SIZE := 15
const START_RESERVE := 60
const MAX_RESERVE := 150
const FIRE_INTERVAL := 0.14
const RELOAD_TIME := 1.25
const DAMAGE := 1.0
const SPREAD := 0.03 # radians
const SHOT_RANGE := 40.0
const SHOT_HEIGHT := 0.95
const HURT_GRACE := 0.3 # seconds of invulnerability after a hit
const PUSH_FORCE := 1.4 # impulse into barrels per metre/second

var hp := MAX_HP
var mag := MAG_SIZE
var reserve := START_RESERVE
var alive := true
var controls_enabled := true
var camera: Camera3D
var aim_point := Vector3.ZERO
var flashlight: SpotLight3D
## Run stats for the end screen.
var shots_fired := 0
var shots_hit := 0
## Test hook: when set (non-null), used instead of WASD.
var move_override: Variant = null

var _aim: Node3D
var _model: Node3D
var _muzzle: Node3D
var _muzzle_light: OmniLight3D
var _flash_mesh: MeshInstance3D
var _overlay := StandardMaterial3D.new()
var _cooldown := 0.0
var _reload_left := 0.0
var _flash_left := 0.0
var _walk_phase := 0.0
var _recoil := 0.0
var _grace := 0.0
var _hurt_left := 0.0
var _knock := Vector3.ZERO


func _ready() -> void:
	add_to_group("player")
	collision_layer = Phys.PLAYER
	collision_mask = Phys.WORLD | Phys.ZOMBIE | Phys.PROP
	var cs := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.8
	cs.shape = shape
	cs.position.y = 0.9
	add_child(cs)

	_aim = Node3D.new()
	_aim.name = "Aim"
	add_child(_aim)
	_model = ModelTable.make("player")
	_aim.add_child(_model)

	_muzzle = Node3D.new()
	_muzzle.position = Vector3(0.05, 1.35, -0.78)
	_aim.add_child(_muzzle)
	_muzzle_light = OmniLight3D.new()
	_muzzle_light.light_color = Color("#FFB347")
	_muzzle_light.omni_range = 6.0
	_muzzle_light.light_energy = 0.0
	_muzzle_light.shadow_enabled = true
	_muzzle.add_child(_muzzle_light)
	_flash_mesh = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.45, 0.45)
	_flash_mesh.mesh = quad
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.albedo_color = Color(4.0, 2.6, 1.0)
	_flash_mesh.material_override = fm
	_flash_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_flash_mesh.visible = false
	_muzzle.add_child(_flash_mesh)

	flashlight = SpotLight3D.new()
	flashlight.name = "Flashlight"
	flashlight.position = Vector3(-0.07, 1.4, -0.5)
	flashlight.rotation_degrees.x = -14.0
	flashlight.light_color = Color("#FFE6B0")
	flashlight.light_energy = 16.0
	flashlight.spot_range = 22.0
	flashlight.spot_angle = 27.0
	flashlight.spot_angle_attenuation = 0.7
	flashlight.spot_attenuation = 0.6
	flashlight.shadow_enabled = true
	flashlight.shadow_blur = 1.5
	flashlight.light_volumetric_fog_energy = 1.2
	_aim.add_child(flashlight)
	# Faint fill so the player never vanishes in the dark.
	var fill := OmniLight3D.new()
	fill.position = Vector3(0, 2.2, 0)
	fill.light_color = Color("#B8C4D6")
	fill.light_energy = 0.5
	fill.omni_range = 3.5
	add_child(fill)

	_overlay.albedo_color = Color(1, 0.1, 0.1, 0.55)
	_overlay.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_overlay.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED


func _physics_process(delta: float) -> void:
	_grace = maxf(_grace - delta, 0.0)
	var input := Vector2.ZERO
	if alive and move_override != null:
		input = move_override
	elif alive and controls_enabled:
		input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var want := Vector3(input.x, 0, input.y) * SPEED
	var horizontal := Vector3(velocity.x, 0, velocity.z).move_toward(want, ACCEL * SPEED * delta / 4.0)
	_knock = _knock.move_toward(Vector3.ZERO, 30.0 * delta)
	velocity = Vector3(horizontal.x, velocity.y, horizontal.z) + _knock
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	velocity -= _knock
	_push_bodies()


func _push_bodies() -> void:
	for i in get_slide_collision_count():
		var c := get_slide_collision(i)
		var body := c.get_collider() as RigidBody3D
		if body:
			var push := -c.get_normal()
			push.y = 0.0
			body.apply_impulse(push.normalized() * PUSH_FORCE * maxf(velocity.length(), 1.0), c.get_position() - body.global_position)


func _process(delta: float) -> void:
	_cooldown -= delta
	_update_aim(delta)
	_update_weapon(delta)
	_animate(delta)


func _update_aim(delta: float) -> void:
	if camera == null or not alive:
		return
	if controls_enabled:
		var p: Variant = camera.mouse_on_plane(SHOT_HEIGHT)
		if p != null:
			aim_point = p
	camera.aim_point = aim_point
	var d := aim_point - global_position
	d.y = 0.0
	if d.length() > 0.2:
		var yaw := atan2(-d.x, -d.z)
		_aim.rotation.y = lerp_angle(_aim.rotation.y, yaw, 1.0 - exp(-TURN_SPEED * delta))


func _update_weapon(delta: float) -> void:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_flash_mesh.visible = false
	_muzzle_light.light_energy = maxf(_muzzle_light.light_energy - delta * 120.0, 0.0)
	if not alive:
		return
	if _reload_left > 0.0:
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()
	if not controls_enabled:
		return
	if Input.is_action_just_pressed("flashlight"):
		flashlight.visible = not flashlight.visible
		Sfx.play("SFX-SHOT", 3.0, -18.0)
	if _reload_left > 0.0:
		return
	if Input.is_action_just_pressed("reload"):
		start_reload()
	elif Input.is_action_pressed("fire") and _cooldown <= 0.0:
		if mag > 0:
			fire()
		elif reserve > 0:
			start_reload()
		elif Input.is_action_just_pressed("fire"):
			Sfx.play("SFX-SHOT", 2.6, -14.0) # dry click


func start_reload() -> void:
	if _reload_left > 0.0 or mag >= MAG_SIZE or reserve <= 0:
		return
	_reload_left = RELOAD_TIME
	Sfx.play("SFX-DOWN", 1.8, -8.0)
	reload_changed.emit(true)


func is_reloading() -> bool:
	return _reload_left > 0.0


func reload_progress() -> float:
	return 1.0 - _reload_left / RELOAD_TIME if _reload_left > 0.0 else 1.0


func _finish_reload() -> void:
	var take := mini(MAG_SIZE - mag, reserve)
	mag += take
	reserve -= take
	_reload_left = 0.0
	Sfx.play("SFX-SHOT", 1.6, -12.0)
	reload_changed.emit(false)
	ammo_changed.emit(mag, reserve)


func fire() -> void:
	_cooldown = FIRE_INTERVAL
	mag -= 1
	shots_fired += 1
	ammo_changed.emit(mag, reserve)
	var origin := global_position + Vector3.UP * SHOT_HEIGHT
	var target := aim_point
	var under: Variant = _target_under_mouse()
	if under != null:
		target = under
	var dir := target - origin
	if Vector2(dir.x, dir.z).length() < 0.6:
		dir = -_aim.global_basis.z
	dir = dir.normalized().rotated(Vector3.UP, randf_range(-SPREAD, SPREAD))
	var end := origin + dir * SHOT_RANGE
	var q := PhysicsRayQueryParameters3D.create(origin, end, Phys.SHOT_MASK, [get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit:
		end = hit.position
		var target_node: Object = hit.collider
		if target_node.has_method("hit"):
			if target_node.is_in_group("zombies"):
				shots_hit += 1
			target_node.hit(DAMAGE, end, dir, hit.normal)
		else:
			Fx.sparks(end, hit.normal)
	Fx.tracer(_muzzle.global_position, end)
	_flash_mesh.visible = true
	_flash_mesh.rotation.z = randf() * TAU
	_flash_left = 0.045
	_muzzle_light.light_energy = 5.0
	_recoil = 1.0
	Sfx.play("SFX-SHOT", 1.0, -3.0)
	if camera:
		camera.add_trauma(0.06)


## If the cursor is over a zombie or prop, the 3D point on it; lets you
## shoot things lower or higher than the default aim plane (e.g. crates).
func _target_under_mouse() -> Variant:
	if camera == null:
		return null
	var mouse := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var q := PhysicsRayQueryParameters3D.create(from, from + camera.project_ray_normal(mouse) * 100.0, Phys.WORLD | Phys.ZOMBIE | Phys.PROP)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if hit and (hit.collider as CollisionObject3D).collision_layer & (Phys.ZOMBIE | Phys.PROP):
		return hit.position
	return null


func take_damage(amount: float, from: Vector3) -> void:
	if not alive or _grace > 0.0:
		return
	_grace = HURT_GRACE
	hp = maxf(hp - amount, 0.0)
	health_changed.emit(hp, MAX_HP)
	hurt.emit()
	var away := global_position - from
	away.y = 0.0
	_knock = away.normalized() * 7.0
	Fx.blood(global_position + Vector3.UP * 1.1, away.normalized(), 10)
	Sfx.play("SFX-HURT")
	_hurt_left = 0.12
	if camera:
		camera.add_trauma(0.5)
	if hp <= 0.0:
		_die()


func heal(amount: float) -> bool:
	if hp >= MAX_HP or not alive:
		return false
	hp = minf(hp + amount, MAX_HP)
	health_changed.emit(hp, MAX_HP)
	return true


func add_ammo(amount: int) -> bool:
	if reserve >= MAX_RESERVE:
		return false
	reserve = mini(reserve + amount, MAX_RESERVE)
	ammo_changed.emit(mag, reserve)
	return true


func _die() -> void:
	alive = false
	_reload_left = 0.0
	Fx.decal(global_position, 2.2)
	var t := create_tween().set_parallel()
	t.tween_property(_model, "rotation:x", deg_to_rad(80.0), 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_property(_model, "position:y", 0.25, 0.6)
	t.tween_property(flashlight, "light_energy", 1.5, 1.2)
	died.emit()


func _animate(delta: float) -> void:
	var flat := Vector3(velocity.x, 0, velocity.z)
	var speed := flat.length()
	_walk_phase += speed * delta * 2.4
	if alive:
		ActorAnim.walk(_model, _walk_phase, clampf(speed / SPEED, 0.0, 1.0), false)
		ModelTable.play_anim(_model, ["run", "walk"] if speed > 0.5 else ["idle"])
	_recoil = move_toward(_recoil, 0.0, delta * 10.0)
	if alive:
		_model.position.z = _recoil * 0.08
	if _hurt_left > 0.0:
		_hurt_left -= delta
		_set_overlay(_overlay if _hurt_left > 0.0 else null)


func _set_overlay(m: Material) -> void:
	for mi in ModelTable.meshes_of(_model):
		mi.material_overlay = m
