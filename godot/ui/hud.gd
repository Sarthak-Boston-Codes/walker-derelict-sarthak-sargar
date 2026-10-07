extends CanvasLayer
## Mute toggles (checked = audible) plus a debug readout of player state and
## how many times each SFX has fired.

@onready var _music_toggle: CheckButton = %MusicToggle
@onready var _sfx_toggle: CheckButton = %SfxToggle
@onready var _state_label: Label = %StateLabel

var _player_state := "-"


func _ready() -> void:
	_music_toggle.button_pressed = not Sound.is_muted(Sound.MUSIC_BUS)
	_sfx_toggle.button_pressed = not Sound.is_muted(Sound.SFX_BUS)
	_music_toggle.toggled.connect(func(on: bool) -> void: Sound.set_muted(Sound.MUSIC_BUS, not on))
	_sfx_toggle.toggled.connect(func(on: bool) -> void: Sound.set_muted(Sound.SFX_BUS, not on))
	Sound.mute_changed.connect(_on_mute_changed)
	Sound.sfx_played.connect(func(_id: String, _n: int) -> void: _refresh())
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_music"):
		Sound.toggle_muted(Sound.MUSIC_BUS)
	elif event.is_action_pressed("toggle_sfx"):
		Sound.toggle_muted(Sound.SFX_BUS)


func set_player_state(state_name: String) -> void:
	_player_state = state_name
	_refresh()


func _on_mute_changed(bus: String, muted: bool) -> void:
	# set_pressed_no_signal: keep the button in sync without re-firing toggled.
	if bus == Sound.MUSIC_BUS:
		_music_toggle.set_pressed_no_signal(not muted)
	else:
		_sfx_toggle.set_pressed_no_signal(not muted)


func _refresh() -> void:
	var parts := PackedStringArray()
	for id in Sound.counts:
		parts.append("%s %d" % [id.trim_prefix("SFX-"), Sound.counts[id]])
	_state_label.text = "State: %s\nSFX fired: %s" % [_player_state, "  ".join(parts)]
