extends Node3D
## Root of the top-down 3D game. Step 1: level plus a pannable camera.

const Level := preload("res://game3d/level.gd")

var level: Node3D
var camera: Camera3D


func _ready() -> void:
	level = Level.new()
	level.name = "Level"
	add_child(level)
	camera = Camera3D.new()
	camera.fov = 50.0
	add_child(camera)
	camera.position = level.player_start + Vector3(0, 16, 9)
	camera.look_at(level.player_start, Vector3.UP)
	camera.current = true


func _process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	camera.position += Vector3(dir.x, 0, dir.y) * 12.0 * delta
