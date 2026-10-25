extends Node3D
## Root of the top-down 3D game: builds the level, spawns the player and
## camera, and owns the run state.

const Level := preload("res://game3d/level.gd")
const Player := preload("res://game3d/player.gd")
const CameraRig := preload("res://game3d/camera_rig.gd")
const Sfx := preload("res://game3d/sfx.gd")
const Fx := preload("res://game3d/fx.gd")

var level: Node3D
var player: CharacterBody3D
var camera: Camera3D


func _ready() -> void:
	add_to_group("game")
	var sfx := Sfx.new()
	sfx.name = "Sfx"
	add_child(sfx)
	level = Level.new()
	level.name = "Level"
	add_child(level)
	var fx_root := Node3D.new()
	fx_root.name = "Fx"
	add_child(fx_root)
	Fx.root = fx_root
	Fx.clear()

	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.global_position = level.player_start
	camera = CameraRig.new()
	camera.name = "Camera"
	camera.target = player
	add_child(camera)
	camera.current = true
	player.camera = camera
	player.aim_point = level.player_start + Vector3(0, 0, -4)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_music"):
		Sound.toggle_muted(Sound.MUSIC_BUS)
	elif event.is_action_pressed("toggle_sfx"):
		Sound.toggle_muted(Sound.SFX_BUS)
