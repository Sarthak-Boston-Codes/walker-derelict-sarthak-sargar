extends SceneTree
## Pins for A7 (CHANGE-BRIEF.md "Pins to take before any change").
## Written by Claude Code, committed before any clip is wired. Headless,
## through the real game loop and real input:
##
##   bash scripts/run-test.sh test_pins_player.gd 60
##
## Every input is an InputEvent resolved from project.godot's input map and
## sent through Input.parse_input_event (R = physical key 82, fire = mouse
## button 1, aim = mouse motion in window pixels). Nothing calls
## start_reload(), fire() or Input.action_press.
##
## Pins: (a) the player's state order for one scripted run: READY, FIRE
## (down to a lower magazine), RELOAD, READY (refilled), FIRE; (b)
## FIRE_INTERVAL 0.14 s (constant, and the measured gap between shots),
## RELOAD_TIME 1.25 s as the game-time gap between reload_changed(true)
## and reload_changed(false), MAG_SIZE 15; (c) the refill happens at
## reload_changed(false) and fire (and a second reload press) is locked
## until then. Every event line carries its process frame so a windowed
## Movie Maker run of this script lines up with the frames.
## Exit 1 on any FAIL.

const PLAYER_PATH := "res://game3d/player.gd"

var _failures := 0
var game: Node
var player: Node
var dt := 0.0
var t0_frame := 0
var events: Array[Dictionary] = [] # {what, frame, mag, reserve}
var states: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func frames(n: int) -> void:
	for i in n:
		await process_frame


func f() -> int:
	return Engine.get_process_frames() - t0_frame


func _state(s: String) -> void:
	if states.is_empty() or states[-1] != s:
		states.append(s)


func _log(what: String) -> void:
	var e := {"what": what, "frame": f(), "mag": player.mag, "reserve": player.reserve}
	events.append(e)
	print("  [frame %4d] %-22s mag %2d reserve %2d" % [e.frame, what, e.mag, e.reserve])


# --- real input ---------------------------------------------------------------

func _key(physical: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _mouse_pos(world: Vector3) -> Vector2:
	return root.get_final_transform() * game.camera.unproject_position(world)


func _aim_at(world: Vector3) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = _mouse_pos(world)
	ev.global_position = ev.position
	Input.parse_input_event(ev)


func _fire_button(pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = _mouse_pos(player.aim_point)
	ev.global_position = ev.position
	Input.parse_input_event(ev)


## The key and button the input map binds, read from project.godot.
func _bound(action: String) -> Array:
	var out := []
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			out.append("key %d" % (e as InputEventKey).physical_keycode)
		elif e is InputEventMouseButton:
			out.append("mouse %d" % (e as InputEventMouseButton).button_index)
	return out


# --- run ----------------------------------------------------------------------

func _run() -> void:
	print("\n== test_pins_player ==")
	dt = 1.0 / Engine.physics_ticks_per_second if Engine.max_fps == 0 else 1.0 / Engine.max_fps
	check(_bound("reload").has("key %d" % KEY_R), "input map: reload is physical key R (82) %s" % [_bound("reload")])
	check(_bound("fire").has("mouse %d" % MOUSE_BUTTON_LEFT), "input map: fire is mouse button 1 %s" % [_bound("fire")])
	_check_constants()

	game = load("res://game3d/game.tscn").instantiate()
	root.add_child(game)
	await frames(10)
	game.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	player = game.player
	await frames(2)
	t0_frame = Engine.get_process_frames()
	# Frame length as the game sees it: --fixed-fps 60 gives 1/60.
	var t_before := Time.get_ticks_usec()
	dt = player.get_process_delta_time()
	print("  process delta %.6f s (%.1f fps)" % [dt, 1.0 / dt])

	player.ammo_changed.connect(func(mag: int, _r: int) -> void:
		_log("ammo_changed %d" % mag))
	player.reload_changed.connect(func(active: bool) -> void:
		_log("reload_changed(%s)" % active)
		_state("RELOAD" if active else "READY"))
	player.died.connect(func() -> void:
		_log("died")
		_state("DEAD"))

	# (a) READY at rest.
	check(player.alive and not player.is_reloading() and player.mag == player.MAG_SIZE,
			"start: alive, not reloading, mag %d = MAG_SIZE" % player.mag)
	_state("READY")

	# Aim ahead (real mouse motion), then hold fire for 5 shots.
	var ahead: Vector3 = player.global_position + Vector3(0, 0.95, -4)
	_aim_at(ahead)
	await frames(3)
	var shots0: int = player.shots_fired
	_fire_button(true)
	var shot_frames: Array[int] = []
	var last_shots := shots0
	for i in 120:
		await process_frame
		if player.shots_fired != last_shots:
			last_shots = player.shots_fired
			shot_frames.append(f())
			_state("FIRE")
		if player.shots_fired - shots0 >= 5:
			break
	_fire_button(false)
	await frames(2)
	check(player.shots_fired - shots0 == 5 and player.mag == 10,
			"fire held: 5 real shots, mag 15 -> %d" % player.mag)
	var gaps: Array[int] = []
	for i in range(1, shot_frames.size()):
		gaps.append(shot_frames[i] - shot_frames[i - 1])
	var expect_gap := ceili(player.FIRE_INTERVAL / dt - 1e-4)
	var all_ok := gaps.size() == 4
	for g in gaps:
		all_ok = all_ok and g == expect_gap
	check(all_ok, "FIRE_INTERVAL: shots %s frames apart = %.4f s (0.14 s rounded up to whole frames: %d)" % [gaps, (gaps[0] if gaps.size() > 0 else 0) * dt, expect_gap])

	# Reload with the R key.
	var mag_before: int = player.mag
	var reserve_before: int = player.reserve
	_key(KEY_R, true)
	var press_frame := f()
	# A parsed event is flushed at the start of the next frame, where the
	# player's _process sees is_action_just_pressed("reload").
	for i in 5:
		await process_frame
		if _index("reload_changed(true)") >= 0:
			break
	_key(KEY_R, false)
	var t_true := _last_frame("reload_changed(true)")
	print("  R parsed after frame %d, reload_changed(true) on frame %d" % [press_frame, t_true])
	check(t_true >= 0 and player.is_reloading(), "R pressed: reload_changed(true) at frame %d, is_reloading()" % t_true)

	# (c) during the reload: fire held, then a second R press. Both ignored.
	var shots_mid: int = player.shots_fired
	_fire_button(true)
	await frames(20)
	_fire_button(false)
	await frames(2)
	check(player.shots_fired == shots_mid and player.mag == mag_before,
			"fire locked mid-reload: 0 shots in 20 frames of held fire, mag still %d" % player.mag)
	_key(KEY_R, true)
	await frames(1)
	_key(KEY_R, false)
	await frames(2)
	check(_count("reload_changed(true)") == 1, "a second R press mid-reload does not restart it (reload_changed(true) x%d)" % _count("reload_changed(true)"))
	check(player.mag == mag_before and player.reserve == reserve_before,
			"no refill before reload_changed(false): mag %d reserve %d" % [player.mag, player.reserve])

	# Wait for the end.
	for i in 120:
		await process_frame
		if not player.is_reloading():
			break
	var t_false := _last_frame("reload_changed(false)")
	var gap_frames := t_false - t_true
	var gap_s := gap_frames * dt
	check(t_false > t_true, "reload_changed(false) at frame %d" % t_false)
	check(absf(gap_s - player.RELOAD_TIME) <= dt + 1e-6,
			"RELOAD_TIME: reload_changed(true) -> (false) = %d frames = %.4f s (1.25 s within one frame)" % [gap_frames, gap_s])
	print("  reload gap %d frames at %.1f fps (1.25 s = %.2f frames)" % [gap_frames, 1.0 / dt, player.RELOAD_TIME / dt])
	# The refill is reported on the same frame as reload_changed(false).
	var e_false: Dictionary = events[_index("reload_changed(false)")]
	check(e_false.mag == player.MAG_SIZE and e_false.reserve == reserve_before - (player.MAG_SIZE - mag_before),
			"refill at reload_changed(false): mag %d -> %d, reserve %d -> %d" % [mag_before, e_false.mag, reserve_before, e_false.reserve])
	var e_ammo := _first_after("ammo_changed", t_true - 1)
	check(not e_ammo.is_empty() and e_ammo.frame == t_false and e_ammo.what == "ammo_changed 15",
			"the first ammo_changed after the reload starts is the refill, on the same frame (%s)" % [e_ammo])

	# Fire works again after the reload.
	var shots_after: int = player.shots_fired
	_fire_button(true)
	await frames(2)
	_fire_button(false)
	await frames(2)
	if player.shots_fired > shots_after:
		_state("FIRE")
	check(player.shots_fired == shots_after + 1 and player.mag == player.MAG_SIZE - 1,
			"after the reload a fire press fires (mag %d)" % player.mag)

	# (a) the state order.
	var want: Array[String] = ["READY", "FIRE", "RELOAD", "READY", "FIRE"]
	check(states == want, "state order %s (pinned %s)" % [states, want])
	var _unused := t_before

	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	game.queue_free()
	await process_frame
	quit(1 if _failures > 0 else 0)


func _check_constants() -> void:
	var p: GDScript = load(PLAYER_PATH)
	var c := p.get_script_constant_map()
	check(is_equal_approx(c.get("FIRE_INTERVAL", -1.0), 0.14), "FIRE_INTERVAL = %s (pinned 0.14)" % c.get("FIRE_INTERVAL"))
	check(is_equal_approx(c.get("RELOAD_TIME", -1.0), 1.25), "RELOAD_TIME = %s (pinned 1.25)" % c.get("RELOAD_TIME"))
	check(c.get("MAG_SIZE", -1) == 15, "MAG_SIZE = %s (pinned 15)" % c.get("MAG_SIZE"))


func _index(what: String) -> int:
	for i in range(events.size() - 1, -1, -1):
		if events[i].what == what:
			return i
	return -1


func _last_frame(what: String) -> int:
	var i := _index(what)
	return events[i].frame if i >= 0 else -1


func _count(what: String) -> int:
	var n := 0
	for e in events:
		if e.what == what:
			n += 1
	return n


func _first_after(prefix: String, frame: int) -> Dictionary:
	for e in events:
		if e.frame > frame and String(e.what).begins_with(prefix):
			return e
	return {}
