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
	await frames(1)
