extends SceneTree
## Headless CPU price of the A6 effects (CHANGE-BRIEF.md, "Price predictions
## and budgets"). Written by Claude Code. Run through the wrapper:
##
##   bash scripts/run-test.sh cost_effects.gd 60 300
##
## Per-frame CPU time = wall-clock time between consecutive frames, read by a
## node with the highest process_priority. Under --fixed-fps the headless loop
## is not throttled, so that interval is the whole frame's CPU work.
## (Performance TIME_PROCESS was tried first and dropped: headless it read
## 720 ms with sd 0, i.e. not a per-frame number.)
## Cases: an empty scene (control), the game with both effects off, Effect A
## at its worst (12 bursts alive = 288 particles), Effect B at ratio 1.0.
## The game cases have waves off and no zombies so they differ only by the
## effect. A headless run uses the dummy renderer: no particle process
## shader runs, so a GPU effect's price here is near zero by construction.
## Always exits 0 unless a case fails to run (this measures, it asserts
## only that the control differs from the game).

const WARM := 60
const FRAMES := 600

var _failures := 0


class Clock extends Node:
	var last := 0
	var samples: PackedFloat64Array = []
	var on := false

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_priority = -1000 # first in the frame: measures frame to frame

	func _process(_d: float) -> void:
		var now := Time.get_ticks_usec()
		if on and last > 0:
			samples.append((now - last) / 1000.0)
		last = now


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _stats(a: PackedFloat64Array) -> Array:
	var s := 0.0
	for x in a:
		s += x
	var mean := s / a.size()
	var v := 0.0
	for x in a:
		v += (x - mean) * (x - mean)
	var sorted := Array(a)
	sorted.sort()
	return [mean, sqrt(v / a.size()), sorted[int(a.size() * 0.5)], sorted[int(a.size() * 0.95)]]


func _measure(name: String, setup: Callable, tick := Callable()) -> Array:
	var clock := Clock.new()
	root.add_child(clock)
	var holder: Node = await setup.call()
	await _frames(WARM)
	clock.on = true
	for i in FRAMES:
		if tick.is_valid():
			tick.call(i)
		await process_frame
	clock.on = false
	var st := _stats(clock.samples)
	print("%-38s frame CPU mean %.4f ms  sd %.4f  median %.4f  p95 %.4f  (n=%d)" % [
			name, st[0], st[1], st[2], st[3], clock.samples.size()])
	clock.queue_free()
	if holder:
		holder.queue_free()
	await _frames(5)
	return st


func _empty() -> Node:
	var n := Node3D.new()
	root.add_child(n)
	return n


func _game() -> Node:
	var g: Node = load("res://game3d/game.tscn").instantiate()
	root.add_child(g)
	await _frames(10)
	g.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	return g


var _g: Node


func _run() -> void:
	print("\n== cost_effects (headless, %s) ==" % RenderingServer.get_current_rendering_method())
	print("video adapter: '%s' (headless: the dummy renderer)" % RenderingServer.get_video_adapter_name())
	await _measure("warm-up (discarded)", _empty)
	var empty := await _measure("empty scene (control)", _empty)
	var off := await _measure("game, both effects off", func() -> Node:
		_g = await _game()
		return _g)
	var a := await _measure("Effect A worst: 12 bursts alive", func() -> Node:
		_g = await _game()
		return _g, func(i: int) -> void:
		# Re-fire all 12 every 0.5 s (30 frames): 12 alive, 288 particles.
		if i % 30 == 0:
			for k in 12:
				_g.player.bullet_hit.emit(_g.player.global_position + Vector3(k * 0.3 - 1.8, 0.95, -2), Vector3.BACK)
			if i == 0:
				print("  check: %d bursts alive, %d particles" % [_g.impact_fx.alive_count(), _g.impact_fx.alive_count() * 24]))
	var b := await _measure("Effect B at amount_ratio 1.0", func() -> Node:
		_g = await _game()
		_g.wound_smoke._on_health_changed(10.0, 100.0) # the mapping at hp 10: ratio 1.0
		print("  check: emitting %s, amount_ratio %.2f, amount %d" % [_g.wound_smoke.smoke.emitting, _g.wound_smoke.smoke.amount_ratio, _g.wound_smoke.smoke.amount])
		return _g)
	# The same case again, last: shows how much the order of the cases moves
	# the numbers (a fresh game each time; earlier games are freed).
	var off2 := await _measure("game, both effects off (again, last)", func() -> Node:
		_g = await _game()
		return _g)
	print("")
	print("above the control: game %.4f ms; A worst %.4f ms over game-off; B %.4f ms over game-off" % [off[0] - empty[0], a[0] - off[0], b[0] - off[0]])
	print("order drift: game-off first %.4f ms vs last %.4f ms (difference %.4f ms); A and B against the mean of the two: %.4f / %.4f ms" % [
			off[0], off2[0], off2[0] - off[0], a[0] - (off[0] + off2[0]) / 2.0, b[0] - (off[0] + off2[0]) / 2.0])
	var differs := absf(off[0] - empty[0]) > 3.0 * maxf(empty[1], 0.001)
	print("%s the control and the game differ by more than 3 control sd (the script is not only measuring itself)" % ["PASS" if differs else "FAIL"])
	if not differs:
		_failures += 1
	print("note: GPU effects run their simulation in a particle process shader on the GPU; the dummy renderer runs none, so A and B cost ~nothing here by construction.")
	await _frames(2)
	quit(1 if _failures > 0 else 0)
