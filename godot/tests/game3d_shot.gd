extends Node
## Screenshot harness for the 3D game (needs a window, not --headless):
##
##   godot --path godot res://tests/game3d_shot.tscn -- --shot=out.png [--frames=90] [--cam=x,y,z] [--look=x,y,z]
##
## Loads game3d/game.tscn, waits, optionally moves the camera, saves a PNG.

var _args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var game: Node = load("res://game3d/game.tscn").instantiate()
	add_child(game)
	for i in int(_args.get("frames", "90")):
		await get_tree().process_frame
	if _args.has("cam"):
		var cam := get_viewport().get_camera_3d()
		cam.set_process(false)
		if cam.get_parent().has_method("set_process"):
			cam.get_parent().set_process(false)
		cam.global_position = _vec(_args.cam)
		cam.look_at(_vec(_args.get("look", "0,0,0")), Vector3.UP)
		for i in 10:
			await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_args.get("shot", "user://shot.png"))
	print("saved ", _args.get("shot"))
	get_tree().quit()


func _vec(s: String) -> Vector3:
	var p := s.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))
