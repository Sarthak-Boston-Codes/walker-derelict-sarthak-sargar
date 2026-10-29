extends Node
## Presentation-only driver for the low-ammo tint (CHANGE-BRIEF.md section 2).
## Reads the magazine through player.ammo_changed and writes one thing: the
## `low_ammo` uniform on the ammo label's own ShaderMaterial. Never writes
## game state.

const SHADER := preload("res://shaders/low_ammo.gdshader")
const PARAM := &"low_ammo"
const THRESHOLD := 5
const RATE_UP := 4.0 # per second: 0 -> 1 in 0.25 s
const RATE_DOWN := 2.0 # per second: 1 -> 0 in 0.5 s

var material: ShaderMaterial
var value := 0.0
var target := 0.0


func _ready() -> void:
	# The HUD runs while paused; this must not (R6), and it uses scaled
	# delta so Engine.time_scale applies (R5).
	process_mode = Node.PROCESS_MODE_PAUSABLE
	# After the player has fired this frame, so the change shows at once.
	process_priority = 100


## Gives `label` a ShaderMaterial of its own and listens to `player`.
func setup(label: CanvasItem, player: Node) -> void:
	material = ShaderMaterial.new()
	material.shader = SHADER
	label.material = material
	player.ammo_changed.connect(_on_ammo_changed)
	_on_ammo_changed(player.mag, player.reserve)
	material.set_shader_parameter(PARAM, value)


func _on_ammo_changed(mag: int, _reserve: int) -> void:
	target = 1.0 if mag <= THRESHOLD else 0.0


func _process(delta: float) -> void:
	if value == target:
		return
	# Moves from wherever it is, so a retrigger extends (R4, R7).
	value = move_toward(value, target, (RATE_UP if target > value else RATE_DOWN) * delta)
	material.set_shader_parameter(PARAM, value)
