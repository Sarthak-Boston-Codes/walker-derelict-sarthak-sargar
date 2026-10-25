extends StaticBody3D
## Security door between the boiler room and the control room. Walk up to
## it with the keycard and it unlocks: keypad lights go green, the slab
## sinks into the floor, and the navmesh is rebaked so zombies can follow.
## It lives on WORLD under the nav region so the first bake treats it as a
## wall.

signal approached_locked
signal opened

const Phys := preload("res://game3d/phys.gd")
const P := preload("res://game3d/placeholder_models.gd")
const Sfx := preload("res://game3d/sfx.gd")

const TRIGGER_DIST := 2.6

var size := Vector3(0.3, 2.4, 3.0)
var is_open := false
## Set by game.gd.
var has_key: Callable = func() -> bool: return false

var _slab: MeshInstance3D
var _lights: Array[OmniLight3D] = []
var _lamps: Array[MeshInstance3D] = []
var _nag_left := 0.0
var _player: Node3D


func _ready() -> void:
	collision_layer = Phys.WORLD
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	cs.position.y = size.y / 2.0
	add_child(cs)
	_slab = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	_slab.mesh = mesh
	_slab.material_override = P.mat(Color("#5A3A2A"), 0.55, 0.7)
	_slab.position.y = size.y / 2.0
	add_child(_slab)
	# Riveted bands so it reads as a heavy door.
	for y in [0.4, 1.2, 2.0]:
		var band := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(size.x + 0.06, 0.12, size.z)
		band.mesh = bm
		band.material_override = P.mat(Color("#2A2C2B"), 0.4, 0.8)
		band.position.y = y - size.y / 2.0
		_slab.add_child(band)
	for side in [-1, 1]:
		var lamp := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.08, 0.25, 0.18)
		lamp.mesh = lm
		lamp.material_override = P.glow(Color("#FF2A1A"), 4.0)
		lamp.position = Vector3(side * 0.42, 1.4, size.z / 2.0 + 0.35)
		add_child(lamp)
		_lamps.append(lamp)
		var l := OmniLight3D.new()
		l.light_color = Color("#FF2A1A")
		l.light_energy = 1.5
		l.omni_range = 3.0
		l.position = Vector3(side * 0.8, 1.6, 0)
		add_child(l)
		_lights.append(l)


func _physics_process(delta: float) -> void:
	if is_open:
		return
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	_nag_left -= delta
	var d := Vector2(_player.global_position.x - global_position.x, _player.global_position.z - global_position.z).length()
	if d > TRIGGER_DIST:
		return
	if has_key.call():
		open()
	elif _nag_left <= 0.0:
		_nag_left = 3.0
		Sfx.play("SFX-HURT", 0.6, -10.0) # denied buzz
		approached_locked.emit()


func open() -> void:
	if is_open:
		return
	is_open = true
	for l in _lights:
		l.light_color = Color("#3BE07A")
	for lamp in _lamps:
		lamp.material_override = P.glow(Color("#3BE07A"), 4.0)
	Sfx.play("SFX-CLEAR", 0.8, 2.0)
	var t := create_tween()
	t.tween_interval(0.3)
	t.tween_property(_slab, "position:y", -size.y / 2.0 + 0.05, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func() -> void:
		collision_layer = 0
		opened.emit())
