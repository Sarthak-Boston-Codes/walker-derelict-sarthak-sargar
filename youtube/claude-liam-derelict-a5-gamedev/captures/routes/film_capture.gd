extends SceneTree
## Film-only captures for the A5 film (Claude Code). Not part of the game.
## Windowed; renders into an off-screen 3840x2160 SubViewport (2D laid out at
## 1280x720, as godot/tools/a5_capture.gd) and saves frames from it.
##
##   godot --path godot --fixed-fps 30 --script <this file>
##   env MODE = playclip | floor     OUT = output folder
##
## playclip: SCRIPTED PLAY with real input (Input.action_press fire/reload, a
##   mouse-motion event pushed into the viewport for aim). Fire down to 5,
##   hold, reload, hold. One JPG per frame; prints the per-frame low_ammo and
##   mag as "FRAME i mag low_ammo".
## floor: STAGED STILL. The player is placed by the script just inside the
##   Boiler Room doorway, flashlight aimed back into the Assembly Hall, so the
##   wet and dry floors meet in frame.

const SIZE := Vector2i(3840, 2160)
const SIZE_2D := Vector2i(1280, 720)

var mode := OS.get_environment("MODE")
var out := OS.get_environment("OUT")
var view: SubViewport
var n := 0


func _initialize() -> void:
	assert(mode in ["playclip", "floor"] and out != "", "set MODE and OUT")
	DirAccess.make_dir_recursive_absolute(out)
	view = SubViewport.new()
	view.size = SIZE
	view.size_2d_override = SIZE_2D
	view.size_2d_override_stretch = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	_run.call_deferred()


func _run() -> void:
	var game: Node = load("res://game3d/game.tscn").instantiate()
	view.add_child(game)
	for i in 30:
		await process_frame
	game.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	if mode == "floor":
		await _floor(game)
	else:
		await _playclip(game)
	quit()


func _aim(screen_2d: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = screen_2d
	ev.global_position = screen_2d
	view.push_input(ev)


func _shot(img_name := "") -> void:
	await RenderingServer.frame_post_draw
	var img := view.get_texture().get_image()
	if img_name != "":
		img.save_png(out.path_join(img_name))
	else:
		img.save_jpg(out.path_join("f%05d.jpg" % n), 0.93)
		n += 1


func _frame(game: Node) -> void:
	await process_frame
	_aim(Vector2(640, 250))
	await _shot()
	var mat: ShaderMaterial = game.hud._ammo_label.material
	print("FRAME %d mag %d low_ammo %.4f" % [n - 1, game.player.mag, float(mat.get_shader_parameter("low_ammo"))])


func _playclip(game: Node) -> void:
	var p: Node = game.player
	for i in 15:
		await _frame(game)
	while p.mag > 5:
		Input.action_press("fire")
		await _frame(game)
	Input.action_release("fire")
	for i in 45:
		await _frame(game)
	await process_frame
	Input.action_press("reload")
	await _frame(game)
	Input.action_release("reload")
	while p.mag <= 5:
		await _frame(game)
	for i in 30:
		await _frame(game)
	print("saved %d frames" % n)


func _floor(game: Node) -> void:
	var p: Node = game.player
	p.controls_enabled = false
	p.global_position = Vector3(21.0, 0.0, -1.6)
	p.aim_point = Vector3(21.0, 0.95, 4.0)
	game.camera.snap()
	for i in 150: # past the 2.5 s start toast
		await process_frame
	await _shot("floor_doorway.png")
	print("saved floor_doorway.png, player at %s" % p.global_position)
