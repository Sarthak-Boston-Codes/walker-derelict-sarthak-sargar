extends Area3D
## Walk-over pickup: "medkit" heals, "ammo" adds reserve rounds, "keycard"
## unlocks the control room. Bobs, spins and glows so it reads in the dark.
## Stays put if it would do nothing (full health / full ammo).

signal picked(kind: String)

const ModelTable := preload("res://game3d/model_table.gd")
const Fx := preload("res://game3d/fx.gd")
const Sfx := preload("res://game3d/sfx.gd")
const Phys := preload("res://game3d/phys.gd")

const HEAL := 40.0
const AMMO := Vector2i(12, 20)
const GLOW := {
	"medkit": Color("#7CFFB0"),
	"ammo": Color("#F2C14E"),
	"keycard": Color("#2BD9FF"),
}

var kind := "medkit"
var bob := true
## Rounds an ammo pickup gives (random in range). Zombie drops give fewer.
var amount := AMMO

var _model: Node3D
var _t := randf() * TAU
var _check_left := 0.0
var _taken := false


func _ready() -> void:
	add_to_group("pickups")
	collision_layer = Phys.PICKUP
	collision_mask = Phys.PLAYER
	monitorable = false
	var cs := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 1.0 if kind == "keycard" else 0.8
	cs.shape = shape
	cs.position.y = 0.5
	add_child(cs)
	_model = ModelTable.make({"medkit": "medkit", "ammo": "ammo_box", "keycard": "keycard"}[kind])
	add_child(_model)
	var light := OmniLight3D.new()
	light.light_color = GLOW[kind]
	light.light_energy = 1.4 if kind == "keycard" else 0.6
	light.omni_range = 2.5 if kind == "keycard" else 1.4
	light.position.y = 0.5
	add_child(light)


func _process(delta: float) -> void:
	_t += delta
	if bob:
		_model.position.y = 0.06 + sin(_t * 2.5) * 0.05
		_model.rotation.y += delta * (1.6 if kind == "keycard" else 0.8)
	_check_left -= delta
	if _check_left <= 0.0 and not _taken:
		_check_left = 0.2
		for body in get_overlapping_bodies():
			if body.is_in_group("player"):
				try_pick(body)


func try_pick(player: Node3D) -> bool:
	if _taken or not player.alive:
		return false
	var used := false
	match kind:
		"medkit":
			used = player.heal(HEAL)
		"ammo":
			used = player.add_ammo(randi_range(amount.x, amount.y))
		"keycard":
			used = true
	if not used:
		return false
	_taken = true
	Sfx.play("SFX-CLEAR", 1.6 if kind != "keycard" else 1.0, -6.0 if kind != "keycard" else 0.0)
	Fx.flash_light(global_position + Vector3.UP * 0.6, GLOW[kind], 3.0, 4.0, 0.35)
	picked.emit(kind)
	var t := create_tween()
	t.tween_property(_model, "scale", Vector3.ONE * 0.01, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	t.tween_callback(queue_free)
	return true
