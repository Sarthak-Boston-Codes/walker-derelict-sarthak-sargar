extends SceneTree
# Rows: pose x formula (current / +180 offset). Columns: logical facing N, E, S, W.
# Yellow line = logical aim direction (where the shot goes).

const POSES := ["CHAR-IDLE", "CHAR-AIM", "CHAR-SHOOT-FOLLOWTHROUGH"]
const FACINGS := {"N": Vector2.UP, "E": Vector2.RIGHT, "S": Vector2.DOWN, "W": Vector2.LEFT}
const CELL := 110

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var assets = root.get_node("Assets")
	var bg := ColorRect.new()
	bg.color = Color("#3A3C3B")
	bg.size = Vector2(4 * CELL + 120, POSES.size() * 2 * CELL)
	root.add_child(bg)
	var row := 0
	for pose in POSES:
		for offset in [0.0, PI]:
			var lbl := Label.new()
			lbl.text = "%s\n%s" % [pose.trim_prefix("CHAR-").left(9), "current" if offset == 0.0 else "+180"]
			lbl.position = Vector2(4, row * CELL + 40)
			lbl.add_theme_font_size_override("font_size", 11)
			root.add_child(lbl)
			var col := 0
			for f in FACINGS:
				var dir: Vector2 = FACINGS[f]
				var center := Vector2(120 + col * CELL + CELL / 2.0, row * CELL + CELL / 2.0)
				var s := Sprite2D.new()
				s.texture = assets.texture(pose)
				s.position = center
				s.rotation = dir.angle() + PI / 2.0 + offset # player.gd _face() (+ offset)
				root.add_child(s)
				var line := Line2D.new()
				line.points = [center + dir * 20, center + dir * 50]
				line.width = 2
				line.default_color = Color(0.95, 0.76, 0.31)
				root.add_child(line)
				if row == 0:
					var h := Label.new()
					h.text = "aim " + f
					h.position = center + Vector2(-14, -54)
					h.add_theme_font_size_override("font_size", 11)
					root.add_child(h)
				col += 1
			row += 1
	for i in 4: await process_frame
	var img := root.get_texture().get_image()
	var sc := root.get_final_transform().get_scale().x
	img = img.get_region(Rect2i(0, 0, int(bg.size.x * sc), int(bg.size.y * sc)))
	img.resize(int(bg.size.x * 1.5), int(bg.size.y * 1.5), Image.INTERPOLATE_LANCZOS)
	img.save_png(OS.get_environment("SHOT_PATH"))
	print("saved")
	quit()
