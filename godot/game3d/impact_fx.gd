extends Node
## Effect A trigger (CHANGE-BRIEF.md, Effect A rules A1-A4). Presentation
## only: listens to player.bullet_hit and plays an impact burst at the hit.
## Never writes game state.
##
## Retrigger rule = overlap: a pool of POOL_SIZE bursts, children of the
## level root (not of the victim, A3). Each hit takes the next free burst;
## if none is free, the oldest is restarted.
##
## "Alive" is kept by this node's own clock: a burst is alive for its longest
## emitter lifetime after it was started. A one-shot GPUParticles3D's
## `emitting` turns false when emission ends (two frames for an explosive
## burst), not when its particles die, so it cannot tell a live burst.

const BURST := preload("res://effects/impact_burst.tscn")
const POOL_SIZE := 12

var pool: Array[Node3D] = []
## Pool indices in the order they were last fired, oldest first.
var order: Array[int] = []
## Bursts fired since attach (for tests).
var fired := 0
## Times the pool was full and the oldest burst was restarted.
var recycled := 0
## Seconds each burst stays alive: its longest emitter lifetime.
var burst_life := 0.0
## Game time (scaled, stops while paused) and per-burst start times.
var clock := 0.0
var _started: Array[float] = []


static func attach(level: Node3D, player: Node) -> Node:
	var fx: Node = (load("res://game3d/impact_fx.gd") as GDScript).new()
	fx.name = "ImpactFx"
	level.add_child(fx)
	fx.setup(level, player)
	return fx


func setup(level: Node3D, player: Node) -> void:
	for i in POOL_SIZE:
		var b: Node3D = BURST.instantiate()
		b.name = "ImpactBurst%d" % i
		level.add_child(b)
		pool.append(b)
		_started.append(-INF)
	for e in pool[0].get_children():
		burst_life = maxf(burst_life, (e as GPUParticles3D).lifetime)
	player.bullet_hit.connect(play)


func _process(delta: float) -> void:
	clock += delta


func play(point: Vector3, normal: Vector3) -> void:
	var i := _free_index()
	if i < 0:
		i = order[0]
		recycled += 1
	order.erase(i)
	order.append(i)
	var b := pool[i]
	b.global_position = point
	b.global_basis = basis_y_to(normal)
	for e in b.get_children():
		(e as GPUParticles3D).restart()
	_started[i] = clock
	fired += 1


## True while pool[i]'s particles can still be alive.
func is_alive(i: int) -> bool:
	return clock - _started[i] < burst_life


func alive_count() -> int:
	var n := 0
	for i in POOL_SIZE:
		if is_alive(i):
			n += 1
	return n


func _free_index() -> int:
	for i in POOL_SIZE:
		if not is_alive(i):
			return i
	return -1


## A basis whose local +Y is `up` (A4: the burst faces out of the surface).
static func basis_y_to(up: Vector3) -> Basis:
	var y := up.normalized()
	if y == Vector3.ZERO:
		return Basis.IDENTITY
	var helper := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := helper.cross(y).normalized()
	return Basis(x, y, x.cross(y))
