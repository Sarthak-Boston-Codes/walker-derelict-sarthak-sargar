extends SceneTree
## Film-only captures for the A7 film (Claude Code). Not part of the game.
## Windowed; renders the real game into an off-screen 3840x2160 SubViewport
## (2D laid out at 1280x720 and stretched, as the A5/A6 films did) and saves
## one JPG per frame.
##
##   godot --path godot --fixed-fps 30 --script <this file>
##   env MODE = keyplay | reloadplay     OUT = output folder
##
## keyplay: SCRIPTED PLAY, real move input. Before frame 0 the player is
##   placed 3 m south of the keycard in the Boiler Room (disclosed; not
##   filmed). Filmed: the W key (physical 87, through Input.parse_input_event)
##   walks the player north onto the keycard; the pickup's own overlap check
##   picks it up; game.gd calls hud.set_keycard(true); HudAnim starts the spin.
## reloadplay: SCRIPTED PLAY, real fire / R / Escape events. The player
##   stands on the lit Loading Bay floor. Four reloads, each with an interrupt:
##   fire during startup (ignored), R during active (no restart), fire held
##   through recovery (the first shot comes when the reload ends), Escape
##   during a reload (the game's pause: rig and timer freeze) and again.
## Every frame prints "FRAME i ..." with the rig state, clip position, pose,
## magazine, shots, icon state and cell, and whether the tree is paused.

const SIZE := Vector2i(3840, 2160)
const SIZE_2D := Vector2i(1280, 720)

var mode := OS.get_environment("MODE")
var out := OS.get_environment("OUT")
var view: SubViewport
var game: Node
var anim: Node
var n := 0


func _initialize() -> void:
	assert(mode in ["keyplay", "reloadplay"] and out != "", "set MODE and OUT")
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
	game = load("res://game3d/game.tscn").instantiate()
	view.add_child(game)
	for i in 90: # past the start toast
		await process_frame
	game.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	anim = game.hud_anim
	game.player.reload_changed.connect(func(a: bool) -> void: print("EVENT frame %d reload_changed(%s) mag %d" % [n, a, game.player.mag]))
	if mode == "keyplay":
		await _keyplay()
	else:
		await _reloadplay()
	print("saved %d frames" % n)
	quit()


func _aim_at(world: Vector3) -> void:
	var ev := InputEventMouseMotion.new()
	# The camera projects into the 1280x720 2D space; push_input divides by the
	# 3x stretch to 3840x2160, so the event is given in the 4K space.
	ev.position = game.camera.unproject_position(world) * Vector2(SIZE) / Vector2(SIZE_2D)
	ev.global_position = ev.position
	view.push_input(ev)


func _key(physical: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _escape() -> void:
	# The pause action is read by the HUD's _unhandled_input inside the
	# SubViewport, so the event is pushed into that viewport.
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_ESCAPE
		ev.pressed = pressed
		view.push_input(ev)


func _fire(pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _shot() -> void:
	await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_jpg(out.path_join("f%05d.jpg" % n), 0.93)
	n += 1


func _filmed(frames: int, act := Callable()) -> void:
	for i in frames:
		if act.is_valid():
			act.call(n)
		await process_frame
		await _shot()
		var p: Node = game.player
		var rp: AnimationPlayer = anim.rig_player
		print("FRAME %d rig %s clip '%s' %.4f mag_y %.1f slide_x %.1f body %.3f | mag %d shots %d | icon %s cell %d | paused %s" % [
			n - 1, anim.rig_state, rp.current_animation,
			rp.current_animation_position if rp.current_animation != "" else 0.0,
			anim.rig.get_node("Body/Mag").position.y, anim.rig.get_node("Body/Slide").position.x,
			anim.rig.get_node("Body").rotation, p.mag, p.shots_fired, anim.key_state, anim.icon.frame, paused])


func _keyplay() -> void:
	var p: Node3D = game.player
	var kc: Vector3 = game.level.keycard.global_position
	p.global_position = Vector3(kc.x, 0, kc.z + 3.0)
	game.camera.snap()
	_aim_at(Vector3(kc.x, 0.95, kc.z - 2.0))
	for i in 10:
		await process_frame
	print("before filming: player %s, keycard %s" % [p.global_position, kc])
	await _filmed(12)
	_key(KEY_W, true)
	var walked := 0
	while not game.has_keycard and walked < 90:
		await _filmed(1)
		walked += 1
	_key(KEY_W, false)
	print("EVENT frame %d keycard picked up %s after %d frames of W" % [n, game.has_keycard, walked])
	await _filmed(345)


func _reloadplay() -> void:
	var p: Node3D = game.player
	p.global_position = Vector3(-7, 0, 5)
	game.camera.snap()
	var aim := Vector3(-4, 0.95, 3)
	_aim_at(aim)
	for i in 10:
		await process_frame
	# Each act callable runs at the start of a filmed frame (frame index n).
	# Startup interrupt: fire pressed during the first 0.5 s.
	await _filmed(10)
	await _shots(2)
	await _reload_with(func(k: int) -> void:
		if k == 8:
			_fire(true)
		elif k == 13:
			_fire(false), "startup")
	await _shots(1)
	# Active interrupt: a second R between 0.5 s and 1.0 s.
	await _reload_with(func(k: int) -> void:
		if k == 20:
			_key(KEY_R, true)
		elif k == 21:
			_key(KEY_R, false), "active")
	await _shots(1)
	# Recovery interrupt: fire held from 1.0 s on; the shot comes at the end.
	await _reload_with(func(k: int) -> void:
		if k == 31:
			_fire(true)
		elif k == 44:
			_fire(false), "recovery")
	await _filmed(10)
	await _shots(1)
	# Pause during a reload: Escape at 0.4 s, Escape again 1 s later.
	await _reload_with(func(k: int) -> void:
		if k == 12 or k == 42:
			_escape(), "pause")
	await _filmed(15)


func _shots(count: int) -> void:
	var s0: int = game.player.shots_fired
	_fire(true)
	var f := 0
	while game.player.shots_fired - s0 < count and f < 40:
		await _filmed(1)
		f += 1
	_fire(false)
	await _filmed(8)


## Real R; `act(k)` gets the frame count since the R press was parsed.
func _reload_with(act: Callable, label: String) -> void:
	print("EVENT frame %d R pressed (%s interrupt)" % [n, label])
	_key(KEY_R, true)
	var k0 := n
	var f := 0
	while f < 100:
		var k := n - k0
		if k == 1:
			_key(KEY_R, false)
		act.call(k)
		await _filmed(1)
		f += 1
		if f > 5 and anim.rig_state == &"HOLD" and not paused and f > 46:
			break
	await _filmed(6)
