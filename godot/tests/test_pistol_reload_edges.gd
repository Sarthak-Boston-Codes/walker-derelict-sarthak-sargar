extends SceneTree
## Edge test for the pistol reload (CHANGE-BRIEF.md phase table, predicted
## failure 9). Written by Claude Code. Headless, real game loop, at 60 fps:
##
##   bash scripts/run-test.sh test_pistol_reload_edges.gd 60
##
## Tick 0 is the process frame on which reload_changed(true) fires. The
## phase boundaries 0.5 s, 1.0 s and 1.25 s are ticks 30, 60 and 75. At
## each, an interrupt lands one tick before, on, and one tick after:
##   fire   - a real mouse-button press held for exactly that tick (parsed
##            one tick earlier, because a parsed event is seen on the next
##            frame): ignored, magazine unchanged until the refill;
##   reload - a real R press seen on that tick: does not restart the clip
##            (no second reload_changed(true), clip position keeps rising);
##   death  - player.take_damage(999) on that tick (the game's own damage
##            path, called directly because enemy contact cannot be timed
##            to one tick; game3d_smoke_test calls it the same way): the
##            clip stops and the pose resets on the same tick (or next).
## Then: at tick 75 the reload ends, the state returns to HOLD, and a fire
## press on tick 76 fires.
## Exit 1 on any FAIL. Requires --fixed-fps 60 (ticks are 1/60 s).

const BOUNDARIES := [30, 60, 75]
const OFFSETS := [-1, 0, 1]

var _failures := 0
var game: Node
var anim: Node
var player: Node
var f0 := -1
var n_true := 0
var n_false := 0
var false_tick := -1


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func frames(n: int) -> void:
	for i in n:
		await process_frame


func tick() -> int:
	return Engine.get_process_frames() - f0


func _run() -> void:
	print("\n== test_pistol_reload_edges ==")
	await _fresh_game()
	var dt: float = player.get_process_delta_time()
	check(absf(dt - 1.0 / 60.0) < 1e-6, "running at 60 fps (delta %.6f): ticks 30/60/75 = 0.5/1.0/1.25 s" % dt)
	for b in BOUNDARIES:
		for o in OFFSETS:
			await _case_fire(b + o)
	for b in BOUNDARIES:
		for o in OFFSETS:
			await _case_reload(b + o)
	for b in BOUNDARIES:
		for o in OFFSETS:
			await _fresh_game()
			await _case_death(b + o)
	await _fresh_game()
	await _case_end_then_fire()
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	if game:
		game.queue_free()
	await process_frame
	quit(1 if _failures > 0 else 0)


# --- helpers ------------------------------------------------------------------

func _fresh_game() -> void:
	if game:
		game.queue_free()
		await frames(2)
	game = load("res://game3d/game.tscn").instantiate()
	root.add_child(game)
	await frames(10)
	game.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	anim = game.hud_anim
	player = game.player
	player.reload_changed.connect(func(a: bool) -> void:
		if a:
			n_true += 1
			f0 = Engine.get_process_frames()
		else:
			n_false += 1
			false_tick = tick())
	await frames(2)


func _key_event(physical: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _fire_event(pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = root.get_final_transform() * game.camera.unproject_position(player.aim_point)
	ev.global_position = ev.position
	Input.parse_input_event(ev)


## One real shot (so the magazine is below MAG_SIZE), then a real R press;
## returns when reload_changed(true) has fired (tick 0).
func _start_reload() -> bool:
	if player.mag >= player.MAG_SIZE:
		var s0: int = player.shots_fired
		_fire_event(true)
		for i in 30:
			await process_frame
			if player.shots_fired > s0:
				break
		_fire_event(false)
		await frames(12) # past FIRE_INTERVAL
	var t0 := n_true
	_key_event(KEY_R, true)
	for i in 5:
		await process_frame
		if n_true > t0:
			break
	_key_event(KEY_R, false)
	false_tick = -1
	return n_true == t0 + 1


func _pose() -> Array:
	return [anim.rig.get_node("Body/Mag").position.y, anim.rig.get_node("Body/Slide").position.x, anim.rig.get_node("Body").rotation]


func _at_rest() -> bool:
	var p := _pose()
	return is_zero_approx(p[0]) and is_zero_approx(p[1]) and is_zero_approx(p[2])


## Runs ticks until tick `last`. `act` is called at the start of each tick
## (after process_frame, before nodes process that tick). Returns per-tick
## samples taken at the start of the following tick: state at end of tick.
func _run_ticks(last: int, act: Callable) -> Dictionary:
	var out := {}
	# We are at the start of tick 1 relative to f0 (the loop above returned
	# right after reload_changed(true) on tick 0's await).
	while true:
		var k := tick()
		out[k - 1] = {"mag": player.mag, "shots": player.shots_fired, "state": anim.rig_state,
				"clip": anim.rig_player.current_animation, "pos": anim.rig_player.current_animation_position if anim.rig_player.current_animation != "" else -1.0,
				"rest": _at_rest(), "alive": player.alive}
		if k > last:
			break
		act.call(k)
		await process_frame
	return out


# --- cases --------------------------------------------------------------------

func _case_fire(at: int) -> void:
	var ok := await _start_reload()
	if not ok:
		check(false, "fire @%d: reload started" % at)
		return
	var mag0: int = player.mag
	var shots0: int = player.shots_fired
	var s := await _run_ticks(80, func(k: int) -> void:
		if k == at - 1:
			_fire_event(true)
		elif k == at:
			_fire_event(false))
	var first_shot := -1
	var mag_ok := true
	for k in range(0, 81):
		if not s.has(k):
			continue
		if first_shot < 0 and s[k].shots > shots0:
			first_shot = k
		if k < false_tick and s[k].mag != mag0:
			mag_ok = false
	var expect_shot := at >= 75
	if expect_shot:
		check(first_shot == at and false_tick == 75 and s[at].mag == player.MAG_SIZE - 1,
				"fire @%d: after the refill (tick %d) the press fires on its own tick (shot tick %d, mag %d)" % [at, false_tick, first_shot, s[at].mag if s.has(at) else -1])
	else:
		check(first_shot == -1, "fire @%d: ignored during the reload (no shot; shot tick %d)" % [at, first_shot])
	check(mag_ok, "fire @%d: magazine stays %d until the refill at tick %d" % [at, mag0, false_tick])
	await frames(12)


func _case_reload(at: int) -> void:
	var ok := await _start_reload()
	if not ok:
		check(false, "reload @%d: reload started" % at)
		return
	var t0 := n_true
	var s := await _run_ticks(80, func(k: int) -> void:
		if k == at - 1:
			_key_event(KEY_R, true)
		elif k == at:
			_key_event(KEY_R, false))
	check(n_true == t0, "reload @%d: the second R press starts no reload (reload_changed(true) +%d)" % [at, n_true - t0])
	# Not restarted: the position at the end of tick k is exactly (k - 1)/60
	# for every tick of the reload (the AnimationPlayer shows position 0 on
	# the tick play() is called and on the next, then advances; measured in
	# test_two_clocks.gd). A restart would drop it back toward 0.
	var rising := true
	var worst := 0.0
	for k in range(1, 75):
		if not s.has(k) or s[k].clip != "reload":
			rising = false
			continue
		worst = maxf(worst, absf(s[k].pos - (k - 1) / 60.0))
	rising = rising and worst < 1e-4
	check(rising, "reload @%d: the clip is not restarted (position = (tick - 1)/60 on every tick 1..74, largest error %.6f s)" % [at, worst])
	check(false_tick == 75 and s[75].state == &"HOLD", "reload @%d: the reload still ends at tick 75 in HOLD (end tick %d)" % [at, false_tick])
	await frames(2)


func _case_death(at: int) -> void:
	var ok := await _start_reload()
	if not ok:
		check(false, "death @%d: reload started" % at)
		return
	var at_death := {}
	var s := await _run_ticks(at + 3, func(k: int) -> void:
		if k == at:
			player.take_damage(999.0, player.global_position + Vector3.RIGHT)
			# Mutate, not assign: a lambda captures the outer local by value.
			at_death.merge({"state": anim.rig_state, "clip": anim.rig_player.current_animation,
					"playing": anim.rig_player.is_playing(), "rest": _at_rest(), "alive": player.alive}))
	check(not at_death.is_empty() and not at_death.alive, "death @%d: the player died on tick %d" % [at, at])
	check(at_death.get("state") == &"DEAD" and at_death.get("clip") == "" and not at_death.get("playing", true),
			"death @%d: the clip stops on the same tick (state %s, clip '%s')" % [at, at_death.get("state"), at_death.get("clip")])
	check(at_death.get("rest", false), "death @%d: the pose is reset on the same tick" % at)
	var later_ok: bool = s.has(at) and s[at].state == &"DEAD" and s[at].rest and s[at].clip == ""
	if s.has(at + 2):
		later_ok = later_ok and s[at + 2].state == &"DEAD" and s[at + 2].rest
	check(later_ok, "death @%d: still DEAD at rest two ticks later" % at)
	var refilled: bool = false_tick >= 0
	check(refilled == (at > 75), "death @%d: refill %s (reload end tick %d)" % [at, "happened before the death" if at > 75 else "never happens", false_tick])


func _case_end_then_fire() -> void:
	print("  -- the end of the reload, then fire on tick 76 --")
	var ok := await _start_reload()
	check(ok, "reload started")
	var shots0: int = player.shots_fired
	var s := await _run_ticks(78, func(k: int) -> void:
		if k == 75:
			_fire_event(true)
		elif k == 76:
			_fire_event(false))
	check(false_tick == 75, "the reload ends on tick 75 (reload_changed(false) on tick %d)" % false_tick)
	check(s[74].state == &"RELOAD" and s[75].state == &"HOLD", "tick 74 RELOAD, tick 75 HOLD (%s, %s)" % [s[74].state, s[75].state])
	check(s[75].clip == "" and s[75].rest, "tick 75: clip stopped at the RESET pose")
	check(s[75].mag == player.MAG_SIZE, "tick 75: magazine refilled (%d)" % s[75].mag)
	check(s[75].shots == shots0 and s[76].shots == shots0 + 1 and s[76].mag == player.MAG_SIZE - 1,
			"a fire press seen on tick 76 fires on tick 76 (mag %d)" % s[76].mag)
