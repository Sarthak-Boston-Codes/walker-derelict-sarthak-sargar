extends SceneTree
## Film-only captures for the A6 film (Claude Code). Not part of the game.
## Windowed; renders into an off-screen 3840x2160 SubViewport (2D laid out at
## 1280x720, as the A5 film did) and saves one JPG per frame.
##
##   godot --path godot --fixed-fps 30 --script <this file>
##   env MODE = burstplay | smokeplay     OUT = output folder
##
## burstplay: SCRIPTED PLAY with real input. The player stands in the Loading
##   Bay; four shamblers walk in from the right, one after the other. Aim is a
##   mouse-motion event pushed into the viewport at the zombie's screen
##   position every frame; fire is Input.action_press("fire") held throughout.
##   Prints "FRAME i shots victim_hits bursts_fired bursts_alive" (victim_hits =
##   player.shots_hit, which counts zombie hits only).
## smokeplay: SCRIPTED PLAY with real damage and a real medkit. Before frame 0
##   the player takes two real zombie swipes (100 -> 64; not filmed). Frames:
##   a third swipe takes hp to 46 (the smoke starts), the zombie is removed by
##   the script, the player walks right with real move input (the trail), the
##   game's own pause holds for 1 s, then a medkit is dropped on the player
##   (hp > 60: the smoke stops and thins). Prints "FRAME i hp emitting ratio paused".

const SIZE := Vector2i(3840, 2160)
const SIZE_2D := Vector2i(1280, 720)

var mode := OS.get_environment("MODE")
var out := OS.get_environment("OUT")
var view: SubViewport
var game: Node
var n := 0


func _initialize() -> void:
	assert(mode in ["burstplay", "smokeplay"] and out != "", "set MODE and OUT")
	DirAccess.make_dir_recursive_absolute(out)
	view = SubViewport.new()
	view.size = SIZE
	view.size_2d_override = SIZE_2D
	view.size_2d_override_stretch = true
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	_run.call_deferred()


func _run() -> void:
	game = load("res://game3d/game.tscn").instantiate()
	view.add_child(game)
	for i in 90: # past the start toast
		await process_frame
	game.waves.active = false
	for z in get_nodes_in_group("zombies"):
		z.queue_free()
	if mode == "burstplay":
		await _burstplay()
	else:
		await _smokeplay()
	print("saved %d frames" % n)
	quit()


func _aim_at(world: Vector3) -> void:
	var ev := InputEventMouseMotion.new()
	# The camera projects into the 1280x720 2D space; push_input divides by the
	# 3x stretch to 3840x2160, so the event is given in the 4K space.
	ev.position = game.camera.unproject_position(world) * Vector2(SIZE) / Vector2(SIZE_2D)
	ev.global_position = ev.position
	view.push_input(ev)


func _shot() -> void:
	await RenderingServer.frame_post_draw
	view.get_texture().get_image().save_jpg(out.path_join("f%05d.jpg" % n), 0.93)
	n += 1


func _burstplay() -> void:
	var p: Node3D = game.player
	p.global_position = Vector3(-4, 0, 10.5)
	game.camera.snap()
	var target := p.global_position + Vector3(4, 0.95, 0.5)
	_aim_at(target)
	for i in 20:
		await process_frame
	var zs: Array[Node3D] = []
	for k in 4:
		zs.append(game.waves.spawn_zombie("shambler", p.global_position + Vector3(5.5 + k * 1.8, 0, 0.6 + (k % 2) * 1.0)))
	for f in 420:
		var live := zs.filter(func(z: Node3D) -> bool: return is_instance_valid(z) and z.state != z.State.DEAD)
		if live.size() > 0:
			target = (live[0] as Node3D).global_position + Vector3.UP * 0.95
		_aim_at(target)
		if f >= 25 and f < 400 and live.size() > 0:
			Input.action_press("fire")
		else:
			Input.action_release("fire")
		await process_frame
		await _shot()
		print("FRAME %d shots %d victim_hits %d bursts_fired %d bursts_alive %d" % [n - 1, p.shots_fired, p.shots_hit, game.impact_fx.fired, game.impact_fx.alive_count()])
	Input.action_release("fire")


func _swipe() -> void:
	var p: Node3D = game.player
	var hp0: float = p.hp
	var z: Node3D = game.waves.spawn_zombie("shambler", p.global_position + Vector3(0.9, 0, 0))
	var f := 0
	while p.hp == hp0 and f < 150:
		await process_frame
		f += 1
	if is_instance_valid(z):
		z.queue_free()


func _filmed(frames: int) -> void:
	var s: GPUParticles3D = game.wound_smoke.smoke
	for i in frames:
		await process_frame
		await _shot()
		print("FRAME %d hp %.0f emitting %s ratio %.2f paused %s" % [n - 1, game.player.hp, s.emitting, s.amount_ratio, game.get_tree().paused])


func _smokeplay() -> void:
	var p: Node3D = game.player
	p.global_position = Vector3(-6, 0, 9.5)
	p.aim_point = p.global_position + Vector3(0, 0.95, -4)
	game.camera.snap()
	_aim_at(p.global_position + Vector3(0, 0.95, -4))
	var tries := 0
	while p.hp > 64.0 and tries < 10: # not filmed: 100 -> 82 -> 64 (a stalled zombie is replaced)
		await _swipe()
		tries += 1
		for i in 20:
			await process_frame
	print("before filming: hp %.0f, smoke emitting %s" % [p.hp, game.wound_smoke.smoke.emitting])
	await _filmed(15)
	# The third swipe, filmed: 64 -> 46, the smoke starts.
	var hp0: float = p.hp
	var z: Node3D = null
	var waited := 0
	while p.hp == hp0 and n < 400:
		if z == null or waited >= 150: # a stalled zombie is replaced (filmed)
			if is_instance_valid(z):
				z.queue_free()
			z = game.waves.spawn_zombie("shambler", p.global_position + Vector3(0.9, 0, 0))
			waited = 0
		await _filmed(1)
		waited += 1
	if is_instance_valid(z):
		z.queue_free()
	await _filmed(75)
	# Walk right with real input: the trail.
	Input.action_press("move_right")
	await _filmed(60)
	Input.action_release("move_right")
	await _filmed(20)
	# The game's own pause for 1 s.
	game.set_paused(true)
	await _filmed(30)
	game.set_paused(false)
	await _filmed(15)
	# A real medkit on the player: hp 46 -> 86, the smoke stops and thins.
	var m: Area3D = (load("res://game3d/pickup.gd") as GDScript).new()
	m.kind = "medkit"
	game.level.add_child(m)
	m.global_position = p.global_position
	await _filmed(80)
