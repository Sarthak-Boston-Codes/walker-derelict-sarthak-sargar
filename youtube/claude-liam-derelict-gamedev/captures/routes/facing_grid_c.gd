extends SceneTree
# Rows: poses. Columns: 8 logical aim directions, drawn via scenes/facing.gd.
# Yellow line = logical aim (where the shot goes). Also unit-checks Facing.apply.

const Facing := preload("res://scenes/facing.gd")
const POSES := ["CHAR-IDLE", "CHAR-AIM", "CHAR-SHOOT-FOLLOWTHROUGH", "CHAR-HURT", "CHAR-GRABBED-FAIL", "CHAR-WALK", "ZOMBIE-SHAMBLE"]
const DIRS := {"E": 0, "SE": 45, "S": 90, "SW": 135, "W": 180, "NW": 225, "N": 270, "NE": 315}
const CELL := 96
const TILT := deg_to_rad(30.0)

var fails := 0

func _initialize() -> void:
	_run.call_deferred()

func check(label: String, ok: bool) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok: fails += 1

func _run() -> void:
	# --- unit checks
	var s := Sprite2D.new()
	Facing.apply(s, Vector2.RIGHT, TILT)
	check("east: no flip, no tilt", not s.flip_h and is_zero_approx(s.rotation))
	Facing.apply(s, Vector2.LEFT, TILT)
	check("west: flipped, no tilt (upright, never upside-down)", s.flip_h and is_zero_approx(s.rotation))
	Facing.apply(s, Vector2.from_angle(deg_to_rad(160)), TILT)
	check("160 deg: flipped, tilt -20 (%.1f)" % rad_to_deg(s.rotation), s.flip_h and is_equal_approx(rad_to_deg(s.rotation), -20.0))
	Facing.apply(s, Vector2.UP, TILT)
	check("straight north after west: keeps flip (no flicker), tilt capped at 30 (%.1f)" % rad_to_deg(s.rotation), s.flip_h and is_equal_approx(absf(rad_to_deg(s.rotation)), 30.0))
	Facing.apply(s, Vector2.RIGHT, TILT)
	Facing.apply(s, Vector2.DOWN, TILT)
	check("straight south after east: keeps no-flip, tilt +30 (%.1f)" % rad_to_deg(s.rotation), not s.flip_h and is_equal_approx(rad_to_deg(s.rotation), 30.0))
	var worst := 0.0
	for d in 360:
		Facing.apply(s, Vector2.from_angle(deg_to_rad(d)), TILT)
		worst = maxf(worst, absf(s.rotation))
	check("max drawn tilt over 360 aim angles = %.1f deg (never > 30)" % rad_to_deg(worst), rad_to_deg(worst) <= 30.0001)
	s.free()

	# --- render grid
	var assets = root.get_node("Assets")
	var w := 110 + DIRS.size() * CELL
	var h := 24 + POSES.size() * CELL
	var bg := ColorRect.new(); bg.color = Color("#3A3C3B"); bg.size = Vector2(w, h)
	root.add_child(bg)
	var col := 0
	for k in DIRS:
		var lab := Label.new(); lab.text = "aim " + k
		lab.position = Vector2(110 + col * CELL + 26, 2)
		lab.add_theme_font_size_override("font_size", 11)
		root.add_child(lab)
		col += 1
	var row := 0
	for pose in POSES:
		var rl := Label.new(); rl.text = pose.replace("CHAR-", "").replace("-FOLLOWTHROUGH", "").replace("-FAIL", "")
		rl.position = Vector2(4, 24 + row * CELL + 38)
		rl.add_theme_font_size_override("font_size", 11)
		root.add_child(rl)
		col = 0
		var sp := Sprite2D.new() # one sprite per row so flip memory carries like in play
		for k in DIRS:
			var dir := Vector2.from_angle(deg_to_rad(DIRS[k]))
			var c := Vector2(110 + col * CELL + CELL / 2.0, 24 + row * CELL + CELL / 2.0)
			var spr := Sprite2D.new()
			spr.texture = assets.texture(pose)
			spr.position = c
			Facing.apply(sp, dir, TILT)
			spr.flip_h = sp.flip_h
			spr.rotation = sp.rotation
			root.add_child(spr)
			var line := Line2D.new()
			line.points = [c + dir * 22, c + dir * 44]
			line.width = 2
			line.default_color = Color(0.95, 0.76, 0.31)
			root.add_child(line)
			col += 1
		sp.free()
		row += 1
	for i in 4: await process_frame
	var img := root.get_texture().get_image()
	var sc := root.get_final_transform().get_scale().x
	img = img.get_region(Rect2i(0, 0, int(w * sc), int(h * sc)))
	img.resize(int(w * 1.25), int(h * 1.25), Image.INTERPOLATE_LANCZOS)
	img.save_png(OS.get_environment("SHOT_PATH"))
	print("FAILS: ", fails)
	quit(fails)
