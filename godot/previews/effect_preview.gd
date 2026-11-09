extends Node
## Frame-strip fixture for the A6 particle effects (CHANGE-BRIEF.md, "The
## frame strip"). Written by Claude Code. Needs a window (Movie Maker):
##
##   godot --path godot res://previews/impact_burst_preview.tscn \
##       --write-movie <abs>/captures/impact_burst/r0/frame.png --fixed-fps 30 --quit-after 60
##
## Loads the real game (level, lighting, flashlight, camera rig at its
## in-game offset), switches waves off, removes zombies, parks the player
## and freezes its controls; the HUD layer is hidden. Then, by frame number (frame 0 = first frame
## written), it either fires the impact burst or drives the wound smoke.
## `-- --control` never starts the effect (a background plate to diff against).
## Optional user arg `-- --repeat=N` re-fires the burst every N frames
## (a held trigger: FIRE_INTERVAL 0.14 s is 4.2 frames at 30 fps).

const IMPACT_BURST := "res://effects/impact_burst.tscn"
const WOUND_SMOKE := "res://effects/wound_smoke.tscn"
## Same as wound_smoke_driver.gd CHEST_HEIGHT.
const CHEST_HEIGHT := 1.25

@export_enum("impact_burst", "wound_smoke") var effect := "impact_burst"
## Where the player stands and looks (x, z on the floor).
@export var player_xz := Vector2(-5, 9.5)
@export var aim_xz := Vector2(-3, 7)
## Effect A: the burst sits this far along the aim, at the shot height,
## facing back along the shot (a zombie's chest, as a hit would be).
@export var hit_distance := 2.5
@export var trigger_frame := 10
## Second trigger; the brief gives none, so -1 (off) unless set.
@export var second_trigger_frame := -1
## Effect B: frames where the condition begins and ends.
@export var condition_begin := 10
@export var condition_end := 130
## amount_ratio while the condition holds: 0.6 = the mapping at hp 30.
@export var smoke_ratio := 0.6
@export var fixed_seed := 12345

var game: Node
var burst: Node3D
var smoke: GPUParticles3D
var _frame := 0
var _repeat := 0
## `-- --noglow`: diagnostic only, switches the level's glow off.
var _noglow := false


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--repeat="):
			_repeat = int(a.trim_prefix("--repeat="))
		_noglow = _noglow or a == "--noglow"
		if a == "--control":
			condition_begin = -1
			trigger_frame = -1
			print("control run: the effect is never started")
	game = load("res://game3d/game.tscn").instantiate()
	add_child(game)
	game.waves.active = false
	for z in get_tree().get_nodes_in_group("zombies"):
		z.queue_free()
	var p: CharacterBody3D = game.player
	p.controls_enabled = false
	p.global_position = Vector3(player_xz.x, 0, player_xz.y)
	p.aim_point = Vector3(aim_xz.x, 0.95, aim_xz.y)
	game.camera.snap()
	# The HUD's intro banner covers the screen centre; the fixture hides the
	# HUD layer so the effect can be read (stated with every strip).
	game.hud.visible = false
	if _noglow:
		(game.level.get_node("Environment") as WorldEnvironment).environment.glow_enabled = false
		print("diagnostic: glow off")
	if effect == "impact_burst":
		burst = (load(IMPACT_BURST) as PackedScene).instantiate()
		game.level.add_child(burst)
		var origin: Vector3 = p.global_position + Vector3.UP * 0.95
		var dir: Vector3 = p.aim_point - origin
		dir.y = 0.0
		dir = dir.normalized()
		burst.global_position = origin + dir * hit_distance
		burst.global_basis = _basis_y_to(-dir)
		_seed(burst)
	else:
		smoke = (load(WOUND_SMOKE) as PackedScene).instantiate()
		smoke.position = Vector3(0, CHEST_HEIGHT, 0)
		p.add_child(smoke)
		_seed(smoke)
	print("preview %s: player %s aim %s" % [effect, p.global_position, p.aim_point])
	await get_tree().process_frame
	var at: Vector3 = burst.global_position if burst else smoke.global_position
	print("effect at %s, on screen at %s" % [at, game.camera.unproject_position(at)])


## Fixed seed on the preview instance only (never in the effect scene).
func _seed(n: Node) -> void:
	for c in [n] + n.get_children():
		if c is GPUParticles3D:
			c.use_fixed_seed = true
			c.seed = fixed_seed


## A basis whose +Y is `up` (the hit normal).
static func _basis_y_to(up: Vector3) -> Basis:
	var y := up.normalized()
	var helper := Vector3.FORWARD if absf(y.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT
	var x := helper.cross(y).normalized()
	return Basis(x, y, x.cross(y))


func _process(_delta: float) -> void:
	if effect == "impact_burst":
		var fire := _frame == trigger_frame or _frame == second_trigger_frame
		if _repeat > 0 and _frame > trigger_frame and (_frame - trigger_frame) % _repeat == 0:
			fire = true
		if fire:
			for c in burst.get_children():
				(c as GPUParticles3D).restart(true)
			print("frame %d: burst fired (Engine frames drawn %d)" % [_frame, Engine.get_frames_drawn()])
			_report_scale(burst.global_position)
	else:
		if _frame == condition_begin:
			smoke.amount_ratio = smoke_ratio
			smoke.emitting = true
			print("frame %d: smoke on, amount_ratio %.2f" % [_frame, smoke_ratio])
			_report_scale(smoke.global_position)
		elif _frame == condition_end:
			smoke.emitting = false
			print("frame %d: smoke off" % _frame)
	_frame += 1


## Screen position of `at` and how many pixels one metre spans there (at
## the 1280 x 720 window), for reading sizes off the strip.
func _report_scale(at: Vector3) -> void:
	var cam: Camera3D = game.camera
	var a := cam.unproject_position(at)
	var right := cam.global_basis.x
	var b := cam.unproject_position(at + right)
	print("  effect at %s, on screen at %s, %.1f px per metre" % [at, a.round(), a.distance_to(b)])
