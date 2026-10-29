extends SceneTree
## Calibrates normal_map_check.curl_ratio on one set saved in both
## conventions (Poly Haven concrete_floor_worn_001, nor_gl and nor_dx).
## Written by Claude Code. Reads the source PNGs, not the imported textures
## (an imported normal map is compressed to two channels).
##
##   bash scripts/run-test.sh calibrate_normal_map_check.gd 60

const Check := preload("res://tests/normal_map_check.gd")
const GL := "res://textures/concrete/concrete_floor_worn_001_nor_gl_1k.png"
const DX := "res://tests/fixtures/normal_maps/concrete_floor_worn_001_nor_dx_1k.png"
## Downsampled before the check: at 1k the photo's fine noise pulls both
## conventions toward 1 (0.70 vs 1.30); at 256 px they separate (about 0.3 vs 1.7).
const CAL_SIZE := 256
## Pass: the map's own convention scores below PASS_BELOW and the other
## convention above FAIL_ABOVE. Set from this pair (0.31 / 1.69 at 256 px)
## with margin; pure noise scores about 1 and fails both.
const PASS_BELOW := 0.6
const FAIL_ABOVE := 1.4


static func prepared(path: String) -> Image:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	img.resize(CAL_SIZE, CAL_SIZE, Image.INTERPOLATE_LANCZOS)
	return img


func _initialize() -> void:
	var gl := prepared(GL)
	var dx := prepared(DX)
	print("gl %dx%d format %d, dx %dx%d format %d" % [gl.get_width(), gl.get_height(), gl.get_format(), dx.get_width(), dx.get_height(), dx.get_format()])
	print("curl_ratio  file    directx=false  directx=true")
	print("            nor_gl  %.4f         %.4f" % [Check.curl_ratio(gl, false), Check.curl_ratio(gl, true)])
	print("            nor_dx  %.4f         %.4f" % [Check.curl_ratio(dx, false), Check.curl_ratio(dx, true)])
	var flat := Image.create(64, 64, false, Image.FORMAT_RGB8)
	flat.fill(Color(0.5, 0.5, 1.0))
	print("            flat    %.4f" % Check.curl_ratio(flat, false))
	var ok := Check.curl_ratio(gl, false) < PASS_BELOW and Check.curl_ratio(gl, true) > FAIL_ABOVE 			and Check.curl_ratio(dx, true) < PASS_BELOW and Check.curl_ratio(dx, false) > FAIL_ABOVE
	print("%s calibration: gl reads as GL, dx reads as DX (threshold < %.1f, other > %.1f, at %d px)" % ["PASS" if ok else "FAIL", PASS_BELOW, FAIL_ABOVE, CAL_SIZE])
	quit(0 if ok else 1)
