extends Node
## Autoloaded as `Sound`. Owns MUS-LOOP, plays SFX by asset ID, and owns the
## Music/SFX mutes. Gameplay code calls play_sfx(id) on the state change that
## should make a sound; anti-double-trigger guards live at those call sites.

signal sfx_played(id: String, count: int)
signal mute_changed(bus: String, muted: bool)

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

## How many times each SFX has fired this session (for trigger-count checks).
var counts := {}

var _music: AudioStreamPlayer
var _sfx := {}
var _fade: Tween


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	_music.stream = Assets.stream("MUS-LOOP")
	add_child(_music)
	for id in Assets.AUDIO:
		if id == "MUS-LOOP":
			continue
		var p := AudioStreamPlayer.new()
		p.bus = SFX_BUS
		p.stream = Assets.stream(id)
		add_child(p)
		_sfx[id] = p
		counts[id] = 0
	_music.play()


func _exit_tree() -> void:
	# A looping stream still playing at shutdown leaks its playback object.
	# Windowed runs exit clean with this; --headless runs still print the
	# leak warning (dummy audio driver), which is harmless.
	_music.stop()


func play_sfx(id: String) -> void:
	assert(_sfx.has(id), "Unknown SFX ID: %s" % id)
	_sfx[id].play()
	counts[id] += 1
	sfx_played.emit(id, counts[id])


func fade_out_music(seconds: float) -> void:
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_music, "volume_db", -60.0, seconds)
	_fade.tween_callback(_music.stop)


func is_music_playing() -> bool:
	return _music.playing


func set_muted(bus: String, muted: bool) -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(bus), muted)
	mute_changed.emit(bus, muted)


func is_muted(bus: String) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus))


func toggle_muted(bus: String) -> void:
	set_muted(bus, not is_muted(bus))
