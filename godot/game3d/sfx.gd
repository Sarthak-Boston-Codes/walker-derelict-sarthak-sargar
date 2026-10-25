extends Node
## Polyphonic SFX for the 3D game, reusing the generated sounds from the
## `Assets` table on the SFX bus (so the existing SFX mute still applies).
## The `Sound` autoload keeps owning music and the mutes.
##
## Usage: Sfx.play("SFX-SHOT"), Sfx.play("SFX-DOWN", 0.6, 4.0)

const VOICES := 12
const MAX_HEAR := 32.0

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


## Like play(), but quieter with distance from the player; silent past
## MAX_HEAR metres. Cheap stand-in for 3D audio that keeps the pooled voices.
static func play_at(id: String, pos: Vector3, pitch := 1.0, volume_db := 0.0) -> void:
	if _inst == null:
		return
	var player := _inst.get_tree().get_first_node_in_group("player") as Node3D
	var d := player.global_position.distance_to(pos) if player else 0.0
	if d > MAX_HEAR:
		return
	_inst._play(id, pitch, volume_db - d * 0.55)


## Muffles the music bus (pause menu) by toggling a low-pass effect.
static func muffle_music(on: bool) -> void:
	var bus := AudioServer.get_bus_index("Music")
	for i in AudioServer.get_bus_effect_count(bus):
		if AudioServer.get_bus_effect(bus, i) is AudioEffectLowPassFilter:
			AudioServer.remove_bus_effect(bus, i)
			break
	if on:
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 700.0
		AudioServer.add_bus_effect(bus, lp)


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
