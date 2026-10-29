extends SceneTree
## Headless test for the low-ammo tint (CHANGE-BRIEF.md section 2, R1-R9).
## Written by Claude Code. Run through the wrapper at a pinned frame rate:
##
##   bash scripts/run-test.sh low_ammo_test.gd 30    (also 60 and 144)
##
## Low ammo is reached with real fire input (Input.action_press("fire"))
## through the game loop; the driver's _process is never called by hand.
## A Sampler node with a higher process_priority than the driver records
## `low_ammo` once per frame. Exit code 1 on any FAIL.

const SHADER_PATH := "res://shaders/low_ammo.gdshader"
const DRIVER_PATH := "res://game3d/low_ammo_driver.gd"
const EPS := 1e-4

var _failures := 0
var game: Node
var sampler: Sampler
var dt := 0.0 # one frame of game time at time_scale 1


class Sampler extends Node:
	var material: ShaderMaterial
	var records: Array[Dictionary] = []
	var game_time := 0.0
	var real_frames := 0
	var color0: Variant
	var color_changed := false

	func _ready() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS
		process_priority = 1000
		color0 = material.get_shader_parameter("warning_color")

	func _process(delta: float) -> void:
		var paused := get_tree().paused
		if not paused:
			game_time += delta
		real_frames += 1
		if material.get_shader_parameter("warning_color") != color0:
			color_changed = true
		records.append({"v": float(material.get_shader_parameter("low_ammo")),
				"t": game_time, "f": real_frames, "paused": paused, "d": delta})

	func last() -> float:
		return records[-1].v if records.size() > 0 else 0.0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func frame() -> void:
	await process_frame


func frames(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	print("\n== low_ammo_test ==")
	_check_shader_interface()
	await _scenario_fade_in_out()
	await _scenario_retrigger()
	await _scenario_time_scale()
	await _scenario_pause()
	await _scenario_end_mid_fade_in()
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	if game:
		game.queue_free()
	await process_frame
	quit(1 if _failures > 0 else 0)


# --- shader interface ---------------------------------------------------------

func _check_shader_interface() -> void:
	var shader: Shader = load(SHADER_PATH)
	var by_name := {}
	for u in shader.get_shader_uniform_list():
		by_name[u.name] = u
	check(by_name.has("low_ammo"), "uniform low_ammo is declared (get_shader_uniform_list)")
	if by_name.has("low_ammo"):
		check(by_name.low_ammo.type == TYPE_FLOAT, "low_ammo is a float")
		check(by_name.low_ammo.hint == PROPERTY_HINT_RANGE and str(by_name.low_ammo.hint_string).begins_with("0.0,1.0"),
				"low_ammo has hint_range(0.0, 1.0) (hint_string '%s')" % by_name.low_ammo.hint_string)
	check(by_name.has("warning_color"), "uniform warning_color is declared")
	if by_name.has("warning_color"):
		check(by_name.warning_color.type == TYPE_COLOR, "warning_color is a vec4 with source_color (reported as Color)")
	# Defaults from the source text (the dummy renderer returns none).
	var src := FileAccess.get_file_as_string(SHADER_PATH)
	var d := _uniform_defaults(src)
	check(d.get("low_ammo", "") == "0.0", "low_ammo default in source is 0.0 (got '%s')" % d.get("low_ammo", ""))
	check(d.get("warning_color", "") == "vec4(1.0, 0.188, 0.188, 1.0)",
			"warning_color default in source is #FF3030 = vec4(1.0, 0.188, 0.188, 1.0) (got '%s')" % d.get("warning_color", ""))
	# Colour line as revised in CHANGE-BRIEF.md (2026-10-29, failure case 5).
	check(src.contains("COLOR.rgb = mix(COLOR.rgb, warning_color.rgb, low_ammo * glyph);")
			and src.contains("float glyph = step(0.004, max(COLOR.r, max(COLOR.g, COLOR.b)));"), "fragment() holds the spec's revised colour line")
	# The driver writes the uniform the shader declares, and nothing else.
	var drv := FileAccess.get_file_as_string(DRIVER_PATH)
	var re := RegEx.create_from_string("set_shader_parameter\\(([^,]+),")
	var names := []
	for m in re.search_all(drv):
		names.append(m.get_string(1).strip_edges())
	var writes_only_param := names.size() > 0
	for n in names:
		writes_only_param = writes_only_param and n == "PARAM"
	check(writes_only_param and drv.contains('const PARAM := &"low_ammo"'),
			"driver's only set_shader_parameter target is PARAM = \"low_ammo\" (%s)" % [names])
	check(by_name.has(_driver_param(drv)), "the name the driver writes is a uniform the shader declares")
	var writes_state := RegEx.create_from_string("player\\.\\w+\\s*[-+*/]?=[^=]").search(drv)
	check(writes_state == null, "driver source assigns no player.* field")


func _uniform_defaults(src: String) -> Dictionary:
	var out := {}
	var re := RegEx.create_from_string("uniform\\s+\\w+\\s+(\\w+)\\s*(?::[^=;]*)?(?:=\\s*([^;]+))?;")
	for m in re.search_all(src):
		out[m.get_string(1)] = m.get_string(2).strip_edges()
	return out


func _driver_param(drv: String) -> String:
	var m := RegEx.create_from_string('const PARAM := &"(\\w+)"').search(drv)
	return m.get_string(1) if m else ""


# --- helpers ------------------------------------------------------------------

func _fresh_game() -> void:
	if game:
		game.queue_free()
		await frames(2)
	Input.action_release("fire")
	Input.action_release("reload")
	game = load("res://game3d/game.tscn").instantiate()
	root.add_child(game)
	await frames(10)
	game.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	var label: Label = game.hud._ammo_label
	sampler = Sampler.new()
	sampler.material = label.material
	root.add_child(sampler)
	await frames(2)
	if dt == 0.0:
		# --fixed-fps pins delta; take the frame period from the loop itself.
		dt = sampler.records[-1].d
		print("frame period %.6f s (%.1f fps)" % [dt, 1.0 / dt])


func _drop_sampler() -> void:
	check(not sampler.color_changed, "R9 warning_color kept its material value every frame")
	sampler.queue_free()


## Holds the real fire action until the magazine reaches `mag`. Returns the
## sampler record index of the frame the shot that reached it was fired.
func _fire_down_to(mag: int) -> int:
	var p: Node = game.player
	var guard := 0
	while p.mag > mag and guard < 2000:
		Input.action_press("fire")
		await frame()
		guard += 1
	Input.action_release("fire")
	return sampler.records.size() - 1


## Presses the real reload action and waits for the refill. Returns the
## record index of the frame the magazine was refilled.
func _reload() -> int:
	var p: Node = game.player
	var before: int = p.mag
	Input.action_press("reload")
	await frame()
	Input.action_release("reload")
	var guard := 0
	while p.mag == before and guard < 2000:
		await frame()
		guard += 1
	return sampler.records.size() - 1


## Waits until low_ammo reaches `goal`; returns that record's index.
func _until(goal: float, max_frames := 2000) -> int:
	for i in max_frames:
		if absf(sampler.last() - goal) < EPS:
			return sampler.records.size() - 1
		await frame()
	return -1


func _span(from_i: int, to_i: int) -> float:
	# Game time from the start of frame from_i to the end of frame to_i.
	var r: Array[Dictionary] = sampler.records
	var start: float = r[from_i - 1].t if from_i > 0 else 0.0
	return r[to_i].t - start


func _max_step(from_i: int, to_i: int) -> float:
	var r: Array[Dictionary] = sampler.records
	var m := 0.0
	for i in range(maxi(from_i, 1), to_i + 1):
		m = maxf(m, absf(r[i].v - r[i - 1].v))
	return m


func _min_value(from_i: int, to_i: int) -> float:
	var m := INF
	for i in range(from_i, to_i + 1):
		m = minf(m, sampler.records[i].v)
	return m


func _near(got: float, want: float, tol: float) -> bool:
	return absf(got - want) <= tol + EPS


# --- scenarios ----------------------------------------------------------------

func _scenario_fade_in_out() -> void:
	await _fresh_game()
	var label: Label = game.hud._ammo_label
	var mat := label.material as ShaderMaterial
	check(mat != null and mat.shader == load(SHADER_PATH), "R8 the ammo label has a ShaderMaterial on low_ammo.gdshader")
	var sharers := 0
	for n in _all_nodes(root):
		if n == label:
			continue
		if n is CanvasItem and (n as CanvasItem).material == mat:
			sharers += 1
		if n is GeometryInstance3D and (n as GeometryInstance3D).material_override == mat:
			sharers += 1
	check(sharers == 0, "R8 no other node uses the label's material (%d sharers)" % sharers)
	check(sampler.last() == 0.0, "low_ammo is 0.0 with a full magazine")

	await _fire_down_to(6)
	await frames(3)
	check(sampler.last() == 0.0, "still 0.0 at mag 6 (threshold is mag <= 5)")
	var p: Node = game.player
	var start := await _fire_down_to(5)
	var end := await _until(1.0)
	var t_in := _span(start, end)
	check(end > 0 and _near(t_in, 0.25, dt), "R1/R3 fade-in 0 -> 1 took %.4f s game time (want 0.25 +- %.4f)" % [t_in, dt])
	check(_max_step(start, end) <= _rate(4.0) + EPS, "R1 rises at most 4.0/s x delta per frame (max step %.4f)" % _max_step(start, end))
	await frames(5)
	check(sampler.last() == 1.0 and p.mag == 5, "holds at 1.0 while mag stays 5")

	start = await _reload()
	end = await _until(0.0)
	var t_out := _span(start, end)
	check(end > 0 and _near(t_out, 0.5, dt), "R2/R3 fade-out 1 -> 0 took %.4f s game time (want 0.50 +- %.4f)" % [t_out, dt])
	check(_max_step(start, end) <= _rate(2.0) + EPS, "R2 falls at most 2.0/s x delta per frame (max step %.4f)" % _max_step(start, end))
	_drop_sampler()


func _rate(per_second: float) -> float:
	return per_second * dt


func _scenario_retrigger() -> void:
	await _fresh_game()
	var p: Node = game.player
	await _fire_down_to(5)
	await _until(1.0)
	# Test setup (not the driver): leave one round in reserve so the reload
	# brings the magazine to exactly 6 and one shot ends it again.
	p.reserve = 1
	await _reload()
	check(p.mag == 6, "reload with 1 in reserve gives mag 6 (state ends)")
	while sampler.last() > 0.55:
		await frame()
	var v: float = sampler.last()
	var start := await _fire_down_to(5)
	var end := await _until(1.0)
	var low := _min_value(start, end)
	check(low >= v - EPS, "R4 retrigger at %.3f never dropped below it (min %.4f)" % [v, low])
	var t := _span(start, end)
	check(end > 0 and _near(t, (1.0 - v) * 0.25, dt), "R4 extend from %.3f took %.4f s (want %.4f +- %.4f)" % [v, t, (1.0 - v) * 0.25, dt])
	_drop_sampler()


func _scenario_time_scale() -> void:
	await _fresh_game()
	Engine.time_scale = 0.5
	var start := await _fire_down_to(5)
	var end := await _until(1.0)
	var r: Array[Dictionary] = sampler.records
	var real_s := float(r[end].f - r[start].f + 1) * dt
	var game_s := _span(start, end)
	Engine.time_scale = 1.0
	check(end > 0 and _near(real_s, 0.5, dt), "R5 at time_scale 0.5 fade-in took %.4f s real time (want 0.50 +- %.4f)" % [real_s, dt])
	check(_near(game_s, 0.25, dt * 0.5), "R5 ... and %.4f s game time (want 0.25 +- %.4f)" % [game_s, dt * 0.5])
	_drop_sampler()


func _scenario_pause() -> void:
	await _fresh_game()
	var start := await _fire_down_to(5)
	await frame()
	game.set_paused(true)
	await frame()
	var i0 := sampler.records.size() - 1
	var v: float = sampler.last()
	await frames(30)
	var i1 := sampler.records.size() - 1
	var frozen := true
	for i in range(i0, i1 + 1):
		frozen = frozen and sampler.records[i].v == v
	check(v > 0.0 and v < 1.0 and frozen, "R6 paused mid fade-in: low_ammo stayed %.4f for 30 frames" % v)
	game.set_paused(false)
	await frame()
	var after: float = sampler.last()
	check(after >= v and after - v <= _rate(4.0) + EPS, "R6 continued from %.4f to %.4f on unpause (no jump)" % [v, after])
	var end := await _until(1.0)
	var t := _span(start, end)
	check(end > 0 and _near(t, 0.25, dt), "R6 fade-in took %.4f s of unpaused game time (want 0.25 +- %.4f)" % [t, dt])
	_drop_sampler()


func _scenario_end_mid_fade_in() -> void:
	# In play the state cannot end during a 0.25 s fade-in: the only way
	# mag rises is a reload (RELOAD_TIME 1.25 s). So the end is the real
	# ammo_changed signal emitted by the test, not a reload.
	await _fresh_game()
	var p: Node = game.player
	await _fire_down_to(5)
	while sampler.last() < 0.5:
		await frame()
	var v: float = sampler.last()
	var prev: float = v
	p.ammo_changed.emit(6, p.reserve)
	await frame()
	var start := sampler.records.size() - 1
	var end := await _until(0.0)
	var first_step: float = prev - sampler.records[start].v
	check(first_step >= 0.0 and first_step <= _rate(2.0) + EPS, "R7 fell from %.4f with no jump (first step %.4f)" % [v, first_step])
	var t := _span(start, end)
	check(end > 0 and _near(t, v * 0.5, dt), "R7 from %.3f reached 0 in %.4f s (want %.4f +- %.4f) [signal emitted by test]" % [v, t, v * 0.5, dt])
	_drop_sampler()


func _all_nodes(n: Node) -> Array[Node]:
	var out: Array[Node] = [n]
	for c in n.get_children():
		out.append_array(_all_nodes(c))
	return out
