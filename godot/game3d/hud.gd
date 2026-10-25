extends CanvasLayer
## In-game HUD plus the pause, death and win overlays. Built in code.
## Keeps running while the tree is paused so the pause menu works.

const UI := preload("res://game3d/ui_theme.gd")

const VIGNETTE_SHADER := """
shader_type canvas_item;
uniform float base = 0.45;
uniform float hurt = 0.0;
void fragment() {
	float d = distance(UV, vec2(0.5));
	float v = smoothstep(0.3, 0.85, d);
	float h = smoothstep(0.15, 0.75, d) * hurt;
	COLOR = vec4(mix(vec3(0.0), vec3(0.55, 0.0, 0.0), clamp(h * 2.0, 0.0, 1.0)), clamp(v * base + h, 0.0, 0.95));
}
"""

var game: Node
## World position the objective marker points at (null = hidden).
var objective_target: Variant = null

var _health_bar: ProgressBar
var _health_label: Label
var _ammo_label: Label
var _reload_bar: ProgressBar
var _key_label: Label
var _wave_label: Label
var _left_label: Label
var _kills_label: Label
var _objective: Label
var _toast: Label
var _countdown: Label
var _vignette: ShaderMaterial
var _pause: Control
var _end: Control
var _end_title: Label
var _end_stats: Label
var _music_btn: Button
var _sfx_btn: Button
var _hurt := 0.0
var _toast_tween: Tween
var _marker: Polygon2D
var _marker_label: Label
var _out_warned := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = UI.make()
	add_child(root)

	var vig := ColorRect.new()
	vig.set_anchors_preset(Control.PRESET_FULL_RECT)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = VIGNETTE_SHADER
	_vignette = ShaderMaterial.new()
	_vignette.shader = sh
	vig.material = _vignette
	root.add_child(vig)

	# Top-left: health, ammo, keycard.
	var tl := _panel(root, Control.PRESET_TOP_LEFT, Vector2(16, 16))
	var tlv := VBoxContainer.new()
	tlv.add_theme_constant_override("separation", 4)
	tl.add_child(tlv)
	var hrow := HBoxContainer.new()
	tlv.add_child(hrow)
	hrow.add_child(UI.label("HEALTH", 14, UI.DIM))
	_health_label = UI.label("100", 14)
	_health_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hrow.add_child(_health_label)
	_health_bar = ProgressBar.new()
	_health_bar.custom_minimum_size = Vector2(240, 16)
	_health_bar.show_percentage = false
	_health_bar.max_value = 100
	_health_bar.value = 100
	tlv.add_child(_health_bar)
	var arow := HBoxContainer.new()
	tlv.add_child(arow)
	arow.add_child(UI.label("AMMO", 14, UI.DIM))
	_ammo_label = UI.label("15 / 45", 30, UI.ACCENT)
	_ammo_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ammo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	arow.add_child(_ammo_label)
	_reload_bar = ProgressBar.new()
	_reload_bar.custom_minimum_size = Vector2(240, 6)
	_reload_bar.show_percentage = false
	_reload_bar.max_value = 1.0
	_reload_bar.add_theme_stylebox_override("fill", UI.fill(UI.ACCENT))
	_reload_bar.modulate.a = 0.0
	tlv.add_child(_reload_bar)
	_key_label = UI.label("◆ KEYCARD", 16, Color("#2BD9FF"))
	_key_label.visible = false
	tlv.add_child(_key_label)

	# Top-right: wave info.
	var tr := _panel(root, Control.PRESET_TOP_RIGHT, Vector2(-16, 16))
	var trv := VBoxContainer.new()
	tr.add_child(trv)
	_wave_label = UI.label("GET READY", 28, UI.ACCENT)
	_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	trv.add_child(_wave_label)
	_left_label = UI.label("", 16)
	_left_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	trv.add_child(_left_label)
	_kills_label = UI.label("Kills 0", 16, UI.DIM)
	_kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	trv.add_child(_kills_label)

	# Top-centre objective.
	_objective = UI.label("", 18)
	_objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_objective.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_objective.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_objective.position.y = 22
	root.add_child(_objective)

	_toast = UI.label("", 40, UI.ACCENT)
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.set_anchors_preset(Control.PRESET_CENTER)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.grow_vertical = Control.GROW_DIRECTION_BOTH
	_toast.position.y -= 150
	_toast.modulate.a = 0.0
	root.add_child(_toast)

	_countdown = UI.label("", 34, Color("#3BE07A"))
	_countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_countdown.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_countdown.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_countdown.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_countdown.position.y -= 70
	root.add_child(_countdown)

	var hint := UI.label("WASD move · mouse aim · click fire · R reload · F light · M music · N sfx · Esc pause", 13, UI.DIM)
	hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint.position += Vector2(-14, -10)
	root.add_child(hint)

	# Objective marker: a chevron over the target, or pinned to the screen
	# edge pointing at it when it's off-screen.
	_marker = Polygon2D.new()
	_marker.polygon = PackedVector2Array([Vector2(0, -16), Vector2(12, 8), Vector2(0, 2), Vector2(-12, 8)])
	_marker.color = UI.ACCENT
	_marker.visible = false
	root.add_child(_marker)
	_marker_label = UI.label("", 14, UI.ACCENT)
	_marker_label.visible = false
	root.add_child(_marker_label)

	_build_pause(root)
	_build_end(root)


func _panel(root: Control, preset: int, offset: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.set_anchors_preset(preset)
	if preset == Control.PRESET_TOP_RIGHT:
		p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	p.position += offset
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(p)
	return p


func _overlay(root: Control) -> Array:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.visible = false
	root.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(v)
	return [dim, v]


func _build_pause(root: Control) -> void:
	var o := _overlay(root)
	_pause = o[0]
	var v: VBoxContainer = o[1]
	var title := UI.label("PAUSED", 44, UI.ACCENT)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	v.add_child(UI.button("Resume", func() -> void: game.set_paused(false)))
	v.add_child(UI.button("Restart", func() -> void: game.restart()))
	_music_btn = UI.button("", func() -> void:
		Sound.toggle_muted(Sound.MUSIC_BUS)
		refresh_mutes())
	v.add_child(_music_btn)
	_sfx_btn = UI.button("", func() -> void:
		Sound.toggle_muted(Sound.SFX_BUS)
		refresh_mutes())
	v.add_child(_sfx_btn)
	v.add_child(UI.button("Main Menu", func() -> void: game.to_menu()))
	refresh_mutes()


func _build_end(root: Control) -> void:
	var o := _overlay(root)
	_end = o[0]
	var v: VBoxContainer = o[1]
	_end_title = UI.label("", 56, UI.DANGER)
	_end_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_end_title)
	_end_stats = UI.label("", 18)
	_end_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_end_stats)
	v.add_child(UI.button("Restart", func() -> void: game.restart()))
	v.add_child(UI.button("Main Menu", func() -> void: game.to_menu()))


func refresh_mutes() -> void:
	if _music_btn:
		_music_btn.text = "Music: %s  (M)" % ("Off" if Sound.is_muted(Sound.MUSIC_BUS) else "On")
		_sfx_btn.text = "Sound FX: %s  (N)" % ("Off" if Sound.is_muted(Sound.SFX_BUS) else "On")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_music"):
		Sound.toggle_muted(Sound.MUSIC_BUS)
		refresh_mutes()
	elif event.is_action_pressed("toggle_sfx"):
		Sound.toggle_muted(Sound.SFX_BUS)
		refresh_mutes()
	elif event.is_action_pressed("pause") and game:
		game.set_paused(not get_tree().paused)


func _process(delta: float) -> void:
	_hurt = maxf(_hurt - delta * 1.8, 0.0)
	var low := 0.0
	if game and is_instance_valid(game.player) and game.player.alive and game.player.hp < 35.0:
		low = 0.18 + sin(Time.get_ticks_msec() / 220.0) * 0.08
	_vignette.set_shader_parameter("hurt", maxf(_hurt, low))
	if game and is_instance_valid(game.player):
		var p: Node = game.player
		_reload_bar.modulate.a = 1.0 if p.is_reloading() else 0.0
		_reload_bar.value = p.reload_progress()
	_update_marker()


func _update_marker() -> void:
	var cam := get_viewport().get_camera_3d()
	var show := objective_target != null and cam != null and not _end.visible
	_marker.visible = show
	_marker_label.visible = show
	if not show:
		return
	var target: Vector3 = objective_target
	var rect := get_viewport().get_visible_rect()
	var margin := 48.0
	var screen := cam.unproject_position(target + Vector3.UP * 1.6)
	var behind := cam.is_position_behind(target)
	var inner := rect.grow(-margin)
	var pulse := 0.75 + 0.25 * sin(Time.get_ticks_msec() / 180.0)
	_marker.modulate.a = pulse
	if not behind and inner.has_point(screen):
		_marker.position = screen + Vector2(0, -6.0 * pulse)
		_marker.rotation = PI # chevron points down at the target
		_marker_label.visible = false
		return
	var center := rect.size / 2.0
	var dir := (screen - center) * (-1.0 if behind else 1.0)
	if dir.length() < 1.0:
		dir = Vector2.UP
	var scale_x: float = (inner.size.x / 2.0) / maxf(absf(dir.x), 0.001)
	var scale_y: float = (inner.size.y / 2.0) / maxf(absf(dir.y), 0.001)
	var edge := center + dir * minf(scale_x, scale_y)
	_marker.position = edge
	_marker.rotation = dir.angle() + PI / 2.0
	var dist := 0.0
	if is_instance_valid(game.player):
		dist = game.player.global_position.distance_to(target)
	_marker_label.text = "%dm" % roundi(dist)
	_marker_label.position = edge - dir.normalized() * 30.0 - Vector2(14, 10)


# --- updates from game.gd ----------------------------------------------------

func set_health(hp: float, max_hp: float) -> void:
	_health_bar.max_value = max_hp
	_health_bar.value = hp
	_health_label.text = str(ceili(hp))


func flash_hurt() -> void:
	_hurt = 0.75


func set_ammo(mag: int, reserve: int) -> void:
	_ammo_label.text = "%d / %d" % [mag, reserve]
	_ammo_label.add_theme_color_override("font_color", UI.DANGER if mag == 0 else UI.ACCENT)
	if mag == 0 and reserve == 0 and not _out_warned:
		_out_warned = true
		toast("OUT OF AMMO — shoot crates open", UI.DANGER, 2.2)
	elif reserve > 0:
		_out_warned = false


func set_keycard(has: bool) -> void:
	_key_label.visible = has


func set_wave(wave: int, in_break: bool, remaining: int, kills: int) -> void:
	_wave_label.text = "WAVE %d" % wave if wave > 0 else "GET READY"
	_left_label.text = "Next wave incoming" if in_break and wave > 0 else ("Infected %d" % remaining if wave > 0 else "")
	_kills_label.text = "Kills %d" % kills


func set_objective(text: String) -> void:
	_objective.text = text


func set_countdown(text: String) -> void:
	_countdown.text = text


func toast(text: String, color := UI.ACCENT, seconds := 1.6) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(seconds)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.5)


func show_pause(on: bool) -> void:
	refresh_mutes()
	_pause.visible = on


func show_end(won: bool, stats: String) -> void:
	_end_title.text = "EXTRACTED" if won else "YOU DIED"
	_end_title.add_theme_color_override("font_color", Color("#3BE07A") if won else UI.DANGER)
	_end_stats.text = stats
	_end.visible = true
	_end.modulate.a = 0.0
	create_tween().tween_property(_end, "modulate:a", 1.0, 0.6)


func is_end_shown() -> bool:
	return _end.visible
