extends Node3D
## The freight lift out. Once powered (door open), stand on it for
## HOLD_TIME seconds to extract. Stepping off resets the countdown.

signal progress_changed(seconds_left: float)
signal extracted

const P := preload("res://game3d/placeholder_models.gd")

const SIZE := 4.0
const HOLD_TIME := 4.0

var powered := false
var done := false
var time_left := HOLD_TIME

var _beacon: SpotLight3D
var _pad_light: OmniLight3D
var _player: Node3D


func _ready() -> void:
	var plate := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(SIZE, 0.08, SIZE)
	plate.mesh = pm
	plate.material_override = P.mat(Color("#4A5258"), 0.45, 0.8)
	plate.position.y = 0.04
	add_child(plate)
	# Hazard border and grating lines.
	var stripes := StandardMaterial3D.new()
	stripes.albedo_color = Color("#D9A42B")
	for i in 4:
		var edge := MeshInstance3D.new()
		var em := BoxMesh.new()
		em.size = Vector3(SIZE, 0.1, 0.18) if i < 2 else Vector3(0.18, 0.1, SIZE)
		edge.mesh = em
		edge.material_override = stripes
		edge.position = Vector3(0, 0.05, (SIZE / 2.0 - 0.09) * (1 if i == 0 else -1)) if i < 2 else Vector3((SIZE / 2.0 - 0.09) * (1 if i == 2 else -1), 0.05, 0)
		add_child(edge)
	for x in range(-3, 4):
		var line := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.04, 0.09, SIZE - 0.5)
		line.mesh = lm
		line.material_override = P.mat(Color("#1C1C1C"), 0.6, 0.5)
		line.position = Vector3(x * 0.5, 0.05, 0)
		add_child(line)
	# Beacon post with a rotating light.
	var post := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.08
	cm.bottom_radius = 0.1
	cm.height = 2.0
	post.mesh = cm
	post.material_override = P.mat(Color("#2A2C2B"), 0.5, 0.7)
	post.position = Vector3(SIZE / 2.0 + 0.3, 1.0, -SIZE / 2.0 - 0.3)
	add_child(post)
	_beacon = SpotLight3D.new()
	_beacon.position = post.position + Vector3(0, 1.1, 0)
	_beacon.spot_angle = 25.0
	_beacon.spot_range = 9.0
	_beacon.light_energy = 0.0
	_beacon.light_color = Color("#3BE07A")
	_beacon.rotation_degrees.x = -35.0
	add_child(_beacon)
	_pad_light = OmniLight3D.new()
	_pad_light.position.y = 1.5
	_pad_light.omni_range = 4.0
	_pad_light.light_energy = 0.0
	_pad_light.light_color = Color("#3BE07A")
	add_child(_pad_light)


func power_on() -> void:
	powered = true
	_beacon.light_energy = 6.0
	_pad_light.light_energy = 1.2


func _process(delta: float) -> void:
	if not powered or done:
		return
	_beacon.rotation.y += delta * 3.0
	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return
	var local := _player.global_position - global_position
	var on_pad: bool = absf(local.x) < SIZE / 2.0 and absf(local.z) < SIZE / 2.0 and _player.alive
	if on_pad:
		time_left = maxf(time_left - delta, 0.0)
		_pad_light.light_energy = 1.2 + sin(time_left * 12.0) * 0.6
		progress_changed.emit(time_left)
		if time_left <= 0.0:
			done = true
			extracted.emit()
	elif time_left < HOLD_TIME:
		time_left = HOLD_TIME
		progress_changed.emit(time_left)


func player_on_pad() -> bool:
	return time_left < HOLD_TIME
