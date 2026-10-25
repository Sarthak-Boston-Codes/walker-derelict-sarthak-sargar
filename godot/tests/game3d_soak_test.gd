extends Node
## Soak test: a simple bot plays the real game for SECONDS of game time
## (aims at the nearest visible zombie, fires, reloads, backs off when a
## zombie gets close, grabs nearby pickups) to shake out runtime errors
## under load and give a rough balance read-out.
##
##   godot --headless --path godot res://tests/game3d_soak_test.tscn
##
## Exit code 0 unless the game stops working (no zombies ever spawn).

const SECONDS := 240.0
const Phys := preload("res://game3d/phys.gd")

var game: Node3D
var _t := 0.0
var _died_at := -1.0
var _max_alive := 0
var _wander := Vector2.ZERO
var _wander_left := 0.0


func _ready() -> void:
	Engine.time_scale = 2.0
	game = load("res://game3d/game.tscn").instantiate()
	add_child(game)
	game.player.controls_enabled = false


func _physics_process(delta: float) -> void:
	if game == null:
		return
	_t += delta
	var p: CharacterBody3D = game.player
	_max_alive = maxi(_max_alive, game.waves.alive_count())
	if not p.alive and _died_at < 0.0:
		_died_at = _t
		print("bot died at %.0f s (wave %d, %d kills)" % [_t, game.waves.wave, game.waves.kills])
	if _t >= SECONDS or (_died_at > 0.0 and _t > _died_at + 3.0):
		_finish()
		return
	if not p.alive:
		return
	var target: Node3D = null
	var best := 15.0
	var space := p.get_world_3d().direct_space_state
	for z in get_tree().get_nodes_in_group("zombies"):
		var d: float = z.global_position.distance_to(p.global_position)
		if d < best:
			var q := PhysicsRayQueryParameters3D.create(p.global_position + Vector3.UP, z.global_position + Vector3.UP, Phys.WORLD)
			if space.intersect_ray(q).is_empty():
				best = d
				target = z
	var move := Vector2.ZERO
	if target:
		p.aim_point = target.global_position + Vector3.UP * 0.95
		if p.mag > 0 and p._cooldown <= 0.0 and not p.is_reloading():
			p.fire()
		elif p.mag == 0:
			p.start_reload()
		if best < 3.5:
			var away := p.global_position - target.global_position
			move = Vector2(away.x, away.z).normalized()
	else:
		if p.mag < p.MAG_SIZE / 2:
			p.start_reload()
		move = _forage(p, space)
	p.move_override = move


## Between fights: walk (on the navmesh) to the nearest useful pickup or
## crate, and shoot crates open once close.
func _forage(p: CharacterBody3D, space: PhysicsDirectSpaceState3D) -> Vector2:
	var goal: Node3D = null
	var best := INF
	for n in get_tree().get_nodes_in_group("pickups") + get_tree().get_nodes_in_group("crates"):
		if game.level.locked_rooms.has(game.level.room_at(n.global_position)):
			continue
		var useful: bool = n.is_in_group("crates") or (n.kind == "ammo" and p.reserve < 120) or (n.kind == "medkit" and p.hp < 70)
		var d: float = n.global_position.distance_to(p.global_position)
		if useful and d < best:
			best = d
			goal = n
	if goal == null:
		_wander_left -= get_physics_process_delta_time()
		if _wander_left <= 0.0:
			_wander_left = randf_range(1.0, 3.0)
			_wander = Vector2.from_angle(randf() * TAU) * 0.6
		return _wander
	if goal.is_in_group("crates") and best < 6.0:
		var q := PhysicsRayQueryParameters3D.create(p.global_position + Vector3.UP * 0.4, goal.global_position + Vector3.UP * 0.25, Phys.WORLD)
		if space.intersect_ray(q).is_empty():
			# Aim straight at it; the bot has no mouse, so fire along the line.
			p.aim_point = goal.global_position + Vector3.UP * 0.25
			if p._cooldown <= 0.0 and p.mag > 0 and not p.is_reloading():
				goal.hit(1.0, goal.global_position + Vector3.UP * 0.25, Vector3.FORWARD, Vector3.BACK)
				p.fire()
			return Vector2.ZERO
	var path := NavigationServer3D.map_get_path(p.get_world_3d().navigation_map, p.global_position, goal.global_position, true)
	if path.size() < 2:
		return Vector2.ZERO
	var step := path[1] - p.global_position
	return Vector2(step.x, step.z).normalized()


func _finish() -> void:
	set_physics_process(false)
	Engine.time_scale = 1.0
	print("\n== game3d_soak_test ==")
	for z in get_tree().get_nodes_in_group("zombies"):
		print("alive zombie %s %s state=%d room='%s' agent_target=%s finished=%s" % [z.kind, z.global_position.snapped(Vector3.ONE * 0.1), z.state, game.level.room_at(z.global_position), z._agent.target_position.snapped(Vector3.ONE * 0.1), z._agent.is_navigation_finished()])
	print("player at %s" % game.player.global_position.snapped(Vector3.ONE * 0.1))
	print("shots %d, zombie hits %d (%.0f%%)" % [game.player.shots_fired, game.player.shots_hit, 100.0 * game.player.shots_hit / maxf(game.player.shots_fired, 1)])
	print("game time %.0f s, wave %d, kills %d, max alive %d, hp %.0f, ammo %d/%d, died %s" % [
		_t, game.waves.wave, game.waves.kills, _max_alive, game.player.hp,
		game.player.mag, game.player.reserve, "at %.0f s" % _died_at if _died_at > 0 else "no"])
	var ok: bool = game.waves.kills > 0
	print("PASS" if ok else "FAIL: nothing was killed")
	game.queue_free()
	await get_tree().process_frame
	get_tree().quit(0 if ok else 1)
