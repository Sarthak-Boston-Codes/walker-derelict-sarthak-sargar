extends Node
## Headless smoke test for the 3D game: drives the real game scene through
## its main systems without a mouse and counts failures.
##
##   godot --headless --path godot res://tests/game3d_smoke_test.tscn
##
## Exit code = number of failures (0 = pass).

var _failures := 0
var game: Node3D


func _ready() -> void:
	_run.call_deferred()


func check(ok: bool, what: String) -> void:
	print("%s  %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		_failures += 1


func frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _run() -> void:
	print("\n== game3d_smoke_test ==")
	game = load("res://game3d/game.tscn").instantiate()
	add_child(game)
	await frames(10)
	var p: CharacterBody3D = game.player
	p.controls_enabled = false
	check(p.is_on_floor(), "player stands on the floor")
	check(NavigationServer3D.map_get_iteration_id(game.get_world_3d().navigation_map) > 0, "navmesh map is live")

	# Weapon: fire a few shots at the wall, reload refills from reserve.
	p.aim_point = p.global_position + Vector3(0, 0.95, -5)
	var reserve0: int = p.reserve
	for i in 5:
		p.fire()
	check(p.mag == p.MAG_SIZE - 5, "firing uses ammo")
	p.start_reload()
	await get_tree().create_timer(p.RELOAD_TIME + 0.2).timeout
	check(p.mag == p.MAG_SIZE and p.reserve == reserve0 - 5, "reload refills the magazine from reserve")

	await _extra_checks()

	# Damage and death last.
	p.take_damage(30, p.global_position + Vector3.RIGHT)
	check(p.hp == p.MAX_HP - 30, "taking damage lowers health")
	await frames(30)
	p.take_damage(999, p.global_position + Vector3.RIGHT)
	check(not p.alive, "lethal damage kills the player")
	await frames(30)

	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(_failures)


## Later steps add their checks here.
func _extra_checks() -> void:
	await _zombie_checks()


func _zombie_checks() -> void:
	var p: CharacterBody3D = game.player
	game.waves.active = false
	# A shambler 7 m away (navmesh route, round the container) must close in.
	var z: Node3D = game.waves.spawn_zombie("shambler", p.global_position + Vector3(7, 0, -1))
	var d0: float = z.global_position.distance_to(p.global_position)
	await get_tree().create_timer(3.0).timeout
	var d1: float = z.global_position.distance_to(p.global_position)
	check(d1 < d0 - 2.0, "shambler chases the player (%.1f m -> %.1f m)" % [d0, d1])
	var hp0: float = p.hp
	await get_tree().create_timer(3.0).timeout
	check(p.hp < hp0, "shambler reaches and hurts the player (hp %.0f -> %.0f)" % [hp0, p.hp])
	var kills0: int = game.waves.kills
	for i in 5:
		z.hit(1.0, z.global_position + Vector3.UP, Vector3.FORWARD, Vector3.BACK)
	check(game.waves.kills == kills0 + 1 and not z.is_in_group("zombies"), "five hits kill a shambler")
	var r: Node3D = game.waves.spawn_zombie("runner", p.global_position + Vector3(0, 0, -6))
	r.hit(1.0, r.global_position, Vector3.FORWARD, Vector3.BACK)
	r.hit(1.0, r.global_position, Vector3.FORWARD, Vector3.BACK)
	check(not r.is_in_group("zombies"), "two hits kill a runner")
	# Wave director: run it and see wave 1 spawn.
	p.hp = p.MAX_HP
	game.waves.active = true
	await get_tree().create_timer(game.waves.FIRST_DELAY + 2.5).timeout
	check(game.waves.wave == 1 and game.waves.alive_count() > 0, "wave 1 starts and spawns zombies (%d alive)" % game.waves.alive_count())
	game.waves.active = false
	for zz in get_tree().get_nodes_in_group("zombies"):
		zz.queue_free()
	await frames(2)
	p.hp = p.MAX_HP
