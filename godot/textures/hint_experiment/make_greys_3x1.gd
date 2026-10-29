extends SceneTree
## Writes greys_3x1.png for the hint experiment (CHANGE-BRIEF.md section 3):
## one row of three texels, greys 64, 128 and 192. Written by Claude Code.
##
##   godot --headless --path godot --script res://textures/hint_experiment/make_greys_3x1.gd

const OUT := "res://textures/hint_experiment/greys_3x1.png"
const GREYS := [64, 128, 192]


func _initialize() -> void:
	var img := Image.create(GREYS.size(), 1, false, Image.FORMAT_RGB8)
	for x in GREYS.size():
		img.set_pixel(x, 0, Color8(GREYS[x], GREYS[x], GREYS[x]))
	var err := img.save_png(OUT)
	print("wrote %s (%s): %s" % [OUT, error_string(err), [img.get_pixel(0, 0).r8, img.get_pixel(1, 0).r8, img.get_pixel(2, 0).r8]])
	quit(0 if err == OK else 1)
