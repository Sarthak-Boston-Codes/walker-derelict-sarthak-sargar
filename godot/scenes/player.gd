extends CharacterBody2D
## The scavenger. One state at a time; each state shows exactly one art ID.
##
## Entry points for other scenes:
##   take_hit(from_position) -- an infected touched us (zombie, step 4)
##   celebrate()             -- reached the exit (exit marker, step 5)

signal state_changed(art_id: String)

enum State { IDLE, WALK, AIM, SHOOT_FOLLOWTHROUGH, HURT, GRABBED_FAIL, RECOVER, CELEBRATE }

const STATE_ART := {
	State.IDLE: "CHAR-IDLE",
	State.WALK: "CHAR-WALK",
	State.AIM: "CHAR-AIM",
	State.SHOOT_FOLLOWTHROUGH: "CHAR-SHOOT-FOLLOWTHROUGH",
	State.HURT: "CHAR-HURT",
	State.GRABBED_FAIL: "CHAR-GRABBED-FAIL",
	State.RECOVER: "CHAR-RECOVER",
	State.CELEBRATE: "CHAR-CELEBRATE",
}

const Facing := preload("res://scenes/facing.gd")

@export var walk_speed := 140.0
@export var aim_speed := 60.0
## Time in AIM before a shot is allowed (pillar 2: visible beat before firing).
## Follow-through always returns to AIM, which restarts this wind-up, so the
## minimum time between shots -- the per-shot cooldown -- is
## followthrough_time + aim_windup.
@export var aim_windup := 0.25
@export var followthrough_time := 0.3
@export var shot_range := 900.0
@export var hurt_time := 0.3
@export var grabbed_time := 1.0
@export var recover_time := 0.5
## Extra invulnerability after RECOVER ends (CHANGE-BRIEF: ~1 s).
@export var post_hit_invuln := 1.0
## Most the sprite tilts toward the facing direction (see facing.gd).
@export var max_tilt_deg := 30.0

var state := State.IDLE
var _facing_dir := Vector2.RIGHT
var _state_time := 0.0
var _invuln_left := 0.0
var _fire_requested := false

@onready var _body: Sprite2D = $Body
@onready var _ray: RayCast2D = $ShotRay
@onready var _tracer: Line2D = $Tracer
@onready var _threat_arrow: Polygon2D = $ThreatArrow
@onready var _ready_cue: Line2D = $ReadyCue


func _ready() -> void:
	_enter(State.IDLE)


func _unhandled_input(event: InputEvent) -> void:
	# _unhandled_input, not polling: a click the HUD consumes never gets here.
	# One press event = one request, so holding the button can't refire.
	if event.is_action_pressed("fire"):
		_fire_requested = true


func _physics_process(delta: float) -> void:
	_state_time += delta
	_invuln_left = maxf(0.0, _invuln_left - delta)
	var move := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = Vector2.ZERO

	match state:
		State.IDLE, State.WALK, State.AIM:
			if Input.is_action_pressed("aim"):
				if state != State.AIM:
					_enter(State.AIM)
				_face(_aim_dir())
				_ready_cue.rotation = _aim_dir().angle()
				velocity = move * aim_speed
				if _fire_requested and _state_time >= aim_windup:
					_fire()
			else:
				var next := State.WALK if move != Vector2.ZERO else State.IDLE
				if state != next:
					_enter(next)
				if move != Vector2.ZERO:
					_face(move)
				velocity = move * walk_speed
		State.SHOOT_FOLLOWTHROUGH:
			if _state_time >= followthrough_time:
				_enter(State.AIM if Input.is_action_pressed("aim") else State.IDLE)
		State.HURT:
			if _state_time >= hurt_time:
				_enter(State.GRABBED_FAIL)
		State.GRABBED_FAIL:
			if _state_time >= grabbed_time:
				_enter(State.RECOVER)
		State.RECOVER:
			# Control returns here (walk only, no aiming) -- Storyboard panel 6.
			velocity = move * walk_speed
			if move != Vector2.ZERO:
				_face(move)
			if _state_time >= recover_time:
				_invuln_left = post_hit_invuln
				_enter(State.IDLE)
		State.CELEBRATE:
			pass

	# Never buffer a click across frames: a press that didn't fire is dropped.
	_fire_requested = false
	# Ready cue: shown only while a click right now would fire.
	_ready_cue.visible = state == State.AIM and _state_time >= aim_windup
	_body.modulate.a = 0.55 if _invuln_left > 0.0 else 1.0
	move_and_slide()


## Returns true if the hit landed (so the attacker can react, e.g. knock back).
func take_hit(from_position: Vector2) -> bool:
	if _invuln_left > 0.0 or state in [State.HURT, State.GRABBED_FAIL, State.RECOVER, State.CELEBRATE]:
		return false
	_enter(State.HURT)
	# Pillar 4: the arrow points at whoever hit us.
	_threat_arrow.rotation = (from_position - global_position).angle()
	Sound.play_sfx("SFX-HURT")
	return true


func celebrate() -> void:
	if state != State.CELEBRATE:
		_enter(State.CELEBRATE)


func art_id() -> String:
	return STATE_ART[state]


func is_invulnerable() -> bool:
	return _invuln_left > 0.0


func _fire() -> void:
	var dir := _aim_dir()
	_ray.target_position = dir * shot_range
	_ray.force_raycast_update()
	var end := global_position + dir * shot_range
	if _ray.is_colliding():
		end = _ray.get_collision_point()
		var target := _ray.get_collider()
		if target.has_method("take_shot"):
			target.take_shot()
	_tracer.points = [global_position, end]
	_enter(State.SHOOT_FOLLOWTHROUGH)
	Sound.play_sfx("SFX-SHOT")


func _aim_dir() -> Vector2:
	var to_mouse := get_global_mouse_position() - global_position
	return to_mouse.normalized() if to_mouse.length() > 1.0 else _facing_dir


func _face(dir: Vector2) -> void:
	_facing_dir = dir.normalized()
	Facing.apply(_body, dir, deg_to_rad(max_tilt_deg))


func _enter(next: State) -> void:
	state = next
	_state_time = 0.0
	_body.texture = Assets.texture(STATE_ART[next])
	_threat_arrow.visible = next in [State.HURT, State.GRABBED_FAIL]
	_tracer.visible = next == State.SHOOT_FOLLOWTHROUGH
	state_changed.emit(STATE_ART[next])
