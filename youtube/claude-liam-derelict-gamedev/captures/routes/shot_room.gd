extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 10: await process_frame
	var floor_tex: Texture2D = main.get_node("Floor").texture
	print("floor texture: ", floor_tex.resource_path, " ", floor_tex.get_size())
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_PATH"))
	print("saved")
	quit()
