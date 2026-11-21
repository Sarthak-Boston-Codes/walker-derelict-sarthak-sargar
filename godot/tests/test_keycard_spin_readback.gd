extends SceneTree
## Read-back of the keycard spin, the cycle (CHANGE-BRIEF.md "The sheet",
## "The cycle spec"). Written by Claude Code. Headless:
##
##   bash scripts/run-test.sh test_keycard_spin_readback.gd 60
##
## Reads the clip resource and the scene that owns it, never a copy built
## here: every track resolves to a real node and property; key times within
## half a frame period of k/12; step 1/12; loop_mode LOOP_LINEAR; the update
## mode (asked only of value tracks) UPDATE_DISCRETE; every frame key below
## hframes * vframes; no duplicate across the wrap; the last-key-to-length
## gap equal to the key interval; the sheet's cell count from the texture.
## Then the clip is played headless and the sprite's frame read at each key
## time and after the wrap (a headless run advances clips; it draws
## nothing, so what the cells look like is the strip's job).
## Exit 1 on any FAIL.

const Lib := preload("res://tests/anim_readback_lib.gd")
const CLIP := "res://animations/keycard_spin.tres"
const SCENE := "res://game3d/keycard_icon.tscn"
const SHEET := "res://art/keycard_sheet.png"
const FPS := 12.0
const FRAMES := 8
const CELL := 64

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func _run() -> void:
	print("\n== test_keycard_spin_readback ==")
	var anim: Animation = load(CLIP)
	check(anim != null, "clip loads from %s" % CLIP)
	var scene: PackedScene = load(SCENE)
	check(scene != null, "scene loads from %s" % SCENE)
	if anim == null or scene == null:
		_finish()
		return
	var rig: Node = scene.instantiate()
	root.add_child(rig)
	var ap := rig.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var sprite := rig.get_node_or_null("KeycardIcon") as Sprite2D
	check(ap != null and sprite != null, "scene has KeycardIcon (Sprite2D) and AnimationPlayer")
	if ap == null or sprite == null:
		_finish()
		return
	var anim_root := ap.get_node(ap.root_node)

	# The player plays the committed resource, not a copy.
	check(ap.has_animation(&"spin"), "AnimationPlayer has 'spin'")
	var played := ap.get_animation(&"spin")
	check(played != null and played.resource_path == CLIP, "'spin' is the resource %s (got '%s')" % [CLIP, played.resource_path if played else ""])

	# Tracks resolve.
	var problems := Lib.track_problems(anim, anim_root)
	check(problems.is_empty(), "track_problems: every track resolves to a real node and property %s" % [problems])
	check(anim.get_track_count() == 1, "exactly one track (%d)" % anim.get_track_count())
	var i := Lib.find_track(anim, "KeycardIcon:frame")
	check(i >= 0, "the track is KeycardIcon:frame")
	if i < 0:
		_finish()
		return
	check(anim.track_get_type(i) == Animation.TYPE_VALUE, "KeycardIcon:frame is a value track (%s)" % Lib.type_name(anim.track_get_type(i)))
	check(anim_root.get_node("KeycardIcon") == sprite, "the track's node is the scene's Sprite2D")

	# Clip settings.
	var period := 1.0 / FPS
	check(absf(anim.step - period) < 1e-5, "step = 1/12 (%.7f)" % anim.step)
	check(anim.loop_mode == Animation.LOOP_LINEAR, "loop_mode = LOOP_LINEAR (%d)" % anim.loop_mode)
	check(absf(anim.length - FRAMES * period) < 1e-5, "length = 8/12 = 0.6667 s (%.7f)" % anim.length)
	for t in anim.get_track_count():
		if anim.track_get_type(t) == Animation.TYPE_VALUE:
			check(anim.value_track_get_update_mode(t) == Animation.UPDATE_DISCRETE,
					"value track %d update mode UPDATE_DISCRETE (%d)" % [t, anim.value_track_get_update_mode(t)])

	# Keys.
	var times := Lib.key_times(anim, i)
	check(times.size() == FRAMES, "8 keys (%d)" % times.size())
	var max_dt := 0.0
	var values: Array[int] = []
	for k in times.size():
		max_dt = maxf(max_dt, absf(times[k] - k * period))
		values.append(int(anim.track_get_key_value(i, k)))
	check(max_dt <= period / 2.0, "key times within half a frame period of k/12 (largest error %.9f s, limit %.4f)" % [max_dt, period / 2.0])
	check(max_dt < 1e-5, "key times equal k/12 to float32 precision (largest error %.9f s)" % max_dt)
	var want: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7]
	check(values == want, "key values %s (want %s)" % [values, want])
	var cells := sprite.hframes * sprite.vframes
	var in_sheet := true
	for v in values:
		in_sheet = in_sheet and v >= 0 and v < cells
	check(in_sheet, "every frame key is inside the sheet: 0 <= v < hframes * vframes = %d (%s)" % [cells, values])
	var adjacent_ok := true
	for k in values.size():
		adjacent_ok = adjacent_ok and values[k] != values[(k + 1) % values.size()]
	check(values.size() > 0 and values[-1] != values[0], "no duplicate across the wrap (last %d, first %d)" % [values[-1] if values.size() else -1, values[0] if values.size() else -1])
	check(adjacent_ok, "no two neighbouring keys show the same cell, wrap included")
	if times.size() >= 2:
		var interval := times[1] - times[0]
		var tail := anim.length - times[-1]
		check(absf(tail - interval) < 1e-5, "last key to length %.7f s = key interval %.7f s" % [tail, interval])

	# The sheet.
	var tex: Texture2D = load(SHEET)
	check(sprite.texture == tex, "KeycardIcon's texture is %s" % SHEET)
	check(sprite.hframes == FRAMES and sprite.vframes == 1, "hframes 8, vframes 1 (%d x %d)" % [sprite.hframes, sprite.vframes])
	check(tex.get_width() == CELL * sprite.hframes and tex.get_height() == CELL * sprite.vframes,
			"sheet %d x %d = cells of %d x %d" % [tex.get_width(), tex.get_height(), tex.get_width() / maxi(sprite.hframes, 1), tex.get_height() / maxi(sprite.vframes, 1)])
	check(cells == FRAMES, "sheet cell count hframes * vframes = %d" % cells)

	# AnimationPlayer settings (one authority: nothing autoplays).
	check(ap.autoplay == "", "autoplay empty ('%s')" % ap.autoplay)
	check(ap.process_mode == Node.PROCESS_MODE_PAUSABLE, "process_mode PAUSABLE (%d)" % ap.process_mode)
	check(ap.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE, "callback_mode_process PROCESS_IDLE (%d)" % ap.callback_mode_process)
	check(not ap.is_playing(), "nothing plays at load")

	# Played headless: the frame at each key time and after the wrap.
	ap.play(&"spin")
	var seen: Array[int] = []
	for k in FRAMES + 1:
		var t := k * period + period / 2.0
		ap.seek(t, true)
		seen.append(sprite.frame)
	check(seen == [0, 1, 2, 3, 4, 5, 6, 7, 0], "played: frame mid-way through each key interval, then after the wrap %s" % [seen])
	ap.stop()
	_finish()


func _finish() -> void:
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(1 if _failures > 0 else 0)
