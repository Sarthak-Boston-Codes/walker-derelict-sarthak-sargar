extends SceneTree
## State test for Effect A, the impact burst (CHANGE-BRIEF.md rules A1-A4).
## Written by Claude Code. Headless, through the real game loop:
##
##   bash scripts/run-test.sh test_impact_burst_state.gd 60
##
## Aim is real input: an InputEventMouseMotion at the target's screen
## position goes through Input.parse_input_event, and the player's own
## _update_aim reads it. Fire is real input: Input.action_press("fire").
## Only the pool-exhausted case emits player.bullet_hit directly (continuous
## fire cannot fill the pool; see CHANGE-BRIEF revision 2026-11-08).
## A headless run draws nothing: this test proves when, where and how many
## bursts are started and that their nodes outlive the victim; it cannot
## prove what they look like. Exit 1 on any FAIL.

var _failures := 0
var game: Node
var fx: Node
var hits: Array[Dictionary] = [] # every bullet_hit seen: {point, normal, frame, emitting}
var finished: Array[Dictionary] = [] # every emitter `finished` signal: {burst, emitter, frame}
var _frame := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func frames(n: int) -> void:
	for i in n:
		await process_frame
		_frame += 1


func _run() -> void:
	print("\n== test_impact_burst_state ==")
	await _scenario_load()
	await _scenario_miss()
	await _scenario_one_hit()
	await _scenario_two_hits_overlap()
	await _scenario_killing_hit()
	await _scenario_held_fire()
	await _scenario_pool_exhausted()
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	Input.action_release("fire")
	if game:
		game.queue_free()
	await process_frame
	quit(1 if _failures > 0 else 0)


# --- helpers ------------------------------------------------------------------

func _fresh_game() -> void:
	Input.action_release("fire")
	if game:
		game.queue_free()
		await frames(2)
	hits.clear()
	game = load("res://game3d/game.tscn").instantiate()
	root.add_child(game)
	await frames(10)
	game.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	fx = game.impact_fx
	finished.clear()
	# Connected after ImpactFx, so this runs after the burst was restarted:
	# it records what the three emitters of the newest burst report then.
	game.player.bullet_hit.connect(func(point: Vector3, normal: Vector3) -> void:
		var b: Node3D = fx.pool[fx.order[-1]]
		var on := []
		for e in b.get_children():
			on.append((e as GPUParticles3D).emitting)
		hits.append({"point": point, "normal": normal, "frame": _frame, "burst": fx.order[-1], "emitting": on}))
	for i in fx.pool.size():
		for e in fx.pool[i].get_children():
			e.finished.connect(func() -> void:
				finished.append({"burst": i, "emitter": String(e.name), "frame": _frame}))
	await frames(2)


## Frame on which burst `i`'s emitter `name` last reported `finished`, or -1.
func _finished_frame(i: int, name: String) -> int:
	for k in range(finished.size() - 1, -1, -1):
		if finished[k].burst == i and finished[k].emitter == name:
			return finished[k].frame
	return -1


## Real mouse input: move the cursor to where `world` is on screen. Mouse
## events are in window pixels; headless, the window is 64 x 64 and the
## 1280-wide canvas is stretched onto it, so the viewport position is mapped
## through the root's final transform.
func _aim_at(world: Vector3) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = root.get_final_transform() * game.camera.unproject_position(world)
	ev.global_position = ev.position
	Input.parse_input_event(ev)
	await frames(3)


## Real fire input for `n` frames (the player fires every FIRE_INTERVAL).
func _hold_fire(n: int) -> void:
	Input.action_press("fire")
	await frames(n)
	Input.action_release("fire")


## A zombie that stands still at `pos` (test fixture: its own processing
## callbacks are off so it neither walks nor attacks; it still takes hits).
func _zombie(pos: Vector3, hp := 1000.0) -> Node3D:
	var z: Node3D = game.waves.spawn_zombie("shambler", pos)
	await frames(2)
	z.global_position = pos
	z.hp = hp
	# Not PROCESS_MODE_DISABLED: that removes a CollisionObject3D from the
	# physics space (disable_mode REMOVE), so bullets would pass through.
	z.set_physics_process(false)
	z.set_process(false)
	await frames(2)
	return z


func _live_bursts() -> Array[int]:
	var out: Array[int] = []
	for i in fx.POOL_SIZE:
		if fx.is_alive(i):
			out.append(i)
	return out


func _player_xz(x: float, z: float) -> void:
	game.player.global_position = Vector3(x, 0, z)
	game.camera.snap()
	await frames(3)


# --- scenarios ----------------------------------------------------------------

func _scenario_load() -> void:
	await _fresh_game()
	check(fx != null and fx.get_parent() == game.level, "ImpactFx exists under the level root")
	var under_level := 0
	for b in fx.pool:
		if b.get_parent() == game.level:
			under_level += 1
	check(fx.pool.size() == 12 and under_level == 12, "pool of 12 bursts, all children of the level root (A2, A3) (%d/%d)" % [under_level, fx.pool.size()])
	var any := false
	for f in 30:
		await frames(1)
		any = any or _live_bursts().size() > 0
	check(not any and fx.fired == 0 and hits.is_empty(), "A1 scene load: no burst emitting in the first 42 frames, 0 fired, 0 bullet_hit")


func _scenario_miss() -> void:
	await _fresh_game()
	# Loading Bay start, aiming north at the wall: a shot that hits no victim.
	await _player_xz(-5, 9.5)
	await _aim_at(Vector3(-5, 0.95, 4))
	var mag0: int = game.player.mag
	await _hold_fire(2)
	await frames(3)
	check(game.player.mag == mag0 - 1, "one real shot fired at the wall (mag %d -> %d)" % [mag0, game.player.mag])
	check(hits.is_empty() and fx.fired == 0 and _live_bursts().is_empty(), "A1 a shot that hits no victim (a wall) fires no burst (fired %d)" % fx.fired)
	print("  note: a ray that hits nothing at all cannot be produced in the closed level; that path has no emit (player.gd fire(): the emit is inside `if hit:`)")


func _scenario_one_hit() -> void:
	await _fresh_game()
	await _player_xz(-5, 9.5)
	var z := await _zombie(Vector3(-5, 0, 5.5))
	await _aim_at(z.global_position + Vector3.UP * 0.95)
	print("  aim_point after mouse input: %s (zombie at %s)" % [game.player.aim_point, z.global_position])
	var hp0: float = z.hp
	await _hold_fire(2)
	await frames(2)
	check(game.player.shots_fired == 1, "exactly one real shot fired (%d)" % game.player.shots_fired)
	check(hits.size() == 1 and z.hp == hp0 - 1.0, "the shot hit the zombie: 1 bullet_hit, zombie hp %.0f -> %.0f" % [hp0, z.hp])
	check(fx.fired == 1, "A1 exactly one burst started for one hit (fired %d)" % fx.fired)
	var live := _live_bursts()
	check(live.size() == 1, "A1 one burst emitting (%s)" % [live])
	if hits.size() == 1 and live.size() == 1:
		var b: Node3D = fx.pool[live[0]]
		var p: Vector3 = hits[0].point
		var n: Vector3 = hits[0].normal
		check(b.global_position.is_equal_approx(p), "A1 burst at the hit point %s (got %s)" % [p, b.global_position])
		var flat := Vector2(p.x - z.global_position.x, p.z - z.global_position.z).length()
		check(flat <= 0.36 and p.y >= 0.0 and p.y <= 1.71, "the hit point is on the zombie's capsule (r 0.35, h 1.7): %.2f m from its axis, height %.2f" % [flat, p.y])
		check(b.global_basis.y.normalized().is_equal_approx(n.normalized()), "A4 burst +Y = hit normal %s (got %s)" % [n, b.global_basis.y])
		check(hits[0].emitting == [true, true, true], "A1 Flash, Sparks, Puff all restarted (emitting) on the hit frame (%s)" % [hits[0].emitting])
		# Node truth for the lifetime: each one-shot emitter's own `finished`.
		var i: int = live[0]
		var h: int = hits[0].frame
		await frames(50)
		var ff := _finished_frame(i, "Flash") - h
		var fs := _finished_frame(i, "Sparks") - h
		var fp := _finished_frame(i, "Puff") - h
		print("  finished signals, frames after the hit: Flash %d, Sparks %d, Puff %d (lifetimes 0.08 / 0.45 / 0.6 s = 4.8 / 27 / 36 frames)" % [ff, fs, fp])
		check(ff > 0 and fs > ff and fp >= fs, "emitters finish in lifetime order Flash < Sparks <= Puff")
		check(fp >= 36 and fp <= 40, "the Puff, the longest, finishes 36..40 frames after the hit (%d)" % fp)
		check(not fx.is_alive(i), "ImpactFx counts the burst free once its lifetime (%.2f s) has passed" % fx.burst_life)


func _scenario_two_hits_overlap() -> void:
	await _fresh_game()
	await _player_xz(-5, 9.5)
	var z := await _zombie(Vector3(-5, 0, 5.5))
	await _aim_at(z.global_position + Vector3.UP * 0.95)
	# Hold fire just long enough for two shots (FIRE_INTERVAL 0.14 s).
	Input.action_press("fire")
	var guard := 0
	while game.player.shots_fired < 2 and guard < 60:
		await frames(1)
		guard += 1
	Input.action_release("fire")
	var dt_frames: int = hits[1].frame - hits[0].frame if hits.size() >= 2 else -1
	check(hits.size() == 2, "two hits from two real shots (%d)" % hits.size())
	check(dt_frames > 0 and dt_frames <= 10, "the second hit came %d frames (%.3f s) after the first, inside one burst lifetime (0.6 s)" % [dt_frames, dt_frames / 60.0])
	var live := _live_bursts()
	check(live.size() == 2, "A2 two live bursts after two hits inside one lifetime (%d: %s)" % [live.size(), live])
	if hits.size() >= 2:
		check(hits[0].burst != hits[1].burst, "A2 the second hit used a different burst (%d, %d)" % [hits[0].burst, hits[1].burst])
		check(_finished_frame(hits[0].burst, "Puff") < 0 and hits[1].emitting == [true, true, true],
				"A2 node truth: the first burst's Puff has not finished when the second burst starts")
	check(fx.fired == 2 and fx.recycled == 0, "A2 two bursts started from the pool, none recycled (fired %d, recycled %d)" % [fx.fired, fx.recycled])


func _scenario_killing_hit() -> void:
	await _fresh_game()
	await _player_xz(-5, 9.5)
	var z := await _zombie(Vector3(-5, 0, 5.5), 1.0)
	await _aim_at(z.global_position + Vector3.UP * 0.95)
	Input.action_press("fire")
	var guard := 0
	while hits.is_empty() and guard < 30:
		await frames(1)
		guard += 1
	Input.action_release("fire")
	check(z.hp <= 0.0, "the hit killed the zombie (hp %.1f)" % z.hp)
	# Free the victim now (fixture: the game would free it later, after its sink).
	z.free()
	check(not is_instance_valid(z), "the victim is freed on the killing-hit frame")
	var live := _live_bursts()
	check(live.size() == 1, "A3 its burst is still alive after the victim is freed (%d live)" % live.size())
	var b_i: int = hits[0].burst if hits.size() > 0 else 0
	await frames(10)
	check(fx.pool[b_i].is_inside_tree() and fx.pool[b_i].get_parent() == game.level and _finished_frame(b_i, "Puff") < 0,
			"A3 10 frames later the burst is still in the tree under the level and its Puff has not finished")
	await frames(40)
	check(_finished_frame(b_i, "Puff") > 0, "A3 ... and it runs to its own end (Puff finished %d frames after the hit)" % (_finished_frame(b_i, "Puff") - hits[0].frame))


func _scenario_held_fire() -> void:
	await _fresh_game()
	await _player_xz(-5, 9.5)
	var z := await _zombie(Vector3(-5, 0, 5.5))
	await _aim_at(z.global_position + Vector3.UP * 0.95)
	var peak := 0
	Input.action_press("fire")
	for f in 120: # 2 s of held fire, a full magazine at 0.14 s per shot
		await frames(1)
		peak = maxi(peak, _live_bursts().size())
	Input.action_release("fire")
	print("  held fire 2 s: %d shots, %d hits, %d bursts fired, peak %d alive (ImpactFx clock)" % [game.player.shots_fired, hits.size(), fx.fired, peak])
	check(fx.fired == hits.size() and hits.size() >= 5, "A1 one burst per hit under held fire, none for the misses (%d bursts, %d hits, %d shots)" % [fx.fired, hits.size(), game.player.shots_fired])
	check(peak >= 2 and peak <= 5, "A2 continuous fire keeps 2..5 bursts alive at once (peak %d; brief: at most 5)" % peak)
	check(fx.recycled == 0, "A2 continuous fire never exhausts the pool (recycled %d)" % fx.recycled)


func _scenario_pool_exhausted() -> void:
	await _fresh_game()
	# Synthetic: 13 bullet_hit emits in one frame (more than fire allows).
	var base := Vector3(0, 0.95, 8)
	for i in 12:
		game.player.bullet_hit.emit(base + Vector3(i * 0.5, 0, 0), Vector3.BACK)
	var oldest: int = fx.order[0]
	check(_live_bursts().size() == 12 and fx.recycled == 0, "12 hits in one frame use all 12 bursts (%d live)" % _live_bursts().size())
	var p13 := Vector3(-3, 0.95, 6)
	game.player.bullet_hit.emit(p13, Vector3.UP)
	check(fx.recycled == 1, "the 13th hit finds the pool exhausted (recycled %d)" % fx.recycled)
	check(fx.order[-1] == oldest and fx.pool[oldest].global_position.is_equal_approx(p13),
			"A2 the oldest burst (index %d) is restarted at the 13th hit's point" % oldest)
	check(_live_bursts().size() == 12 and fx.fired == 13, "still 12 live, 13 started (fired %d)" % fx.fired)
