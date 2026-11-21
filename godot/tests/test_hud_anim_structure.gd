extends SceneTree
## Structure test for HudAnim, the one authority (CHANGE-BRIEF.md "The
## state machine", "The two clocks", predicted failure 2). Written by
## Claude Code. Headless:
##
##   bash scripts/run-test.sh test_hud_anim_structure.gd 60
##
## 1. The state tables against the resources: every clip a state requests
##    exists in the AnimationPlayer it is played on; every transition the
##    brief lists is in the table and no other.
## 2. Exactly one writer: a scan of the HUD scripts (godot/game3d/*.gd)
##    finds no code other than hud_anim.gd that touches the two rigs, and
##    no write in hud_anim.gd to an animated property (KeycardIcon:frame,
##    Body:rotation, Body/Slide:position, Body/Mag:position), no tween, no
##    AnimationTree, no AnimatedSprite2D.
## 3. In the running game: exactly two AnimationPlayers in the HUD, both
##    autoplay empty, PAUSABLE, PROCESS_IDLE; the current clip read with
##    current_animation (empty at HOLD / HIDDEN).
## Exit 1 on any FAIL.

const HUD_ANIM := "res://game3d/hud_anim.gd"
const SCRIPT_DIR := "res://game3d/"

## The brief's state tables: state -> {event: next}, and the clip each plays.
const BRIEF_RIG := {
	&"HOLD": {&"reload_started": &"RELOAD", &"died": &"DEAD"},
	&"RELOAD": {&"reload_finished": &"HOLD", &"died": &"DEAD"},
	&"DEAD": {},
}
const BRIEF_RIG_CLIP := {&"HOLD": &"", &"RELOAD": &"reload", &"DEAD": &""}
const BRIEF_KEY := {&"HIDDEN": {&"keycard_acquired": &"SPINNING"}, &"SPINNING": {}}
const BRIEF_KEY_CLIP := {&"HIDDEN": &"", &"SPINNING": &"spin"}

var _failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func frames(n: int) -> void:
	for i in n:
		await process_frame


func _run() -> void:
	print("\n== test_hud_anim_structure ==")
	var script: GDScript = load(HUD_ANIM)
	var c := script.get_script_constant_map()
	var rig_table: Dictionary = c.get("RIG_TABLE", {})
	var key_table: Dictionary = c.get("KEY_TABLE", {})

	# 1. Tables against the brief.
	check(rig_table.keys().size() == 3 and rig_table.has(&"HOLD") and rig_table.has(&"RELOAD") and rig_table.has(&"DEAD"),
			"rig states are HOLD, RELOAD, DEAD (%s)" % [rig_table.keys()])
	check(key_table.keys().size() == 2 and key_table.has(&"HIDDEN") and key_table.has(&"SPINNING"),
			"icon states are HIDDEN, SPINNING (%s)" % [key_table.keys()])
	check(c.get("RIG_START") == &"HOLD" and c.get("KEY_START") == &"HIDDEN", "start states HOLD and HIDDEN")
	for s in BRIEF_RIG:
		var on: Dictionary = rig_table.get(s, {}).get("on", {})
		check(on == BRIEF_RIG[s], "rig %s transitions %s (brief %s)" % [s, on, BRIEF_RIG[s]])
		check(rig_table.get(s, {}).get("clip") == BRIEF_RIG_CLIP[s], "rig %s plays '%s'" % [s, BRIEF_RIG_CLIP[s]])
	for s in BRIEF_KEY:
		var on: Dictionary = key_table.get(s, {}).get("on", {})
		check(on == BRIEF_KEY[s], "icon %s transitions %s (brief %s)" % [s, on, BRIEF_KEY[s]])
		check(key_table.get(s, {}).get("clip") == BRIEF_KEY_CLIP[s], "icon %s plays '%s'" % [s, BRIEF_KEY_CLIP[s]])

	# Every requested clip exists in the player it runs on.
	var rig_scene: Node = (load("res://game3d/pistol_rig.tscn") as PackedScene).instantiate()
	var key_scene: Node = (load("res://game3d/keycard_icon.tscn") as PackedScene).instantiate()
	var rap: AnimationPlayer = rig_scene.get_node("AnimationPlayer")
	var kap: AnimationPlayer = key_scene.get_node("AnimationPlayer")
	for s in rig_table:
		var clip: StringName = rig_table[s].clip
		check(clip == &"" or rap.has_animation(clip), "rig %s's clip '%s' exists in pistol_rig.tscn" % [s, clip])
	check(rap.has_animation(c.get("REST_CLIP", &"")), "the rest clip '%s' exists in pistol_rig.tscn" % c.get("REST_CLIP"))
	for s in key_table:
		var clip: StringName = key_table[s].clip
		check(clip == &"" or kap.has_animation(clip), "icon %s's clip '%s' exists in keycard_icon.tscn" % [s, clip])
	check(rap.get_animation(&"reload").loop_mode == Animation.LOOP_NONE, "reload is LOOP_NONE (commits)")
	check(kap.get_animation(&"spin").loop_mode == Animation.LOOP_LINEAR, "spin is LOOP_LINEAR (loops)")
	rig_scene.free()
	key_scene.free()

	# 2. One writer: source scan.
	_scan_sources()

	# 3. The running game.
	var game: Node = load("res://game3d/game.tscn").instantiate()
	root.add_child(game)
	await frames(5)
	var hud: Node = game.hud
	var anim: Node = game.hud_anim
	check(anim != null and anim.get_script() == script and anim.get_parent() == hud, "game.hud_anim is a HudAnim under the HUD")
	var players: Array[Node] = hud.find_children("*", "AnimationPlayer", true, false)
	check(players.size() == 2, "exactly two AnimationPlayers in the HUD (%d)" % players.size())
	check(hud.find_children("*", "AnimationTree", true, false).is_empty(), "no AnimationTree in the HUD")
	check(hud.find_children("*", "AnimatedSprite2D", true, false).is_empty(), "no AnimatedSprite2D in the HUD")
	check(players.has(anim.rig_player) and players.has(anim.icon_player), "they are the rig's and the icon's")
	for ap: AnimationPlayer in players:
		var who := "rig" if ap == anim.rig_player else "icon"
		check(ap.autoplay == "", "%s autoplay empty" % who)
		check(ap.process_mode == Node.PROCESS_MODE_PAUSABLE, "%s process_mode PAUSABLE under a PROCESS_MODE_ALWAYS HUD (HUD %d)" % [who, hud.process_mode])
		check(ap.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_IDLE, "%s callback_mode_process PROCESS_IDLE" % who)
		check(ap.can_process(), "%s processes while the tree runs" % who)
	check(anim.rig_player.get_animation(&"reload").resource_path == "res://animations/pistol_reload.tres", "the running rig plays the committed reload resource")
	check(anim.icon_player.get_animation(&"spin").resource_path == "res://animations/keycard_spin.tres", "the running icon plays the committed spin resource")
	check(anim.rig_state == &"HOLD" and anim.rig_player.current_animation == "", "at scene start: rig HOLD, current_animation '' ('%s')" % anim.rig_player.current_animation)
	check(anim.key_state == &"HIDDEN" and anim.icon_player.current_animation == "" and not anim.icon.visible,
			"at scene start: icon HIDDEN, current_animation '', icon invisible")
	var body: Node2D = anim.rig.get_node("Body")
	check(is_zero_approx(body.rotation) and anim.rig.get_node("Body/Slide").position == Vector2.ZERO and anim.rig.get_node("Body/Mag").position == Vector2.ZERO,
			"rig at the RESET pose at scene start")
	check(anim.icon_root.get_parent() == hud.get("_key_label"), "the icon sits beside the HUD keycard element (child of _key_label)")
	# The pause rule as structure: pausing stops both players processing.
	paused = true
	check(not anim.rig_player.can_process() and not anim.icon_player.can_process(), "with the tree paused neither AnimationPlayer can process")
	check(hud.can_process(), "the HUD itself still processes when paused (pause menu)")
	paused = false

	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	game.queue_free()
	await process_frame
	quit(1 if _failures > 0 else 0)


func _scan_sources() -> void:
	var files := DirAccess.get_files_at(SCRIPT_DIR)
	var scanned := 0
	var touching: Array[String] = []
	var any_tween_on_rig := false
	var anim_tree_or_sprite: Array[String] = []
	var rig_words := RegEx.create_from_string("keycard_icon\\.tscn|pistol_rig\\.tscn|KeycardIcon|PistolRig|rig_player|icon_player|hud_anim")
	for f in files:
		if not f.ends_with(".gd"):
			continue
		scanned += 1
		var path := SCRIPT_DIR + f
		var src := FileAccess.get_file_as_string(path)
		if RegEx.create_from_string("\\bAnimationTree\\b|\\bAnimatedSprite2D\\b").search(_code(src)):
			anim_tree_or_sprite.append(f)
		if path == HUD_ANIM:
			continue
		for m in rig_words.search_all(_code(src)):
			touching.append("%s: %s" % [f, m.get_string()])
	# game.gd may name HudAnim to attach it, nothing else.
	var allowed := ["game.gd: hud_anim"]
	var extra := touching.filter(func(t: String) -> bool: return not allowed.has(t))
	check(scanned > 10, "scanned %d HUD/game scripts in %s" % [scanned, SCRIPT_DIR])
	check(extra.is_empty(), "no script but hud_anim.gd touches the rigs (game.gd only attaches HudAnim: %s; others %s)" % [touching, extra])
	check(anim_tree_or_sprite.is_empty(), "no AnimationTree or AnimatedSprite2D in game3d scripts %s" % [anim_tree_or_sprite])
	var src := _code(FileAccess.get_file_as_string(HUD_ANIM))
	var writes := RegEx.create_from_string("\\.(frame|rotation)\\s*[-+*/]?=[^=]|\\b(body|slide|mag|Body|Slide|Mag)\\b[^\\n]*\\.position\\s*[-+*/]?=[^=]|set_indexed|\\.set\\(\\s*[\"&]+(frame|position|rotation)").search_all(src)
	var w := []
	for m in writes:
		w.append(m.get_string().strip_edges())
	check(w.is_empty(), "hud_anim.gd writes no animated property (frame, rotation, Body/Slide/Mag position): %s" % [w])
	any_tween_on_rig = RegEx.create_from_string("create_tween|Tween|tween_property").search(src) != null
	check(not any_tween_on_rig, "hud_anim.gd uses no tween")
	var pos_writes := RegEx.create_from_string("(\\w+)\\.position\\s*=").search_all(src)
	var targets := []
	for m in pos_writes:
		targets.append(m.get_string(1))
	check(targets.all(func(t: String) -> bool: return t == "rig" or t == "icon_root"),
			"hud_anim.gd sets position only on the rig and icon roots, which no clip animates (%s)" % [targets])
	check(not src.contains("Animation.new()") and not src.contains("track_insert_key") and not src.contains("add_track"),
			"no clip is built in code at run time")
	var calls := RegEx.create_from_string("(rig_player|icon_player)\\.(\\w+)\\(").search_all(src)
	var methods := {}
	for m in calls:
		methods[m.get_string(2)] = true
	check(methods.keys().all(func(k: String) -> bool: return k in ["play", "stop", "seek"]),
			"hud_anim.gd only calls play/stop/seek on the AnimationPlayers (%s)" % [methods.keys()])


## Source without comments and string contents of doc lines.
func _code(src: String) -> String:
	var out := PackedStringArray()
	for line in src.split("\n"):
		var i := line.find("#")
		out.append(line.substr(0, i) if i >= 0 else line)
	return "\n".join(out)
