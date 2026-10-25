extends RefCounted
## Shared look for the 3D game's UI: dark panels, flashlight-yellow
## accents (the CHARACTER-SHEET palette), and a generated crosshair cursor.

const ACCENT := Color("#F2C14E")
const TEXT := Color("#E8E4D8")
const DIM := Color("#8F8B80")
const DANGER := Color("#E5483B")
const PANEL := Color(0.06, 0.065, 0.07, 0.86)

static var _theme: Theme
static var _cursor: Image


static func make() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 20
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.8))
	t.set_constant("shadow_offset_x", "Label", 2)
	t.set_constant("shadow_offset_y", "Label", 2)
	t.set_stylebox("panel", "PanelContainer", _box(PANEL, Color(1, 1, 1, 0.08), 1, 6))
	t.set_stylebox("normal", "Button", _box(Color(0.1, 0.105, 0.11, 0.95), Color(1, 1, 1, 0.12), 1, 4))
	t.set_stylebox("hover", "Button", _box(Color(0.16, 0.15, 0.12, 0.98), ACCENT, 2, 4))
	t.set_stylebox("pressed", "Button", _box(Color(0.24, 0.2, 0.1, 1.0), ACCENT, 2, 4))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), ACCENT, 2, 4))
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", ACCENT)
	t.set_color("font_pressed_color", "Button", ACCENT)
	t.set_color("font_focus_color", "Button", ACCENT)
	t.set_font_size("font_size", "Button", 22)
	t.set_stylebox("background", "ProgressBar", _box(Color(0, 0, 0, 0.6), Color(1, 1, 1, 0.1), 1, 3))
	t.set_stylebox("fill", "ProgressBar", _box(DANGER, Color(0, 0, 0, 0), 0, 3))
	_theme = t
	return t


static func _box(bg: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func fill(color: Color) -> StyleBoxFlat:
	return _box(color, Color(0, 0, 0, 0), 0, 3)


static func label(text: String, size := 20, color := TEXT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


static func button(text: String, on_press: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(260, 48)
	b.pressed.connect(on_press)
	return b


## Ring-and-dot crosshair in the flashlight colour.
static func use_crosshair(on: bool) -> void:
	if not on:
		Input.set_custom_mouse_cursor(null)
		return
	if _cursor == null:
		_cursor = Image.create(32, 32, false, Image.FORMAT_RGBA8)
		for y in 32:
			for x in 32:
				var d := Vector2(x - 15.5, y - 15.5).length()
				var a := 0.0
				if absf(d - 10.0) < 1.2:
					a = 1.0
				elif d < 2.0:
					a = 1.0
				elif absf(d - 10.0) < 2.4:
					a = 0.35
				var c := ACCENT if a > 0.5 else Color(0, 0, 0)
				_cursor.set_pixel(x, y, Color(c.r, c.g, c.b, a))
	Input.set_custom_mouse_cursor(_cursor, Input.CURSOR_ARROW, Vector2(16, 16))
