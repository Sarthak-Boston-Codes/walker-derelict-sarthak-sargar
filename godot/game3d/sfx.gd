extends Node
## Polyphonic SFX for the 3D game, reusing the generated sounds from the
## `Assets` table on the SFX bus (so the existing SFX mute still applies).
## The `Sound` autoload keeps owning music and the mutes.
##
## Usage: Sfx.play("SFX-SHOT"), Sfx.play("SFX-DOWN", 0.6, 4.0)

const VOICES := 12

static var _inst: Node

var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _enter_tree() -> void:
	_inst = self


func _ready() -> void:
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)


func _exit_tree() -> void:
	if _inst == self:
		_inst = null


## pitch: playback speed (1 = as authored). volume_db: offset.
static func play(id: String, pitch := 1.0, volume_db := 0.0) -> void:
	if _inst == null:
		return
	_inst._play(id, pitch, volume_db)


func _play(id: String, pitch: float, volume_db: float) -> void:
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = Assets.stream(id)
	p.pitch_scale = pitch * randf_range(0.95, 1.05)
	p.volume_db = volume_db
	p.play()
	# Keep the 2D slice's trigger counters meaningful for 3D events too.
	if Sound.counts.has(id):
		Sound.counts[id] += 1
