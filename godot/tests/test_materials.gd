extends SceneTree
## Material audit (CHANGE-BRIEF.md sections 3-4). Written by Claude Code.
## One PASS/FAIL line per check; exit 1 on any failure.
##
##   bash scripts/run-test.sh test_materials.gd 60

const Cal := preload("res://tests/calibrate_normal_map_check.gd")
const Check := preload("res://tests/normal_map_check.gd")

const CONCRETE := "res://shaders/concrete_surface.gdshader"
const HINT := "res://shaders/hint_experiment.gdshader"
const DRY := "res://materials/concrete_dry.tres"
const WET := "res://materials/concrete_wet.tres"
const HINT_COLOUR := "res://materials/hint_as_colour.tres"
const HINT_DATA := "res://materials/hint_as_data.tres"
const TEX := "res://textures/concrete/concrete_floor_worn_001_%s_1k.png"
const GREYS := "res://textures/hint_experiment/greys_3x1.png"

var _failures := 0


func check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func _initialize() -> void:
	print("\n== test_materials ==")
	_shared_shader()
	_sampler_hints()
	_uniform_list()
	_material_values()
	_import_settings()
	_formats()
	_normal_maps()
	_hint_experiment()
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(1 if _failures > 0 else 0)


func _shared_shader() -> void:
	var dry: ShaderMaterial = load(DRY)
	var wet: ShaderMaterial = load(WET)
	check(dry.shader.resource_path == CONCRETE, "concrete_dry uses %s (got %s)" % [CONCRETE, dry.shader.resource_path])
	check(wet.shader.resource_path == CONCRETE, "concrete_wet uses %s (got %s)" % [CONCRETE, wet.shader.resource_path])
	check(dry.shader == wet.shader, "dry and wet share one Shader resource")
	check(dry != wet, "dry and wet are two ShaderMaterials")


## {uniform name: hint text after the colon} for every uniform in `src`.
func _hints(src: String) -> Dictionary:
	var out := {}
	var re := RegEx.create_from_string("uniform\\s+\\w+\\s+(\\w+)\\s*(?::\\s*([^=;]*))?")
	for m in re.search_all(src):
		var parts := []
		for h in m.get_string(2).split(",", false):
			parts.append(h.strip_edges())
		out[m.get_string(1)] = parts
	return out


func _sampler_hints() -> void:
	var h := _hints(FileAccess.get_file_as_string(CONCRETE))
	check(h.get("albedo_tex", []).has("source_color"), "albedo_tex is sampled as colour (source_color) %s" % [h.get("albedo_tex")])
	check(not h.get("roughness_tex", ["?"]).has("source_color") and h.has("roughness_tex"),
			"roughness_tex is sampled as data (no source_color) %s" % [h.get("roughness_tex")])
	check(h.get("normal_tex", []).has("hint_normal") and not h.get("normal_tex", []).has("source_color"),
			"normal_tex is data with hint_normal, no source_color %s" % [h.get("normal_tex")])
	check(h.get("albedo_tint", []).has("source_color"), "albedo_tint is a source_color vec4")
	for s in ["albedo_tex", "roughness_tex", "normal_tex"]:
		check(h.get(s, []).has("filter_linear_mipmap") and h.get(s, []).has("repeat_enable"), "%s filters with mipmaps and repeats" % s)
	var hh := _hints(FileAccess.get_file_as_string(HINT))
	check(hh.get("tex_as_colour", []) == ["source_color", "filter_nearest"], "hint shader: tex_as_colour is source_color, filter_nearest %s" % [hh.get("tex_as_colour")])
	check(hh.get("tex_as_data", []) == ["filter_nearest"], "hint shader: tex_as_data is filter_nearest only %s" % [hh.get("tex_as_data")])


func _uniform_list() -> void:
	var shader: Shader = load(CONCRETE)
	var u := {}
	for e in shader.get_shader_uniform_list():
		u[e.name] = e
	var want := {
		"albedo_tint": [TYPE_COLOR, ""], "uv_scale": [TYPE_FLOAT, "0.05,2.0"],
		"roughness_scale": [TYPE_FLOAT, "0.0,1.0"], "normal_strength": [TYPE_FLOAT, "0.0,2.0"],
		"wetness": [TYPE_FLOAT, "0.0,1.0"], "wet_darkening": [TYPE_FLOAT, "0.0,1.0"],
		"albedo_tex": [TYPE_OBJECT, ""], "roughness_tex": [TYPE_OBJECT, ""], "normal_tex": [TYPE_OBJECT, ""],
	}
	for n in want:
		var ok: bool = u.has(n) and u[n].type == want[n][0]
		if ok and want[n][1] != "":
			# hint_string is "min,max,step" printed from float32 (0.05 -> 0.05000000074506).
			var got: PackedStringArray = str(u[n].hint_string).split(",")
			var exp: PackedStringArray = want[n][1].split(",")
			ok = u[n].hint == PROPERTY_HINT_RANGE and got.size() >= 2 \
					and is_equal_approx(got[0].to_float(), exp[0].to_float()) and is_equal_approx(got[1].to_float(), exp[1].to_float())
		check(ok, "uniform list: %s type %d%s" % [n, want[n][0], (" range " + want[n][1]) if want[n][1] != "" else ""])


func _material_values() -> void:
	var dry: ShaderMaterial = load(DRY)
	var wet: ShaderMaterial = load(WET)
	var tint_wet := Color("#C8CCD0")
	check(dry.get_shader_parameter("wetness") == 0.0, "dry wetness = 0.0")
	check(is_equal_approx(wet.get_shader_parameter("wetness"), 0.8), "wet wetness = 0.8")
	check(dry.get_shader_parameter("albedo_tint") == Color.WHITE, "dry albedo_tint = white")
	check((wet.get_shader_parameter("albedo_tint") as Color).is_equal_approx(tint_wet), "wet albedo_tint = #C8CCD0 (got %s)" % (wet.get_shader_parameter("albedo_tint") as Color).to_html(false))
	for m in [dry, wet]:
		var label: String = m.resource_path.get_file()
		for p in [["uv_scale", 0.5], ["roughness_scale", 1.0], ["normal_strength", 1.0], ["wet_darkening", 0.35]]:
			check(is_equal_approx(m.get_shader_parameter(p[0]), p[1]), "%s %s = %s" % [label, p[0], p[1]])
		for t in [["albedo_tex", "diff"], ["roughness_tex", "rough"], ["normal_tex", "nor_gl"]]:
			var tex: Texture2D = m.get_shader_parameter(t[0])
			check(tex != null and tex.resource_path == TEX % t[1], "%s %s -> %s" % [label, t[0], TEX % t[1]])


func _import_settings() -> void:
	# compress/mode 2 = VRAM Compressed; compress/normal_map 1 = Enable,
	# 2 = Disable (ResourceImporterTexture). 0 = Lossless.
	for row in [["diff", 2], ["rough", 2], ["nor_gl", 1]]:
		var cf := ConfigFile.new()
		var path: String = (TEX % row[0]) + ".import"
		var err := cf.load(path)
		check(err == OK, "%s loads" % path.get_file())
		check(cf.get_value("params", "compress/mode") == 2, "%s compress/mode = 2 (VRAM Compressed)" % row[0])
		check(cf.get_value("params", "compress/normal_map") == row[1], "%s compress/normal_map = %d (%s)" % [row[0], row[1], "Enable" if row[1] == 1 else "Disable"])
		check(cf.get_value("params", "mipmaps/generate") == true, "%s mipmaps/generate = true" % row[0])
	var g := ConfigFile.new()
	g.load(GREYS + ".import")
	check(g.get_value("params", "compress/mode") == 0, "greys_3x1 compress/mode = 0 (Lossless)")
	check(g.get_value("params", "mipmaps/generate") == false, "greys_3x1 mipmaps/generate = false")


func _formats() -> void:
	# What the importer actually produced (desktop VRAM formats).
	for row in [["diff", [Image.FORMAT_DXT1, Image.FORMAT_DXT5, Image.FORMAT_BPTC_RGBA]],
			["rough", [Image.FORMAT_DXT1, Image.FORMAT_DXT5, Image.FORMAT_BPTC_RGBA]],
			["nor_gl", [Image.FORMAT_RGTC_RG]]]:
		var img := (load(TEX % row[0]) as Texture2D).get_image()
		check(img != null and img.get_format() in row[1] and img.has_mipmaps(),
				"%s imported as format %d, mipmaps %s" % [row[0], img.get_format() if img else -1, img.has_mipmaps() if img else false])
	var gi := (load(GREYS) as Texture2D).get_image()
	check(gi.get_format() == Image.FORMAT_RGB8 and not gi.has_mipmaps() and gi.get_width() == 3 and gi.get_height() == 1,
			"greys_3x1 imported as RGB8 3x1, no mipmaps (format %d)" % gi.get_format())
	check([gi.get_pixel(0, 0).r8, gi.get_pixel(1, 0).r8, gi.get_pixel(2, 0).r8] == [64, 128, 192], "greys_3x1 texels are 64, 128, 192")


func _normal_maps() -> void:
	for row in [[TEX % "nor_gl", false], [Cal.DX, true]]:
		var img := Cal.prepared(row[0])
		var own := Check.curl_ratio(img, row[1])
		var other := Check.curl_ratio(img, not row[1])
		var name: String = row[0].get_file()
		check(own < Cal.PASS_BELOW, "%s curl_ratio in its own convention (directx=%s) %.3f < %.1f" % [name, row[1], own, Cal.PASS_BELOW])
		check(other > Cal.FAIL_ABOVE, "%s curl_ratio in the other convention (directx=%s) %.3f > %.1f" % [name, not row[1], other, Cal.FAIL_ABOVE])


func _hint_experiment() -> void:
	var c: ShaderMaterial = load(HINT_COLOUR)
	var d: ShaderMaterial = load(HINT_DATA)
	check(c.shader.resource_path == HINT and d.shader == c.shader, "both hint materials use hint_experiment.gdshader")
	check(c.get_shader_parameter("read_as_colour") == true and d.get_shader_parameter("read_as_colour") == false, "read_as_colour true / false")
	for m in [c, d]:
		for s in ["tex_as_colour", "tex_as_data"]:
			var t: Texture2D = m.get_shader_parameter(s)
			check(t != null and t.resource_path == GREYS, "%s %s -> greys_3x1.png" % [m.resource_path.get_file(), s])
	var scene: Node = (load("res://scenes/hint_experiment.tscn") as PackedScene).instantiate()
	var env: Environment = scene.get_node("WorldEnvironment").environment
	check(env.tonemap_mode == Environment.TONE_MAPPER_LINEAR and env.tonemap_exposure == 1.0, "hint scene: Linear tonemap, exposure 1.0")
	check(not env.glow_enabled and not env.fog_enabled and not env.adjustment_enabled, "hint scene: glow, fog, adjustments off")
	scene.free()
	var lab: Node = (load("res://scenes/material_lab.tscn") as PackedScene).instantiate()
	var lenv: Environment = lab.get_node("WorldEnvironment").environment
	check(lenv.tonemap_mode == Environment.TONE_MAPPER_LINEAR and lenv.tonemap_exposure == 1.0 and not lenv.ssao_enabled
			and not lenv.ssr_enabled and not lenv.glow_enabled and not lenv.fog_enabled, "material lab: Linear 1.0, SSAO/SSR/glow/fog off")
	var sun: DirectionalLight3D = lab.get_node("Sun45")
	check(is_equal_approx(sun.rotation_degrees.x, -45.0), "material lab: light pitched 45 degrees down (%s)" % sun.rotation_degrees)
	check(lab.get_node("TileDry").get_surface_override_material(0).resource_path == DRY and lab.get_node("TileWet").get_surface_override_material(0).resource_path == WET,
			"material lab: TileDry uses dry, TileWet uses wet")
	lab.free()
