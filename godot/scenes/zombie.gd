extends CharacterBody2D
## One infected. SHAMBLE until shot, then DOWN for good.
## Chases the player only when within detect_radius.

signal downed

enum State { SHAMBLE, DOWN }

const STATE_ART := {
	State.SHAMBLE: "ZOMBIE-SHAMBLE",
	State.DOWN: "ZOMBIE-DOWN",
}

@export var detect_radius := 220.0
## Slower than the player's aim-walk (60), so backing off while aiming works.
@export var chase_speed := 55.0
## Pillar 2: the hit is visible before it goes down.
@export var hit_flash_time := 0.15
## Shoved this far from the player on a successful grab, so it can't sit on
## the player and re-grab the moment invulnerability ends.
@export var knockback := 80.0

var state := State.SHAMBLE
var _shot := false

@onready var _body: Sprite2D = $Body
@onready var _touch: Area2D = $TouchZone


func _ready() -> void:
	_body.texture = Assets.texture(STATE_ART[state])


func _physics_process(_delta: float) -> void:
	if state == State.DOWN or _shot:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var to_player := player.global_position - global_position
	velocity = Vector2.ZERO
	if to_player.length() <= detect_radius:
		velocity = to_player.normalized() * chase_speed
		_body.rotation = to_player.angle() + PI / 2.0
	move_and_slide()
	# Poll, don't rely on body_entered: a player who stays inside the zone
	# after invulnerability ends must still get hit. The player's own
	# invulnerability window is what stops SFX-HURT double-triggering.
	for body in _touch.get_overlapping_bodies():
		if body.has_method("take_hit") and body.take_hit(global_position):
			move_and_collide((global_position - body.global_position).normalized() * knockback)


## Called by the player's shot raycast.
func take_shot() -> void:
	if state == State.DOWN or _shot:
		return
	_shot = true
	_body.modulate = Color(2.5, 2.5, 2.5)
	await get_tree().create_timer(hit_flash_time, false, true).timeout
	_body.modulate = Color.WHITE
	_go_down()


func _go_down() -> void:
	# The only alive -> down transition, so SFX-DOWN fires exactly once.
	state = State.DOWN
	_body.texture = Assets.texture(STATE_ART[state])
	collision_layer = 0 # shots and the player pass over it
	_touch.set_deferred("monitoring", false)
	Sound.play_sfx("SFX-DOWN")
	downed.emit()
