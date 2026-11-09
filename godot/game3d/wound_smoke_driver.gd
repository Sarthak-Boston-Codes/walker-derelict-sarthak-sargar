extends Node
## Effect B driver (CHANGE-BRIEF.md, Effect B mapping and rules B1-B5).
## Presentation only: reads player.hp through health_changed and died, and
## writes exactly two properties of the smoke emitter: `emitting` and
## `amount_ratio`. Never writes `amount` (that reallocates the particle
## buffer) and never writes game state.
##
## Mapping: while hp <= 60 and the player is alive, emitting = true and
## amount_ratio = clamp((60 - hp) / 50, 0.2, 1.0); otherwise emitting = false.

const SMOKE := preload("res://effects/wound_smoke.tscn")
const THRESHOLD := 60.0
const FULL_AT := 10.0 # hp at which amount_ratio reaches 1.0
const MIN_RATIO := 0.2
## The emitter sits at the player's chest (player capsule is 1.8 m tall).
const CHEST_HEIGHT := 1.25

var smoke: GPUParticles3D
var _alive := true


static func attach(player: Node3D) -> Node:
	var d: Node = (load("res://game3d/wound_smoke_driver.gd") as GDScript).new()
	d.name = "WoundSmokeDriver"
	player.add_child(d)
	d.setup(player)
	return d


func setup(player: Node3D) -> void:
	smoke = SMOKE.instantiate()
	smoke.position = Vector3(0, CHEST_HEIGHT, 0)
	player.add_child(smoke)
	player.health_changed.connect(_on_health_changed)
	player.died.connect(_on_died)
	_alive = player.alive
	_on_health_changed(player.hp, player.MAX_HP)


static func ratio_for(hp: float) -> float:
	return clampf((THRESHOLD - hp) / (THRESHOLD - FULL_AT), MIN_RATIO, 1.0)


func _on_health_changed(hp: float, _max_hp: float) -> void:
	var on := _alive and hp > 0.0 and hp <= THRESHOLD
	if on:
		smoke.amount_ratio = ratio_for(hp)
	if smoke.emitting != on:
		smoke.emitting = on


func _on_died() -> void:
	_alive = false
	smoke.emitting = false
