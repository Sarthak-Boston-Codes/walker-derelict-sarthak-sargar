extends Node
## Frame-strip fixture for the A7 HUD clips (CHANGE-BRIEF.md "The frame
## strip"). Written by Claude Code. Needs a window (Movie Maker):
##
##   godot --path godot res://previews/pistol_reload_preview.tscn \
##       --write-movie <abs>/captures/pistol_reload/r0-dark/frame.png --fixed-fps 30 --quit-after 60
##
## Loads the real game (level, lighting, HUD at 1280 x 720, HudAnim wired by
## game.gd), switches waves off, removes zombies and parks the player at
## `player_xz`, looking at `aim_xz`. Nothing here touches the rigs: every
## clip is started by HudAnim from the real signals.
##   reload: one real shot (mouse button 1 through Input.parse_input_event)
##           at frame 2, so the magazine is below 15; then a real R key event
##           parsed on frame trigger_frame - 1, which the player sees on
##           trigger_frame (a parsed event reaches is_action_just_pressed on
##           the next frame), so reload_changed(true) fires on trigger_frame.
##   spin:   at frame pickup_frame the player is placed on the keycard (the
##           same fixture placement game3d_smoke_test uses), the pickup's
##           own overlap check picks it up, game.gd calls hud.set_keycard,
##           HudAnim starts the spin; the next frame the player is put back.
## Frame 0 = the first frame written. Every frame logs the rig pose, the
## clip position and the icon cell, so the strip lines up with the log.

@export_enum("reload", "spin") var clip := "reload"
@export var player_xz := Vector2(27, 3)
@export var aim_xz := Vector2(30, 6)
@export var trigger_frame := 10
@export var pickup_frame := 10

var game: Node
var anim: Node
## Movie frame being processed (0 = first written); set at the start of
## this node's _process, which runs before the game's nodes each frame.
var _frame := -1
var _home := Vector3.ZERO


func _ready() -> void:
	# Optional user args (scouting a background): -- --player=x,z --aim=x,z
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--player="):
			var v := a.trim_prefix("--player=").split(",")
			player_xz = Vector2(float(v[0]), float(v[1]))
		elif a.begins_with("--aim="):
			var v := a.trim_prefix("--aim=").split(",")
			aim_xz = Vector2(float(v[0]), float(v[1]))
	game = load("res://game3d/game.tscn").instantiate()
	add_child(game)
	game.waves.active = false
	for z in get_tree().get_nodes_in_group("zombies"):
		z.queue_free()
	anim = game.hud_anim
	var p: CharacterBody3D = game.player
	_home = Vector3(player_xz.x, 0, player_xz.y)
	p.global_position = _home
	p.aim_point = Vector3(aim_xz.x, 0.95, aim_xz.y)
	game.camera.snap()
	p.reload_changed.connect(func(a: bool) -> void:
		print("frame %d: reload_changed(%s)  mag %d" % [_frame, a, p.mag]))
	game.hud.get("_key_label").visibility_changed.connect(func() -> void:
		print("frame %d: keycard label visible %s" % [_frame, game.hud.get("_key_label").visible]))
	print("preview %s: player %s aim %s" % [clip, p.global_position, p.aim_point])
	# Logged just before each frame is drawn: the line is what that movie
	# frame shows.
	RenderingServer.frame_pre_draw.connect(_log_drawn)


func _fire_event(pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = get_viewport().get_final_transform() * game.camera.unproject_position(game.player.aim_point)
	ev.global_position = ev.position
	Input.parse_input_event(ev)


func _key_event(physical: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = physical
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _process(_delta: float) -> void:
	_frame += 1
	var p: CharacterBody3D = game.player
	# The aim follows the OS cursor in a window; hold it on aim_xz.
	p.aim_point = Vector3(aim_xz.x, 0.95, aim_xz.y)
	if clip == "reload":
		if _frame == 1:
			_fire_event(true)
		elif _frame == 2:
			_fire_event(false)
		elif _frame == trigger_frame - 1:
			_key_event(KEY_R, true)
		elif _frame == trigger_frame:
			_key_event(KEY_R, false)
	else:
		if _frame == pickup_frame:
			p.global_position = game.level.keycard.global_position * Vector3(1, 0, 1) + Vector3(0, 0, 0.9)
		elif anim.key_state == &"SPINNING" and p.global_position != _home:
			p.global_position = _home
			game.camera.snap()


func _log_drawn() -> void:
	var rp: AnimationPlayer = anim.rig_player
	var ip: AnimationPlayer = anim.icon_player
	print("drawn %3d  rig %-6s clip '%s' %.4f  mag_y %6.2f slide_x %6.2f body %7.4f | icon %-8s visible %-5s cell %d %s" % [
		_frame, anim.rig_state, rp.current_animation,
		rp.current_animation_position if rp.current_animation != "" else 0.0,
		anim.rig.get_node("Body/Mag").position.y, anim.rig.get_node("Body/Slide").position.x,
		anim.rig.get_node("Body").rotation, anim.key_state, anim.icon.is_visible_in_tree(), anim.icon.frame,
		"%.4f" % ip.current_animation_position if ip.current_animation != "" else ""])
	if _frame == 0:
		var r: Node2D = anim.rig
		print("rig on screen at %s, icon at %s (canvas px)" % [r.get_global_transform_with_canvas().origin.round(), anim.icon.get_global_transform_with_canvas().origin.round()])
