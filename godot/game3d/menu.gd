extends Node3D
## Main menu: the real factory level slowly orbited by a camera behind a
## title and a few buttons.

const Level := preload("res://game3d/level.gd")
const Sfx := preload("res://game3d/sfx.gd")
const UI := preload("res://game3d/ui_theme.gd")

const GAME_SCENE := "res://game3d/game.tscn"
const ORBIT_CENTER := Vector3(11, 0, -2)

var _camera: Camera3D
var _t := 0.6
var _music_btn: Button
var _sfx_btn: Button


func _ready() -> void:
	get_tree().paused = false
	UI.use_crosshair(false)
	add_child(Sfx.new())
	add_child(Level.new())
	_camera = Camera3D.new()
	_camera.fov = 50.0
	add_child(_camera)
	_camera.current = true
	_place_camera()
	_build_ui()


func _process(delta: float) -> void:
	_t += delta * 0.06
	_place_camera()


func _place_camera() -> void:
	_camera.position = ORBIT_CENTER + Vector3(cos(_t) * 26.0, 21.0, sin(_t) * 22.0)
	_camera.look_at(ORBIT_CENTER, Vector3.UP)


func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UI.make()
	layer.add_child(root)
	var grad := Gradient.new()
	grad.set_color(0, Color(0, 0, 0, 0.85))
	grad.set_color(1, Color(0, 0, 0, 0.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_to = Vector2(0.75, 0)
	var tr := TextureRect.new()
	tr.texture = gt
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(tr)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER_LEFT)
	col.grow_vertical = Control.GROW_DIRECTION_BOTH
	col.position.x = 80
	col.add_theme_constant_override("separation", 14)
	root.add_child(col)
	col.add_child(UI.label("DERELICT", 92, UI.ACCENT))
	col.add_child(UI.label("Lights out. Something's still on the factory floor.", 20, UI.DIM))
	var gap := Control.new()
	gap.custom_minimum_size.y = 18
	col.add_child(gap)
	var start := UI.button("Start", _start)
	col.add_child(start)
	_music_btn = UI.button("", func() -> void:
		Sound.toggle_muted(Sound.MUSIC_BUS)
		_refresh())
	col.add_child(_music_btn)
	_sfx_btn = UI.button("", func() -> void:
		Sound.toggle_muted(Sound.SFX_BUS)
		_refresh())
	col.add_child(_sfx_btn)
	col.add_child(UI.button("Quit", func() -> void: get_tree().quit()))
	_refresh()
	start.grab_focus.call_deferred()

	var help := PanelContainer.new()
	help.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	help.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	help.grow_vertical = Control.GROW_DIRECTION_BEGIN
	help.position += Vector2(-24, -24)
	root.add_child(help)
	var hv := VBoxContainer.new()
	help.add_child(hv)
	hv.add_child(UI.label("HOW TO PLAY", 16, UI.ACCENT))
	for line in ["WASD — move", "Mouse — aim the flashlight", "Left click — fire (hold)",
			"R — reload    F — flashlight", "Esc — pause    M / N — music / sfx",
			"", "Find the keycard in the Boiler Room,", "open the security door,",
			"hold the extraction lift to escape.", "Shoot red barrels. Crates hold ammo."]:
		hv.add_child(UI.label(line, 15))


func _refresh() -> void:
	_music_btn.text = "Music: %s" % ("Off" if Sound.is_muted(Sound.MUSIC_BUS) else "On")
	_sfx_btn.text = "Sound FX: %s" % ("Off" if Sound.is_muted(Sound.SFX_BUS) else "On")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_music"):
		Sound.toggle_muted(Sound.MUSIC_BUS)
		_refresh()
	elif event.is_action_pressed("toggle_sfx"):
		Sound.toggle_muted(Sound.SFX_BUS)
		_refresh()


func _start() -> void:
	Sfx.play("SFX-CLEAR", 1.4, -4.0)
	get_tree().change_scene_to_file(GAME_SCENE)
