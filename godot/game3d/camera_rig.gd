extends Camera3D
## Fixed-angle top-down camera: follows `target` smoothly, leans a little
## towards where the player aims, and shakes from accumulated trauma.

const OFFSET := Vector3(0, 14.5, 6.5)
const FOLLOW_SPEED := 6.0
const LOOK_AHEAD := 0.22 # fraction of the aim vector
const MAX_LOOK_AHEAD := 3.5
const MAX_SHAKE_OFFSET := 0.7
const MAX_SHAKE_ROLL := 0.05

var target: Node3D
## Where the player is aiming (world space), set by the player each frame.
var aim_point := Vector3.ZERO
var trauma := 0.0

var _focus := Vector3.ZERO
var _noise := FastNoiseLite.new()
var _t := 0.0


func _ready() -> void:
	fov = 45.0
	far = 120.0
	_noise.frequency = 2.5
	if target:
		snap()


func snap() -> void:
	_focus = target.global_position
	_place(Vector3.ZERO, 0.0)


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	_t += delta
	var lead := (aim_point - target.global_position) * LOOK_AHEAD
	lead.y = 0.0
	lead = lead.limit_length(MAX_LOOK_AHEAD)
	var goal := target.global_position + lead
	_focus = _focus.lerp(goal, 1.0 - exp(-FOLLOW_SPEED * delta))
	trauma = maxf(trauma - delta * 1.6, 0.0)
	var s := trauma * trauma
	var shake := Vector3(_noise.get_noise_2d(_t * 40.0, 0.0), 0.0, _noise.get_noise_2d(0.0, _t * 40.0)) * MAX_SHAKE_OFFSET * s
	_place(shake, _noise.get_noise_2d(_t * 40.0, 50.0) * MAX_SHAKE_ROLL * s)


func _place(shake: Vector3, roll: float) -> void:
	global_position = _focus + OFFSET + shake
	look_at(_focus + shake, Vector3.UP)
	rotate_object_local(Vector3.FORWARD, roll)


## Mouse position projected onto the horizontal plane at `height`.
func mouse_on_plane(height: float) -> Variant:
	var mouse := get_viewport().get_mouse_position()
	var origin := project_ray_origin(mouse)
	var dir := project_ray_normal(mouse)
	return Plane(Vector3.UP, height).intersects_ray(origin, dir)
