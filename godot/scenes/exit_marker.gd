extends Area2D
## Extraction point. First player entry ends the session: CHAR-CELEBRATE,
## SFX-CLEAR, and MUS-LOOP fades out.

signal cleared

## CHANGE-BRIEF: music fades over ~1-2 s as SFX-CLEAR plays.
@export var music_fade_time := 1.5

var _cleared := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	# The flag, not body_entered alone, is the guard: leaving and re-entering
	# the zone must not refire SFX-CLEAR.
	if _cleared or not body.has_method("celebrate"):
		return
	_cleared = true
	body.celebrate()
	Sound.play_sfx("SFX-CLEAR")
	Sound.fade_out_music(music_fade_time)
	cleared.emit()
