extends SceneTree
## GPU price of the A6 effects (CHANGE-BRIEF.md, "Price predictions and
## budgets"). Written by Claude Code. Needs a window and the real GPU:
##
##   godot --path godot --resolution 1280x720 --script res://tools/gpu_price.gd
##
## Reads the RenderingServer GPU counter for the main viewport
## (viewport_set_measure_render_time, viewport_get_measured_render_time_gpu)
## every frame and averages it over FRAMES frames per case, with vsync turned
## off by this script so FPS can rise above the display's refresh rate.
## Cases, each a fresh game with waves off and no zombies, the player parked
## in the Loading Bay with the effects in view: both effects off; Effect A at
## its worst (12 bursts alive = 288 particles, re-fired every 0.5 s); Effect
## B at amount_ratio 1.0 (40 particles). "Off" runs first and last, so the
## drift between two identical cases is visible.

const WARM := 120
const FRAMES := 600

var _vp: RID
var _g: Node


func _initialize() -> void:
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _game() -> Node:
	var g: Node = load("res://game3d/game.tscn").instantiate()
	root.add_child(g)
	await _frames(10)
	g.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	g.player.controls_enabled = false
	g.player.global_position = Vector3(-5, 0, 9.5)
	g.player.aim_point = Vector3(-5, 0.95, 5.5)
	g.camera.snap()
	g.hud.visible = false
	return g


func _case(name: String, effect: String) -> Dictionary:
	_g = await _game()
	if effect == "B":
		_g.wound_smoke._on_health_changed(10.0, 100.0) # the mapping at hp 10: ratio 1.0
	await _frames(WARM)
	var gpu := PackedFloat64Array()
	var cpu := PackedFloat64Array()
	var t0 := Time.get_ticks_usec()
	for i in FRAMES:
		if effect == "A" and i % 30 == 0:
			for k in 12:
				_g.player.bullet_hit.emit(Vector3(-6.65 + k * 0.3, 0.95, 7.5), Vector3.BACK)
		await process_frame
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(_vp))
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(_vp))
	var secs := (Time.get_ticks_usec() - t0) / 1e6
	var r := {"name": name, "gpu": _mean_sd(gpu), "cpu": _mean_sd(cpu), "fps": FRAMES / secs}
	var extra := ""
	if effect == "A":
		extra = "  (%d bursts alive at the end, %d particles)" % [_g.impact_fx.alive_count(), _g.impact_fx.alive_count() * 24]
	elif effect == "B":
		extra = "  (emitting %s, amount_ratio %.2f, amount %d)" % [_g.wound_smoke.smoke.emitting, _g.wound_smoke.smoke.amount_ratio, _g.wound_smoke.smoke.amount]
	print("%-30s GPU %.4f ms (sd %.4f)   render CPU %.4f ms (sd %.4f)   %.0f FPS over %d frames%s" % [
			name, r.gpu[0], r.gpu[1], r.cpu[0], r.cpu[1], r.fps, FRAMES, extra])
	_g.queue_free()
	await _frames(10)
	return r


func _mean_sd(a: PackedFloat64Array) -> Array:
	var s := 0.0
	for x in a:
		s += x
	var m := s / a.size()
	var v := 0.0
	for x in a:
		v += (x - m) * (x - m)
	return [m, sqrt(v / a.size())]


func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	_vp = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(_vp, true)
	var refresh := DisplayServer.screen_get_refresh_rate()
	print("GPU: %s | %s %s | window %s | vsync mode %d (0 = disabled) | screen refresh %.1f Hz" % [
			RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_method(),
			RenderingServer.get_current_rendering_driver_name(), root.size, DisplayServer.window_get_vsync_mode(), refresh])
	var off1 := await _case("both effects off (first)", "")
	var a := await _case("Effect A worst (12 bursts)", "A")
	var b := await _case("Effect B ratio 1.0", "B")
	var off2 := await _case("both effects off (last)", "")
	var base: float = (off1.gpu[0] + off2.gpu[0]) / 2.0
	print("")
	print("off drift (last - first): %.4f ms GPU" % (off2.gpu[0] - off1.gpu[0]))
	print("Effect A worst over the mean of the two off runs: %.4f ms GPU (budget 0.30 ms)" % (a.gpu[0] - base))
	print("Effect B ratio 1.0 over the mean of the two off runs: %.4f ms GPU (budget 0.20 ms)" % (b.gpu[0] - base))
	var capped: bool = refresh > 0 and off1.fps <= refresh * 1.05
	print("FPS %s the refresh rate (%.0f FPS vs %.1f Hz)%s" % ["does not rise above" if capped else "rises above",
			off1.fps, refresh, ": the measurement may be capped" if capped else ": not vsync-capped"])
	quit()
