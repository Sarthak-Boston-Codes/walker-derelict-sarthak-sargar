extends SceneTree
## State test for Effect B, the wound smoke (CHANGE-BRIEF.md rules B1-B5 and
## the mapping). Written by Claude Code. Headless, through the real game loop:
##
##   bash scripts/run-test.sh test_wound_smoke_state.gd 60
##
## Health changes are real: a zombie's own attack (enemy contact, 18 hp per
## swipe from a shambler) and a real medkit pickup (+40 through pickup.gd's
## overlap check). Pause is the game's own set_paused(). Hidden is the test
## setting `visible = false` on the emitter (nothing in the game hides it).
## A Sampler node with a high process_priority records the emitter every
## frame. A headless run draws nothing: this proves what the driver writes
## and what the node reports, not what is on screen. Exit 1 on any FAIL.

const DRIVER_PATH := "res://game3d/wound_smoke_driver.gd"
## Loaded at run time: a preload here compiles pickup.gd before the Assets
## autoload exists and fails the whole game's scripts.
const PICKUP_PATH := "res://game3d/pickup.gd"

var _failures := 0
var game: Node
var smoke: GPUParticles3D
var sampler: Sampler
var events: Array[Dictionary] = [] # per health_changed: {hp, emitting, ratio, amount}


class Sampler extends Node:
	var smoke: GPUParticles3D
	var amount0 := -1
	var amount_changed := false
	var frames := 0

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_priority = 1000
		amount0 = smoke.amount

	func _process(_delta: float) -> void:
		frames += 1
		if smoke.amount != amount0:
			amount_changed = true


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
	print("\n== test_wound_smoke_state ==")
	_check_driver_source()
	await _fresh_game()
	await _scenario_load()
	await _scenario_damage_and_medkit()
	await _scenario_pause()
	await _scenario_hidden()
	await _scenario_death()
	check(not sampler.amount_changed, "B2 `amount` stayed %d on every one of %d frames" % [sampler.amount0, sampler.frames])
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	game.get_tree().paused = false
	sampler.free()
	game.queue_free()
	await process_frame
	quit(1 if _failures > 0 else 0)


func _check_driver_source() -> void:
	var src := FileAccess.get_file_as_string(DRIVER_PATH)
	var writes := RegEx.create_from_string("smoke\\.(\\w+)\\s*=[^=]").search_all(src)
	var names := {}
	for m in writes:
		names[m.get_string(1)] = true
	check(names.keys().size() > 0 and names.keys().all(func(k: String) -> bool: return k in ["emitting", "amount_ratio", "position"]),
			"B2 driver source assigns only smoke.emitting, smoke.amount_ratio (and its position once) (%s)" % [names.keys()])
	check(not src.contains("smoke.amount ="), "B2 driver source never assigns smoke.amount")
	var state := RegEx.create_from_string("player\\.\\w+\\s*[-+*/]?=[^=]").search(src)
	check(state == null, "driver source assigns no player.* field")


func _fresh_game() -> void:
	game = load("res://game3d/game.tscn").instantiate()
	root.add_child(game)
	smoke = game.wound_smoke.smoke
	sampler = Sampler.new()
	sampler.smoke = smoke
	root.add_child(sampler)
	game.player.health_changed.connect(func(hp: float, _m: float) -> void:
		events.append({"hp": hp, "emitting": smoke.emitting, "ratio": smoke.amount_ratio, "amount": smoke.amount}))
	await frames(2)


func _expected_ratio(hp: float) -> float:
	return clampf((60.0 - hp) / 50.0, 0.2, 1.0)


func _scenario_load() -> void:
	check(smoke.get_parent() == game.player, "the emitter is a child of the player")
	check(is_equal_approx(smoke.position.y, 1.25), "at chest height (y %.2f)" % smoke.position.y)
	var any := false
	for f in 30:
		await frames(1)
		any = any or smoke.emitting
	check(not any and game.player.hp == 100.0, "B5 scene load at full health: emitting false for the first 32 frames (preprocess %.1f)" % smoke.preprocess)
	game.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	await frames(2)


## Real enemy contact until hp <= `until`: a shambler is spawned next to the
## player and its own attack does the damage. Knockback pushes the player out
## of reach after a swipe, so each swipe gets a fresh adjacent zombie (the
## previous one is freed); at most 400 frames are allowed per swipe.
func _take_hits_until(until: float, max_swipes := 12) -> void:
	var p: Node3D = game.player
	var swipes := 0
	while p.hp > until and p.alive and swipes < max_swipes:
		var hp0: float = p.hp
		var z: Node3D = game.waves.spawn_zombie("shambler", p.global_position + Vector3(0.9, 0, 0))
		var f := 0
		while p.hp == hp0 and f < 400:
			await frames(1)
			f += 1
		if is_instance_valid(z):
			z.free()
		swipes += 1
		await frames(20) # past HURT_GRACE
	await frames(2)


func _medkit() -> void:
	var m: Area3D = (load(PICKUP_PATH) as GDScript).new()
	m.kind = "medkit"
	game.level.add_child(m)
	m.global_position = game.player.global_position
	var hp0: float = game.player.hp
	var f := 0
	while game.player.hp == hp0 and f < 60:
		await frames(1)
		f += 1
	await frames(2)


func _scenario_damage_and_medkit() -> void:
	events.clear()
	await _take_hits_until(30.0)
	print("  health_changed seen (hp: emitting, ratio): %s" % [events.map(func(e: Dictionary) -> String: return "%.0f: %s, %.2f" % [e.hp, e.emitting, e.ratio])])
	var ok_off := true
	var ok_on := true
	var ratios := {}
	for e in events:
		if e.hp > 60.0:
			ok_off = ok_off and not e.emitting
		else:
			ok_on = ok_on and e.emitting and is_equal_approx(e.ratio, _expected_ratio(e.hp))
			ratios[snappedf(e.ratio, 0.001)] = e.hp
	check(events.size() >= 4, "real enemy contact changed hp at least 4 times (%d)" % events.size())
	check(ok_off, "B1 above 60 hp: not emitting")
	check(ok_on, "B1/mapping at or below 60 hp: emitting, amount_ratio = clamp((60 - hp) / 50, 0.2, 1.0)")
	check(ratios.size() >= 2, "B2 at least two hp values gave two different ratios (%s)" % [ratios])
	var hp_before: float = game.player.hp
	events.clear()
	await _medkit()
	print("  medkit: hp %.0f -> %.0f, emitting %s" % [hp_before, game.player.hp, smoke.emitting])
	check(game.player.hp > 60.0 and not smoke.emitting, "B1 a real medkit lifting hp above 60 (%.0f -> %.0f) stops the emitter" % [hp_before, game.player.hp])
	events.clear()
	await _take_hits_until(60.0)
	var last: Dictionary = events[-1] if events.size() > 0 else {}
	check(last.size() > 0 and last.hp <= 60.0 and smoke.emitting and is_equal_approx(smoke.amount_ratio, _expected_ratio(last.hp)),
			"B1 hp falling to 60 or below again restarts it (hp %.0f, ratio %.2f)" % [game.player.hp, smoke.amount_ratio])


func _scenario_pause() -> void:
	check(smoke.emitting, "(pause) the smoke is on before pausing")
	var ratio0 := smoke.amount_ratio
	var proc0 := smoke.can_process()
	game.set_paused(true)
	await frames(30)
	print("  paused: tree.paused %s, smoke.can_process() %s -> %s, emitting %s, amount_ratio %.2f, speed_scale %.2f" % [
			game.get_tree().paused, proc0, smoke.can_process(), smoke.emitting, smoke.amount_ratio, smoke.speed_scale])
	check(game.get_tree().paused and not smoke.can_process(), "B3 the game's own pause stops the emitter's processing (can_process false: the node is pausable)")
	check(smoke.emitting and smoke.amount_ratio == ratio0, "B3 paused: emitting and amount_ratio unchanged (the driver does not touch them)")
	game.set_paused(false)
	await frames(3)
	check(not game.get_tree().paused and smoke.can_process() and smoke.emitting and smoke.amount_ratio == ratio0,
			"B3 unpaused: processing resumes with the same emitting / ratio")


func _scenario_hidden() -> void:
	smoke.visible = false
	await frames(5)
	check(not smoke.is_visible_in_tree() and smoke.emitting, "B4 hidden: is_visible_in_tree false, emitting unchanged (true)")
	var hp0: float = game.player.hp
	await _take_hits_until(hp0 - 1.0)
	check(not smoke.visible and smoke.emitting and is_equal_approx(smoke.amount_ratio, _expected_ratio(game.player.hp)),
			"B4 hidden: the mapping still follows hp (hp %.0f -> ratio %.2f)" % [game.player.hp, smoke.amount_ratio])
	smoke.visible = true
	await frames(2)


func _scenario_death() -> void:
	events.clear()
	var died := [false]
	game.player.died.connect(func() -> void: died[0] = true)
	await _take_hits_until(0.0)
	await frames(5)
	check(died[0] and not game.player.alive, "the player died from real enemy contact")
	check(not smoke.emitting, "B1 on death the emitter stops (emitting false)")
