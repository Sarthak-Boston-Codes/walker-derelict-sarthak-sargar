extends Node
## Wave director. Waves trickle zombies in from spawn points in unlocked
## rooms that are a fair distance from the player, then a short breather.
## Wave 1 is shamblers only; runners creep in from wave 2.

signal wave_started(wave: int)
signal wave_cleared(wave: int)
signal zombie_killed(total_kills: int)

const Zombie := preload("res://game3d/zombie.gd")

const FIRST_DELAY := 4.0
const BREAK_TIME := 7.0
const MAX_ALIVE := 16
const MIN_SPAWN_DIST := 9.0
const MAX_SPAWN_DIST := 26.0

var level: Node3D
var player: Node3D
var spawn_parent: Node3D
var active := true
var wave := 0
var kills := 0
var in_break := true

var _to_spawn := 0
var _timer := FIRST_DELAY


func _physics_process(delta: float) -> void:
	if not active or not player.alive:
		return
	_timer -= delta
	if in_break:
		if _timer <= 0.0:
			_start_wave()
		return
	if _to_spawn > 0:
		if _timer <= 0.0 and alive_count() < MAX_ALIVE:
			var kind := "runner" if randf() < runner_chance() else "shambler"
			spawn_zombie(kind, _pick_point())
			_to_spawn -= 1
			_timer = maxf(1.5 - wave * 0.1, 0.45)
	elif alive_count() == 0:
		in_break = true
		_timer = BREAK_TIME
		wave_cleared.emit(wave)


func _start_wave() -> void:
	wave += 1
	in_break = false
	_to_spawn = 3 + wave * 3
	_timer = 0.3
	wave_started.emit(wave)


func runner_chance() -> float:
	return clampf(0.15 * (wave - 1), 0.0, 0.55)


func alive_count() -> int:
	return get_tree().get_nodes_in_group("zombies").size()


## Zombies still to come in this wave plus those alive.
func remaining() -> int:
	return _to_spawn + alive_count()


func spawn_zombie(kind: String, pos: Vector3) -> Node3D:
	var z := Zombie.new()
	z.kind = kind
	spawn_parent.add_child(z)
	z.global_position = pos + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6))
	z.died.connect(_on_zombie_died)
	return z


## Spawns a burst right now in one room (used when the control room opens).
func ambush(room: String, count: int) -> void:
	var points: Array = level.spawn_points.filter(func(sp: Dictionary) -> bool: return sp.room == room)
	for i in count:
		var sp: Dictionary = points[i % points.size()]
		spawn_zombie("runner" if i % 3 == 0 else "shambler", sp.pos)


func _pick_point() -> Vector3:
	var ok: Array[Vector3] = []
	var best := Vector3.ZERO
	var best_d := -1.0
	for sp in level.spawn_points:
		if level.locked_rooms.has(sp.room):
			continue
		var d: float = (sp.pos as Vector3).distance_to(player.global_position)
		if d >= MIN_SPAWN_DIST and d <= MAX_SPAWN_DIST:
			ok.append(sp.pos)
		if d > best_d:
			best_d = d
			best = sp.pos
	return ok.pick_random() if not ok.is_empty() else best


func _on_zombie_died(_z: Node3D) -> void:
	kills += 1
	zombie_killed.emit(kills)
