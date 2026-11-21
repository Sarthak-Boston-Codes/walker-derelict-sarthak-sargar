extends SceneTree
## State test for HudAnim (CHANGE-BRIEF.md "The state machine", predicted
## failure 3). Written by Claude Code. Headless, real game loop:
##
##   bash scripts/run-test.sh test_hud_anim_state.gd 60
##
## Input is real: InputEventKey (R = physical 82, Escape = pause) and
## InputEventMouseButton (fire = button 1) through Input.parse_input_event.
## Death is real enemy contact (a shambler's own swipe). The keycard is
## picked up by placing the player on it (fixture: the same placement
## game3d_smoke_test uses; the pickup's own overlap check does the rest).
##
## Proves: RELOAD plays 'reload' on reload_changed(true); the clip runs to
## its end and the state returns to HOLD at the RESET pose; pausing
## mid-reload freezes the clip position (and the game's reload timer), and
## unpausing continues from there; death mid-reload stops the clip and
## resets the pose on the died signal; the keycard pickup starts the spin.
## Cannot prove headless: what any of it looks like (nothing is drawn),
## that the rig is legible or registered, or how it feels in play.
## Exit 1 on any FAIL.

var _failures := 0
var game: Node
var anim: Node
var player: Node
var events: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func frames(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	print("\n== test_hud_anim_state ==")
	await _scenario_reload_runs_to_end()
	await _scenario_pause_mid_reload()
	await _scenario_keycard()
	await _scenario_death_mid_reload()
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	if game:
		game.queue_free()
	await process_frame
	quit(1 if _failures > 0 else 0)


# --- helpers ------------------------------------------------------------------

func _fresh_game() -> void:
	if game:
		_fire(false)
		game.queue_free()
		await frames(2)
	if paused:
		paused = false
	events.clear()
	game = load("res://game3d/game.tscn").instantiate()
	root.add_child(game)
	await frames(10)
	game.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	anim = game.hud_anim
	player = game.player
	player.reload_changed.connect(func(a: bool) -> void:
		events.append({"what": "reload_changed(%s)" % a, "frame": Engine.get_process_frames()}))
	player.died.connect(func() -> void:
		events.append({"what": "died", "frame": Engine.get_process_frames(),
				"state": anim.rig_state, "clip": anim.rig_player.current_animation,
				"playing": anim.rig_player.is_playing(), "pose": _pose()}))
	await frames(2)


func _key(physical: Key) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.pressed = true
	Input.parse_input_event(ev)
	await frames(1)
	var up := InputEventKey.new()
	up.physical_keycode = physical
	up.pressed = false
	Input.parse_input_event(up)


func _fire(pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = root.get_final_transform() * game.camera.unproject_position(player.aim_point)
	ev.global_position = ev.position
	Input.parse_input_event(ev)


## Fires `n` real shots (so a reload is allowed: mag < MAG_SIZE).
func _shots(n: int) -> void:
	var s0: int = player.shots_fired
	_fire(true)
	for i in 200:
		await process_frame
		if player.shots_fired - s0 >= n:
			break
	_fire(false)
	await frames(2)


## Real R press; waits until reload_changed(true) arrives (the event is seen
## by the player on the next frame).
func _reload() -> int:
	var n0 := _count("reload_changed(true)")
	await _key(KEY_R)
	for i in 5:
		if _count("reload_changed(true)") > n0:
			break
		await process_frame
	return _count("reload_changed(true)") - n0


func _count(what: String) -> int:
	return events.filter(func(e: Dictionary) -> bool: return e.what == what).size()


func _pose() -> Array:
	return [anim.rig.get_node("Body/Mag").position.y, anim.rig.get_node("Body/Slide").position.x, anim.rig.get_node("Body").rotation]


func _at_rest() -> bool:
	var p := _pose()
	return is_zero_approx(p[0]) and is_zero_approx(p[1]) and is_zero_approx(p[2]) \
			and anim.rig.get_node("Body/Mag").position.x == 0.0 and anim.rig.get_node("Body/Slide").position.y == 0.0


# --- scenarios ----------------------------------------------------------------

func _scenario_reload_runs_to_end() -> void:
	print("\n-- reload runs to its end --")
	await _fresh_game()
	check(anim.rig_state == &"HOLD" and anim.rig_player.current_animation == "" and _at_rest(), "start: HOLD, no clip, RESET pose")
	await _shots(2)
	check(anim.rig_state == &"HOLD" and anim.rig_player.current_animation == "", "firing does not touch the rig (HOLD, no clip)")
	var started := await _reload()
	check(started == 1, "a real R press starts the reload (reload_changed(true) x%d)" % started)
	check(anim.rig_state == &"RELOAD", "RELOAD on reload_changed(true) (%s)" % anim.rig_state)
	check(anim.rig_player.current_animation == "reload" and anim.rig_player.is_playing(),
			"current_animation is 'reload' and playing ('%s')" % anim.rig_player.current_animation)
	# Mid-way the clip moves the rig.
	await frames(30)
	var mid := _pose()
	check(mid[0] > 30.0 and mid[2] < -0.2, "30 frames (0.5 s) in: magazine out (%.1f px) and gun tilted (%.3f rad)" % [mid[0], mid[2]])
	var last_pos := 0.0
	var state_at_false := &""
	for i in 120:
		if anim.rig_player.current_animation == "reload":
			last_pos = anim.rig_player.current_animation_position
		await process_frame
		if _count("reload_changed(false)") > 0:
			state_at_false = anim.rig_state
			break
	check(_count("reload_changed(false)") == 1, "reload_changed(false) arrived")
	check(last_pos >= 1.25 - 2.0 / 60.0, "the clip ran to its end before the state left RELOAD (last position %.4f s of 1.25)" % last_pos)
	check(state_at_false == &"HOLD", "the state returns to HOLD on reload_changed(false) (%s)" % state_at_false)
	check(anim.rig_player.current_animation == "" and not anim.rig_player.is_playing(), "HOLD: clip stopped, current_animation ''")
	check(_at_rest(), "HOLD: rig at the RESET pose %s" % [_pose()])


func _scenario_pause_mid_reload() -> void:
	print("\n-- pause mid-reload --")
	await _fresh_game()
	await _shots(1)
	await _reload()
	await frames(20)
	await _key(KEY_ESCAPE) # pause (hud.gd _unhandled_input -> game.set_paused)
	await frames(2)
	check(paused and game.hud._pause.visible, "Escape pauses the game (tree paused, pause menu shown)")
	var pos0: float = anim.rig_player.current_animation_position
	var pose0 := _pose()
	var left0: float = player._reload_left
	await frames(60)
	var pos1: float = anim.rig_player.current_animation_position
	check(is_equal_approx(pos0, pos1), "paused 60 frames: clip position frozen (%.4f -> %.4f s)" % [pos0, pos1])
	check(_pose() == pose0, "paused: rig pose unchanged %s" % [pose0])
	check(is_equal_approx(left0, player._reload_left), "paused: the game's reload timer frozen too (%.4f s left)" % left0)
	check(anim.rig_state == &"RELOAD" and anim.rig_player.current_animation == "reload", "paused: still RELOAD playing 'reload'")
	await _key(KEY_ESCAPE)
	await frames(3)
	check(not paused, "Escape again unpauses")
	var pos2: float = anim.rig_player.current_animation_position
	check(pos2 > pos1 and pos2 - pos1 < 6.0 / 60.0, "unpaused: the clip continues from where it stopped (%.4f -> %.4f s)" % [pos1, pos2])
	# Clip and game stay together after the pause: both finish.
	for i in 120:
		await process_frame
		if _count("reload_changed(false)") > 0:
			break
	check(anim.rig_state == &"HOLD" and _at_rest(), "after the pause the reload still ends in HOLD at rest")
	var total_clip := pos0 + (1.25 - pos1)
	check(absf(total_clip - 1.25) < 1e-3, "pause added no clip time (%.4f s)" % total_clip)


func _scenario_keycard() -> void:
	print("\n-- keycard pickup --")
	await _fresh_game()
	check(anim.key_state == &"HIDDEN" and not anim.icon.visible and anim.icon_player.current_animation == "", "before the pickup: HIDDEN, icon invisible, no clip")
	var lvl: Node = game.level
	player.global_position = lvl.keycard.global_position * Vector3(1, 0, 1) + Vector3(0, 0, 0.9)
	for i in 30:
		await process_frame
		if game.has_keycard:
			break
	check(game.has_keycard and game.hud._key_label.visible, "the keycard is picked up (HUD keycard element shown)")
	check(anim.key_state == &"SPINNING", "SPINNING on the keycard state going true (%s)" % anim.key_state)
	check(anim.icon.visible and anim.icon_player.current_animation == "spin" and anim.icon_player.is_playing(),
			"icon visible, current_animation 'spin' ('%s')" % anim.icon_player.current_animation)
	var seen := {}
	for i in 90:
		await process_frame
		seen[anim.icon.frame] = true
	var keys := seen.keys()
	keys.sort()
	check(keys == [0, 1, 2, 3, 4, 5, 6, 7], "1.5 s of play shows all 8 cells %s" % [keys])
	check(anim.icon_player.current_animation == "spin" and anim.icon_player.is_playing(), "still spinning after 1.5 s (loops, never ends)")


func _scenario_death_mid_reload() -> void:
	print("\n-- death mid-reload (real zombie contact) --")
	await _fresh_game()
	# Bring hp low with real swipes, so the next one kills.
	await _hits_until(18.0)
	print("  hp after swipes: %.0f" % player.hp)
	var died_in_reload := false
	for attempt in 6:
		if not player.alive:
			break
		if player.mag >= player.MAG_SIZE:
			await _shots(1)
		var s := await _reload()
		if s != 1:
			continue
		var z: Node3D = game.waves.spawn_zombie("shambler", player.global_position + Vector3(0.9, 0, 0))
		for i in 200:
			await process_frame
			if not player.alive or not player.is_reloading():
				break
		if is_instance_valid(z):
			z.free()
		if not player.alive:
			var e: Dictionary = events.filter(func(x: Dictionary) -> bool: return x.what == "died")[0]
			var n_true := _count("reload_changed(true)")
			var n_false := _count("reload_changed(false)")
			died_in_reload = n_true == n_false + 1
			print("  died on attempt %d, reload_changed true x%d false x%d" % [attempt + 1, n_true, n_false])
			if died_in_reload:
				check(e.state == &"DEAD", "on the died signal the rig is DEAD (%s)" % e.state)
				check(e.clip == "" and not e.playing, "on the died signal the clip is stopped (current_animation '%s')" % e.clip)
				check(is_zero_approx(e.pose[0]) and is_zero_approx(e.pose[1]) and is_zero_approx(e.pose[2]), "on the died signal the pose is reset %s (same tick)" % [e.pose])
			break
		await frames(25)
	check(died_in_reload, "the player died mid-reload through real zombie contact")
	if died_in_reload:
		await frames(90)
		check(_count("reload_changed(false)") == _count("reload_changed(true)") - 1, "no reload_changed(false) after death (player.gd _die zeroes _reload_left)")
		check(anim.rig_state == &"DEAD" and anim.rig_player.current_animation == "" and _at_rest(), "90 frames later: still DEAD, no clip, at rest")
		await _key(KEY_R)
		await frames(3)
		check(anim.rig_state == &"DEAD" and anim.rig_player.current_animation == "", "an R press after death changes nothing")


func _hits_until(until: float) -> void:
	var swipes := 0
	while player.hp > until and player.alive and swipes < 12:
		var hp0: float = player.hp
		var z: Node3D = game.waves.spawn_zombie("shambler", player.global_position + Vector3(0.9, 0, 0))
		var f := 0
		while player.hp == hp0 and f < 400:
			await frames(1)
			f += 1
		if is_instance_valid(z):
			z.free()
		swipes += 1
		await frames(20)
