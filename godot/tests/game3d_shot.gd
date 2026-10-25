extends Node
## Screenshot harness for the 3D game (needs a window, not --headless):
##
##   godot --path godot res://tests/game3d_shot.tscn -- --shot=out.png [--frames=90] [--cam=x,y,z] [--look=x,y,z] [--aim=x,z] [--pos=x,z] [--zombies=N] [--boom=frames] [--scene=res://...] [--fps] [--end=dead|won] [--turn=x,z (re-aim after spawning)]
##
## Loads game3d/game.tscn, waits, optionally moves the camera, saves a PNG.

var _args := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_args[kv[0]] = kv[1] if kv.size() > 1 else ""
	var game: Node = load(str(_args.get("scene", "res://game3d/game.tscn"))).instantiate()
	add_child(game)
	if _args.has("aim"):
		var a: PackedStringArray = str(_args.aim).split(",")
		game.player.controls_enabled = false
		game.player.aim_point = Vector3(float(a[0]), 0.95, float(a[1]))
	if _args.has("pos"):
		var a: PackedStringArray = str(_args.pos).split(",")
		game.player.global_position = Vector3(float(a[0]), 0, float(a[1]))
		game.camera.snap()
	if _args.has("zombies"):
		game.waves.active = false
		var p: Vector3 = game.player.global_position
		var aim: Vector3 = game.player.aim_point - p
		aim.y = 0
		aim = aim.normalized()
		for i in int(_args.zombies):
			var side := aim.cross(Vector3.UP) * (i - int(_args.zombies) / 2.0) * 1.1
			game.waves.spawn_zombie("runner" if i % 2 else "shambler", p + aim * (5.0 + (i % 3)) + side)
	if _args.has("turn"):
		var a: PackedStringArray = str(_args.turn).split(",")
		game.player.aim_point = Vector3(float(a[0]), 0.95, float(a[1]))
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
	if _args.has("boom"):
		var best: Node3D = null
		for b in get_tree().get_nodes_in_group("explosive_barrels"):
			if best == null or b.global_position.distance_to(game.player.global_position) < best.global_position.distance_to(game.player.global_position):
				best = b
		best.explode()
		for i in int(_args.boom):
			await get_tree().process_frame
	if _args.get("end", "") == "dead":
		game.player.take_damage(999, game.player.global_position + Vector3.RIGHT)
		await get_tree().create_timer(2.6).timeout
	elif _args.get("end", "") == "won":
		game.player.global_position = game.level.extraction.global_position
		game._on_extracted()
		await get_tree().create_timer(3.0).timeout
	if _args.has("fps"):
		print("fps %d  process %.1f ms  physics %.1f ms  draw calls %d" % [Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(_args.get("shot", "user://shot.png"))
	print("saved ", _args.get("shot"))
	get_tree().quit()


func _vec(s: String) -> Vector3:
	var p := s.split(",")
	return Vector3(float(p[0]), float(p[1]), float(p[2]))
