extends SceneTree
## A5 in-engine captures and pixel measurements (Use It). Written by Claude
## Code. Needs a window (not --headless); renders into an off-screen
## 3840x2160 SubViewport, as the A3 film's showcase_capture.gd did, and saves
## frames from it. 2D is laid out at 1280x720 (size_2d_override) so the HUD
## matches the game window, scaled 3x.
##
##   godot --path godot --fixed-fps 60 --script res://tools/a5_capture.gd
##   env MODE = ammo | hint | sweep | twomat | play     OUT = output folder
##
## Prints one JSON line per measurement, prefixed "MEASURE ".

const SIZE := Vector2i(3840, 2160)
const SIZE_2D := Vector2i(1280, 720)
const ACCENT := Color8(242, 193, 78)

var mode := OS.get_environment("MODE")
var out := OS.get_environment("OUT")
var view: SubViewport


func _initialize() -> void:
	assert(mode in ["ammo", "hint", "sweep", "twomat", "play"] and out != "", "set MODE and OUT")
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
	match mode:
		"ammo": await _ammo()
		"hint": await _hint()
		"sweep": await _sweep()
		"twomat": await _twomat()
		"play": await _play()
	quit()


func measure(what: String, data: Dictionary) -> void:
	data["what"] = what
	print("MEASURE ", JSON.stringify(data))


func frames(n: int) -> void:
	for i in n:
		await process_frame


func grab(name: String) -> Image:
	await RenderingServer.frame_post_draw
	var img := view.get_texture().get_image()
	img.convert(Image.FORMAT_RGB8)
	img.save_png(out.path_join(name + ".png"))
	return img


func rgb(img: Image, p: Vector2i) -> Array:
	var c := img.get_pixelv(p)
	return [c.r8, c.g8, c.b8]


func save_crop(img: Image, rect: Rect2i, name: String) -> void:
	img.get_region(rect).save_png(out.path_join(name + ".png"))


# --- low_ammo at controlled values ---------------------------------------------

func _start_game() -> Node:
	var game: Node = load("res://game3d/game.tscn").instantiate()
	view.add_child(game)
	await frames(20)
	game.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	return game


func _ammo() -> void:
	var game := await _start_game()
	var p: Node = game.player
	p.controls_enabled = false
	for i in p.MAG_SIZE - 5:
		p.fire()
		p._cooldown = 0.0
	await frames(30)
	var label: Label = game.hud._ammo_label
	var driver: Node = game.hud.low_ammo
	var mat: ShaderMaterial = label.material
	# Pause the driver, as the assignment's capture() helper does, then set
	# the uniform by hand.
	driver.process_mode = Node.PROCESS_MODE_DISABLED
	var scale := float(SIZE.x) / SIZE_2D.x
	var r2 := label.get_global_rect()
	var rect := Rect2i(Vector2i(r2.position * scale) - Vector2i(12, 12), Vector2i(r2.size * scale) + Vector2i(24, 24))
	var imgs := {}
	for v in [0.0, 0.5, 1.0, 2.0]:
		mat.set_shader_parameter("low_ammo", v)
		await frames(3)
		var img := await grab("ammo_%.1f" % v)
		save_crop(img, rect, "ammo_%.1f_label" % v)
		imgs[v] = img
	var a_b := _pick_pixels(imgs[0.0], rect)
	for v in imgs:
		measure("ammo_pixels", {"low_ammo": v, "text": label.text, "A": a_b.A, "A_rgb": rgb(imgs[v], a_b.A),
				"B": a_b.B, "B_rgb": rgb(imgs[v], a_b.B), "bg": a_b.bg, "bg_rgb": rgb(imgs[v], a_b.bg)})
	# Shadow probe: pixels that are dark at 0.0 and sit one shadow offset
	# (2 px x 3 scale) below-right of a fully covered glyph pixel.
	var off := Vector2i(6, 6)
	var probe := []
	for y in range(rect.position.y, rect.end.y - off.y):
		for x in range(rect.position.x, rect.end.x - off.x):
			var g := Vector2i(x, y)
			var s := g + off
			if _is_accent(imgs[0.0], g) and not _near_accent(imgs[0.0], s):
				probe.append(s)
	for v in imgs:
		var sum := Vector3.ZERO
		for s in probe:
			var c: Color = imgs[v].get_pixelv(s)
			sum += Vector3(c.r8, c.g8, c.b8)
		measure("ammo_shadow", {"low_ammo": v, "pixels": probe.size(), "mean_rgb": [snappedf(sum.x / maxf(probe.size(), 1), 0.1), snappedf(sum.y / maxf(probe.size(), 1), 0.1), snappedf(sum.z / maxf(probe.size(), 1), 0.1)]})
	measure("ammo_setup", {"use_hdr_2d": view.use_hdr_2d, "label_rect_2d": [r2.position.x, r2.position.y, r2.size.x, r2.size.y],
			"shadow_color": label.get_theme_color("font_shadow_color").to_html(), "font_color": label.get_theme_color("font_color").to_html(false)})


func _is_accent(img: Image, p: Vector2i) -> bool:
	return rgb(img, p) == [242, 193, 78]


func _near_accent(img: Image, p: Vector2i) -> bool:
	var c := rgb(img, p)
	return absi(c[0] - 242) + absi(c[1] - 193) + absi(c[2] - 78) < 60


## Pixel A inside the first glyph run (the magazine digit), B inside the
## second (the "/"), each with its 5x5 neighbourhood exactly #F2C14E; bg a
## panel pixel left of the text that is not glyph or shadow.
func _pick_pixels(img: Image, rect: Rect2i) -> Dictionary:
	var cols := []
	for x in range(rect.position.x, rect.end.x):
		var hit := false
		for y in range(rect.position.y, rect.end.y):
			if _near_accent(img, Vector2i(x, y)):
				hit = true
				break
		cols.append(hit)
	var runs := []
	var start := -1
	for i in cols.size():
		if cols[i] and start < 0:
			start = i
		elif not cols[i] and start >= 0:
			runs.append([rect.position.x + start, rect.position.x + i - 1])
			start = -1
	var out_d := {"A": Vector2i(-1, -1), "B": Vector2i(-1, -1), "bg": Vector2i(rect.position.x + 4, rect.position.y + 4), "runs": runs.size()}
	for k in [["A", 0], ["B", 1]]:
		if runs.size() <= k[1]:
			continue
		var best := Vector2i(-1, -1)
		for x in range(runs[k[1]][0], runs[k[1]][1] + 1):
			for y in range(rect.position.y, rect.end.y):
				if _block_accent(img, Vector2i(x, y), 2):
					best = Vector2i(x, y)
					break
			if best.x >= 0:
				break
		out_d[k[0]] = best
	return out_d


func _block_accent(img: Image, p: Vector2i, r: int) -> bool:
	for dy in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if not _is_accent(img, p + Vector2i(dx, dy)):
				return false
	return true


# --- hint experiment -----------------------------------------------------------

func _hint() -> void:
	var scene: Node = load("res://scenes/hint_experiment.tscn").instantiate()
	view.add_child(scene)
	await frames(10)
	var img := await grab("hint_experiment")
	var cam: Camera3D = scene.get_node("Camera3D")
	for q in [["QuadSourceColor", 0.8, "source_color"], ["QuadNoHint", -0.8, "no hint"]]:
		var vals := []
		for x in [-1.0, 0.0, 1.0]:
			var px := Vector2i(cam.unproject_position(Vector3(x, q[1], 0)) * (float(SIZE.x) / SIZE_2D.x))
			vals.append(rgb(img, px))
		measure("hint_bands", {"quad": q[0], "sampler": q[2], "bands_64_128_192": vals})


# --- interface sweep -----------------------------------------------------------

func _lab() -> Node:
	var lab: Node = load("res://scenes/material_lab.tscn").instantiate()
	view.add_child(lab)
	await frames(10)
	return lab


func _tile_stats(img: Image, cam: Camera3D, centre: Vector3) -> Dictionary:
	var k := float(SIZE.x) / SIZE_2D.x
	var a := Vector2i(cam.unproject_position(centre + Vector3(-1.4, 0, -1.4)) * k)
	var b := Vector2i(cam.unproject_position(centre + Vector3(1.4, 0, 1.4)) * k)
	var sum := Vector3.ZERO
	var sq := 0.0
	var n := 0
	for y in range(mini(a.y, b.y), maxi(a.y, b.y), 4):
		for x in range(mini(a.x, b.x), maxi(a.x, b.x), 4):
			var c := img.get_pixel(x, y)
			var l := 0.2126 * c.r8 + 0.7152 * c.g8 + 0.0722 * c.b8
			sum += Vector3(c.r8, c.g8, c.b8)
			sq += l * l
			n += 1
	var mean := sum / maxf(n, 1)
	var lum := 0.2126 * mean.x + 0.7152 * mean.y + 0.0722 * mean.z
	return {"mean_rgb": [snappedf(mean.x, 0.1), snappedf(mean.y, 0.1), snappedf(mean.z, 0.1)], "mean_luma": snappedf(lum, 0.1),
			"luma_sd": snappedf(sqrt(maxf(sq / maxf(n, 1) - lum * lum, 0.0)), 0.1)}


func _sweep() -> void:
	var lab := await _lab()
	var cam: Camera3D = lab.get_node("Camera3D")
	var mat: ShaderMaterial = (lab.get_node("TileDry") as MeshInstance3D).get_surface_override_material(0)
	var sweep := [
		["albedo_tint", [Color.BLACK, Color(0.5, 0.5, 0.5), Color.WHITE], 2],
		["uv_scale", [0.05, 0.5, 2.0], 1],
		["roughness_scale", [0.0, 1.0, 1.0], 1],
		["normal_strength", [0.0, 1.0, 2.0], 1],
		["wetness", [0.0, 0.0, 1.0], 0],
		["wet_darkening", [0.0, 0.35, 1.0], 1],
	]
	for s in sweep:
		var name: String = s[0]
		var keep: Variant = mat.get_shader_parameter(name)
		var labels := ["min", "default", "max"]
		if name == "albedo_tint":
			labels = ["black", "grey", "white(default)"]
		elif name == "roughness_scale":
			labels = ["min", "default(=max)", "max"]
		elif name == "wetness":
			labels = ["min(=default)", "default", "max"]
		for i in 3:
			if (name == "roughness_scale" and i == 2) or (name == "wetness" and i == 1):
				continue
			mat.set_shader_parameter(name, s[1][i])
			if name == "wet_darkening":
				mat.set_shader_parameter("wetness", 1.0)
			await frames(3)
			var img := await grab("sweep_%s_%s" % [name, labels[i].split("(")[0]])
			var st := _tile_stats(img, cam, Vector3(-2.1, 0, 0))
			st["uniform"] = name
			st["setting"] = labels[i]
			st["value"] = str(s[1][i])
			measure("sweep", st)
		mat.set_shader_parameter(name, keep)
		mat.set_shader_parameter("wetness", 0.0)


# --- two materials, one shader -------------------------------------------------

func _twomat() -> void:
	var lab := await _lab()
	var cam: Camera3D = lab.get_node("Camera3D")
	var dry: ShaderMaterial = (lab.get_node("TileDry") as MeshInstance3D).get_surface_override_material(0)
	var shader := dry.shader
	var steps := [["baseline", func() -> void: pass]]
	var original := shader.code
	var line := "\tALBEDO = base * (1.0 - wetness * wet_darkening);"
	steps.append(["shader_line_edited", func() -> void: shader.code = original.replace(line, "\tALBEDO = base * (1.0 - wetness * wet_darkening) * vec3(1.0, 0.35, 0.35);")])
	steps.append(["shader_reverted", func() -> void: shader.code = original])
	steps.append(["dry_value_edited", func() -> void: dry.set_shader_parameter("albedo_tint", Color(1.0, 0.35, 0.35))])
	steps.append(["dry_value_reverted", func() -> void: dry.set_shader_parameter("albedo_tint", Color.WHITE)])
	measure("twomat_setup", {"line_found": original.contains(line), "edited_in": "memory (Shader.code), file on disk untouched"})
	for s in steps:
		s[1].call()
		await frames(4)
		var img := await grab("twomat_" + s[0])
		measure("twomat", {"step": s[0], "dry": _tile_stats(img, cam, Vector3(-2.1, 0, 0)), "wet": _tile_stats(img, cam, Vector3(2.1, 0, 0))})


# --- scripted play -------------------------------------------------------------

func _play() -> void:
	var game := await _start_game()
	var p: Node = game.player
	var label: Label = game.hud._ammo_label
	var mat: ShaderMaterial = label.material
	var reloads := []
	var cycles := 3
	var shot_frames := []
	var frame_i := 0
	var bad_state := 0
	var t0 := 0
	for c in cycles:
		while p.mag > 5:
			Input.action_press("fire")
			var before: int = p.mag
			await process_frame
			frame_i += 1
			if p.mag != before:
				shot_frames.append(frame_i)
		Input.action_release("fire")
		for i in 40: # fade in and hold
			await process_frame
			frame_i += 1
			if i == 6 and c == 0:
				await grab("play_fading_in")
		if c == 0:
			await grab("play_low_ammo")
		var low: float = mat.get_shader_parameter("low_ammo")
		if low != 1.0:
			bad_state += 1
		Input.action_press("reload")
		await process_frame
		Input.action_release("reload")
		t0 = frame_i
		while p.mag <= 5:
			await process_frame
			frame_i += 1
		reloads.append(frame_i - t0)
		for i in 45:
			await process_frame
			frame_i += 1
		if c == 0:
			await grab("play_after_reload")
		if float(mat.get_shader_parameter("low_ammo")) != 0.0:
			bad_state += 1
	var gaps := []
	for i in range(1, shot_frames.size()):
		gaps.append(shot_frames[i] - shot_frames[i - 1])
	var other_materials := 0
	for n in _all(game.hud):
		if n is CanvasItem and n != label and (n as CanvasItem).material != null and n.get_class() == "Label":
			other_materials += 1
	measure("play", {"cycles": cycles, "low_ammo_wrong_after_settle": bad_state, "reload_frames": reloads,
			"fire_gap_frames_min_max": [gaps.min() if gaps.size() else -1, gaps.max() if gaps.size() else -1],
			"MAG_SIZE": p.MAG_SIZE, "RELOAD_TIME": p.RELOAD_TIME, "FIRE_INTERVAL": p.FIRE_INTERVAL,
			"other_labels_with_material": other_materials, "final_text": label.text})


func _all(n: Node) -> Array:
	var out_a := [n]
	for c in n.get_children():
		out_a.append_array(_all(c))
	return out_a
