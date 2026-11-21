extends SceneTree
## Read-back of the pistol reload, the committing action (CHANGE-BRIEF.md
## "The phase table"). Written by Claude Code. Headless:
##
##   bash scripts/run-test.sh test_pistol_reload_readback.gd 60
##
## Reads the clip resource and the rig scene that owns it: every track
## resolves to a real node and property (the check is branched on track
## type, 3D bone and blend-shape branches included though this rig has
## none); key times and values against the brief's key table (times within
## half a frame period, 1/48 s); each segment's easing as the table names
## it; step 1/24; loop_mode LOOP_NONE; length equal to RELOAD_TIME read
## from player.gd; RESET covers every keyed property at the rest value.
## Then the clip is played headless and the pose read at the phase
## boundaries (a headless run advances clips; it draws nothing).
## Exit 1 on any FAIL.

const Lib := preload("res://tests/anim_readback_lib.gd")
const CLIP := "res://animations/pistol_reload.tres"
const SCENE := "res://game3d/pistol_rig.tscn"
const PLAYER := "res://game3d/player.gd"
const FPS := 24.0

## The brief's key table: path -> [[frame, value, easing into the next key]].
## Easing: "lin" linear (1.0), "in" ease-in (> 1), "out" ease-out (0 < t < 1),
## "inout" ease in-out (< 0).
const TABLE := {
	"Body/Mag:position:y": [[0, 0.0, "lin"], [6, 0.0, "in"], [12, 64.0, "out"], [18, 0.0, "lin"], [30, 0.0, "lin"]],
	"Body/Slide:position:x": [[0, 0.0, "lin"], [18, 0.0, "lin"], [21, -14.0, "in"], [24, 0.0, "lin"], [30, 0.0, "lin"]],
	"Body:rotation": [[0, 0.0, "lin"], [6, -0.21, "lin"], [24, -0.21, "inout"], [30, 0.0, "lin"]],
}

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func _easing_ok(tr: float, kind: String) -> bool:
	match kind:
		"lin": return is_equal_approx(tr, 1.0)
		"in": return tr > 1.0
		"out": return tr > 0.0 and tr < 1.0
		"inout": return tr < 0.0
	return false


func _run() -> void:
	print("\n== test_pistol_reload_readback ==")
	var anim: Animation = load(CLIP)
	var scene: PackedScene = load(SCENE)
	check(anim != null, "clip loads from %s" % CLIP)
	check(scene != null, "scene loads from %s" % SCENE)
	if anim == null or scene == null:
		_finish()
		return
	var rig: Node2D = scene.instantiate()
	root.add_child(rig)
	var ap := rig.get_node_or_null("AnimationPlayer") as AnimationPlayer
	check(ap != null, "PistolRig has an AnimationPlayer")
	check(rig.name == "PistolRig", "scene root is PistolRig (%s)" % rig.name)
	for n in ["Body", "Body/Slide", "Body/Mag"]:
		var node := rig.get_node_or_null(n)
		check(node != null and node.get_class() == "Node2D", "%s is a plain Node2D pivot (%s)" % [n, node.get_class() if node else "missing"])
		var parts := 0
		if node:
			for c in node.get_children():
				if c is Polygon2D:
					parts += 1
		check(parts > 0, "%s holds Polygon2D parts (%d)" % [n, parts])
	if ap == null:
		_finish()
		return
	var anim_root := ap.get_node(ap.root_node)
	check(anim_root == rig, "the AnimationPlayer's root node is PistolRig")
	check(ap.has_animation(&"reload") and ap.get_animation(&"reload").resource_path == CLIP,
			"'reload' is the resource %s" % CLIP)

	# Tracks resolve (branched on type).
	var problems := Lib.track_problems(anim, anim_root)
	check(problems.is_empty(), "track_problems: every track resolves to a real node and property %s" % [problems])
	var types := []
	for i in anim.get_track_count():
		types.append(Lib.type_name(anim.track_get_type(i)))
	print("  track types: %s (no 3D bone or blend-shape tracks: those branches are not exercised by this rig)" % [types])

	# Settings.
	var period := 1.0 / FPS
	check(absf(anim.step - period) < 1e-6, "step = 1/24 (%.9f)" % anim.step)
	check(anim.loop_mode == Animation.LOOP_NONE, "loop_mode = LOOP_NONE (%d)" % anim.loop_mode)
	var reload_time: float = (load(PLAYER) as GDScript).get_script_constant_map().get("RELOAD_TIME", -1.0)
	check(absf(anim.length - reload_time) < 1e-6, "length %.6f s = RELOAD_TIME %.6f s read from player.gd" % [anim.length, reload_time])
	check(is_equal_approx(reload_time * FPS, 30.0), "RELOAD_TIME is 30 frames at 24 fps (%.3f)" % (reload_time * FPS))

	# Keys against the table.
	check(anim.get_track_count() == TABLE.size(), "%d tracks, one per table row (%d)" % [TABLE.size(), anim.get_track_count()])
	print("  frame -> key time (s), from the brief's table and read from the clip:")
	for path in TABLE:
		var i := Lib.find_track(anim, path)
		check(i >= 0, "track %s exists" % path)
		if i < 0:
			continue
		check(anim.track_get_type(i) == Animation.TYPE_VALUE, "%s is a value track" % path)
		check(anim.value_track_get_update_mode(i) == Animation.UPDATE_CONTINUOUS, "%s updates continuously (value track, asked only of value tracks)" % path)
		var rows: Array = TABLE[path]
		check(anim.track_get_key_count(i) == rows.size(), "%s has %d keys (%d)" % [path, rows.size(), anim.track_get_key_count(i)])
		var n := mini(rows.size(), anim.track_get_key_count(i))
		var worst := 0.0
		var values_ok := true
		var ease_ok := true
		var line := "    %-22s" % path
		for k in n:
			var want_t: float = rows[k][0] * period
			var t := anim.track_get_key_time(i, k)
			worst = maxf(worst, absf(t - want_t))
			values_ok = values_ok and is_equal_approx(float(anim.track_get_key_value(i, k)), rows[k][1])
			ease_ok = ease_ok and _easing_ok(anim.track_get_key_transition(i, k), rows[k][2])
			line += " f%d=%.4f" % [rows[k][0], t]
		print(line)
		check(worst <= period / 2.0, "%s key times within half a frame period (1/48 s) of frame/24 (largest error %.9f s)" % [path, worst])
		check(values_ok, "%s key values match the table" % path)
		check(ease_ok, "%s easing per key matches the table (in > 1, out 0..1, in-out < 0)" % path)

	# RESET covers every keyed property, at the rest value.
	check(ap.has_animation(&"RESET"), "RESET animation exists in the rig scene")
	if ap.has_animation(&"RESET"):
		var reset := ap.get_animation(&"RESET")
		check(Lib.track_problems(reset, anim_root).is_empty(), "RESET's tracks resolve")
		for i in anim.get_track_count():
			var path := String(anim.track_get_path(i))
			var j := Lib.find_track(reset, path)
			var ok := j >= 0 and reset.track_get_key_count(j) >= 1 and is_equal_approx(float(reset.track_get_key_value(j, 0)), 0.0)
			check(ok, "RESET keys %s at the rest value 0" % path)
			check(is_equal_approx(float(anim.track_get_key_value(i, 0)), 0.0) and is_equal_approx(float(anim.track_get_key_value(i, anim.track_get_key_count(i) - 1)), 0.0),
					"reload starts and ends %s at the rest value" % path)

	# AnimationPlayer settings.
	check(ap.autoplay == "", "autoplay empty ('%s')" % ap.autoplay)
	check(ap.process_mode == Node.PROCESS_MODE_PAUSABLE, "process_mode PAUSABLE (%d)" % ap.process_mode)
	check(ap.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE, "callback_mode_process PROCESS_IDLE (%d)" % ap.callback_mode_process)
	check(not ap.is_playing(), "nothing plays at load")

	# Played headless: the pose at the phase boundaries.
	var body: Node2D = rig.get_node("Body")
	var slide: Node2D = rig.get_node("Body/Slide")
	var mag: Node2D = rig.get_node("Body/Mag")
	ap.play(&"reload")
	var poses := []
	for t in [0.0, 0.25, 0.5, 0.75, 0.875, 1.0, 1.25]:
		ap.seek(t, true)
		poses.append([t, snappedf(mag.position.y, 0.01), snappedf(slide.position.x, 0.01), snappedf(body.rotation, 0.0001)])
	for p in poses:
		print("  t %.3f s  Mag y %6.2f  Slide x %6.2f  Body rot %7.4f" % p)
	check(_near(poses[2][1], 64.0) and _near(poses[2][3], -0.21), "at 0.5 s (end of startup) the magazine is out (64) and the gun tilted (-0.21)")
	check(_near(poses[3][1], 0.0) and _near(poses[3][2], 0.0), "at 0.75 s (frame 18) the magazine is seated and the slide at rest")
	check(_near(poses[4][2], -14.0), "at 0.875 s (frame 21) the slide is racked back (-14)")
	check(_near(poses[5][2], 0.0) and _near(poses[5][3], -0.21), "at 1.0 s (end of active) the slide is forward, the gun still tilted")
	check(_near(poses[6][1], 0.0) and _near(poses[6][2], 0.0) and _near(poses[6][3], 0.0), "at 1.25 s the rig is at rest")
	ap.stop()
	rig.queue_free()
	_finish()


## Pose values are 32-bit in the clip: compare with a tolerance.
func _near(a: float, b: float) -> bool:
	return absf(a - b) < 1e-3


func _finish() -> void:
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(1 if _failures > 0 else 0)
