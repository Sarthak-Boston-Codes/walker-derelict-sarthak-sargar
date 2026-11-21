extends SceneTree
## The two clocks (CHANGE-BRIEF.md "The two clocks"). Written by Claude
## Code. Headless, real game loop, real R key events:
##
##   bash scripts/run-test.sh test_two_clocks.gd 60
##   bash scripts/run-test.sh test_two_clocks.gd 30
##
## Clock 1, the game: _reload_left counts down in player._process; the
## reload ends on the tick reload_changed(false) fires.
## Clock 2, the clip: the reload AnimationPlayer (PROCESS_IDLE). HudAnim
## stops the HUD's clip on reload_changed(false), so to see when the clip
## itself would finish, a shadow copy of pistol_rig.tscn (a test fixture,
## the sibling of the HUD rig under the same parent, so it is processed in
## the same place) is started from the same signal and never stopped; its
## animation_finished tick is the clip's end. The HUD clip's position on
## the reload_changed(false) tick is recorded too.
## Reports, over several reloads, the largest disagreement between the two
## ends in seconds. Pass condition: at most one frame period (the brief
## predicted "under one frame"; the result says which).
## Exit 1 on any FAIL.

const RELOADS := 5

var _failures := 0
var game: Node
var anim: Node
var player: Node
var shadow: Node2D
var shadow_ap: AnimationPlayer
var f0 := -1
var t_false := -1
var t_finish := -1
## The HUD clip's position at the end of the last tick before the reload
## ended (HudAnim stops it on reload_changed(false)).
var hud_pos_at_false := -1.0
var first_advance := -1


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
	print("\n== test_two_clocks ==")
	game = load("res://game3d/game.tscn").instantiate()
	root.add_child(game)
	await frames(10)
	game.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	anim = game.hud_anim
	player = game.player
	shadow = (load("res://game3d/pistol_rig.tscn") as PackedScene).instantiate()
	shadow.name = "ShadowRig"
	shadow.visible = false
	anim.rig.get_parent().add_child(shadow)
	shadow_ap = shadow.get_node("AnimationPlayer")
	shadow_ap.animation_finished.connect(func(_n: StringName) -> void: t_finish = tick())
	# Connected after HudAnim (game.gd attached it in _ready), so on both
	# signals HudAnim has already acted when these run.
	player.reload_changed.connect(func(a: bool) -> void:
		if a:
			f0 = Engine.get_process_frames()
			shadow_ap.stop()
			shadow_ap.play(&"reload")
		else:
			t_false = tick())
	await frames(2)
	var dt: float = player.get_process_delta_time()
	var fps := roundi(1.0 / dt)
	print("  process delta %.6f s (%d fps), RELOAD_TIME %.2f s = %.2f frames, clip length %.2f s" % [dt, fps, player.RELOAD_TIME, player.RELOAD_TIME / dt, shadow_ap.get_animation(&"reload").length])
	print("  reload  t(false) tick  clip-finish tick  HUD clip pos, last tick before false first tick the clip advances  disagreement")
	var worst := 0.0
	var all_measured := true
	for r in RELOADS:
		await _one_shot()
		t_false = -1
		t_finish = -1
		first_advance = -1
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_R
		ev.pressed = true
		Input.parse_input_event(ev)
		for i in 5:
			await process_frame
			if f0 >= 0 and tick() >= 0 and player.is_reloading():
				break
		var up := InputEventKey.new()
		up.physical_keycode = KEY_R
		up.pressed = false
		Input.parse_input_event(up)
		for i in 200:
			if anim.rig_player.current_animation == "reload":
				hud_pos_at_false = anim.rig_player.current_animation_position
			if first_advance < 0 and shadow_ap.current_animation == "reload" and shadow_ap.current_animation_position > 0.0:
				first_advance = tick() - 1 # sampled at the start of the next tick
			await process_frame
			if t_false >= 0 and t_finish >= 0:
				break
		all_measured = all_measured and t_false >= 0 and t_finish >= 0
		var d := (t_finish - t_false) * dt
		worst = maxf(worst, absf(d))
		print("  %d       %4d          %4d              %.4f s               %4d                       %+d ticks = %+.4f s" % [r + 1, t_false, t_finish, hud_pos_at_false, first_advance, t_finish - t_false, d])
		await frames(3)
	check(all_measured, "both ends measured on all %d reloads" % RELOADS)
	print("  largest disagreement at %d fps: %.4f s (%.2f frames)" % [fps, worst, worst / dt])
	check(worst <= dt + 1e-6, "largest disagreement %.4f s is at most one frame period (%.4f s)" % [worst, dt])
	print("  brief's prediction (under one frame): %s" % ("met" if worst < dt - 1e-6 else "NOT met: the disagreement is exactly one frame"))
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	game.queue_free()
	await process_frame
	quit(1 if _failures > 0 else 0)


func _one_shot() -> void:
	if player.mag < player.MAG_SIZE:
		return
	var s0: int = player.shots_fired
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = root.get_final_transform() * game.camera.unproject_position(player.aim_point)
	ev.global_position = ev.position
	Input.parse_input_event(ev)
	for i in 30:
		await process_frame
		if player.shots_fired > s0:
			break
	var up := ev.duplicate() as InputEventMouseButton
	up.pressed = false
	Input.parse_input_event(up)
	await frames(12)
