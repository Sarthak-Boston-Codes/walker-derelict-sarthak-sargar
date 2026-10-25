extends Node3D
## Root of the top-down 3D game. Builds the level, player, camera, waves
## and HUD, and owns the run: objective chain, pause, death, win.
##
## Objective chain: find the keycard (Boiler Room) -> open the security
## door -> stand on the extraction lift for Extraction.HOLD_TIME seconds.
## Keyboard shortcuts (pause, mutes) are read by the HUD, which keeps
## processing while the tree is paused.

const Level := preload("res://game3d/level.gd")
const Player := preload("res://game3d/player.gd")
const CameraRig := preload("res://game3d/camera_rig.gd")
const Sfx := preload("res://game3d/sfx.gd")
const Fx := preload("res://game3d/fx.gd")
const Waves := preload("res://game3d/waves.gd")
const Hud := preload("res://game3d/hud.gd")
const Pickup := preload("res://game3d/pickup.gd")
const UI := preload("res://game3d/ui_theme.gd")

const MENU_SCENE := "res://game3d/menu.tscn"
const AMBUSH_SIZE := 8

enum State { PLAYING, DEAD, WON }

var level: Node3D
var player: CharacterBody3D
var camera: Camera3D
var waves: Node
var hud: CanvasLayer
var state := State.PLAYING
var has_keycard := false
var elapsed := 0.0
var _dust: CPUParticles3D


func _ready() -> void:
	add_to_group("game")
	get_tree().paused = false
	var sfx := Sfx.new()
	sfx.name = "Sfx"
	add_child(sfx)
	level = Level.new()
	level.name = "Level"
	add_child(level)
	var fx_root := Node3D.new()
	fx_root.name = "Fx"
	add_child(fx_root)
	Fx.root = fx_root
	Fx.clear()

	player = Player.new()
	player.name = "Player"
	add_child(player)
	player.global_position = level.player_start
	camera = CameraRig.new()
	camera.name = "Camera"
	camera.target = player
	add_child(camera)
	camera.current = true
	player.camera = camera
	player.aim_point = level.player_start + Vector3(0, 0, -4)
	_dust = Fx.make_dust_field()
	add_child(_dust)
	_dust.global_position = level.player_start + Vector3.UP * 1.3

	var actors := Node3D.new()
	actors.name = "Zombies"
	add_child(actors)
	waves = Waves.new()
	waves.name = "Waves"
	waves.level = level
	waves.player = player
	waves.spawn_parent = actors
	add_child(waves)

	hud = Hud.new()
	hud.name = "Hud"
	hud.game = self
	add_child(hud)
	_connect_signals()
	hud.set_health(player.hp, player.MAX_HP)
	hud.set_ammo(player.mag, player.reserve)
	hud.set_objective("Find the security keycard — somewhere in the Boiler Room")
	hud.toast("Survive. Find the keycard. Get out.", UI.TEXT, 2.5)
	UI.use_crosshair(true)


func _connect_signals() -> void:
	player.health_changed.connect(hud.set_health)
	player.ammo_changed.connect(hud.set_ammo)
	player.hurt.connect(hud.flash_hurt)
	player.died.connect(_on_player_died)
	waves.wave_started.connect(func(w: int) -> void:
		hud.toast("WAVE %d" % w, UI.DANGER))
	waves.wave_cleared.connect(func(w: int) -> void:
		Sfx.play("SFX-CLEAR")
		hud.toast("Wave %d cleared" % w, UI.ACCENT))
	for p in get_tree().get_nodes_in_group("pickups"):
		_hook_pickup(p)
	# Ammo boxes from crates appear later.
	get_tree().node_added.connect(func(n: Node) -> void:
		if n.get_script() == Pickup:
			_hook_pickup.call_deferred(n))
	level.locked_door.has_key = func() -> bool: return has_keycard
	level.locked_door.approached_locked.connect(func() -> void:
		hud.toast("LOCKED — needs a keycard", UI.DANGER, 1.2))
	level.locked_door.opened.connect(_on_door_opened)
	level.extraction.progress_changed.connect(func(left: float) -> void:
		hud.set_countdown("EXTRACTING… %.1f" % left if left < level.extraction.HOLD_TIME else ""))
	level.extraction.extracted.connect(_on_extracted)


func _hook_pickup(p: Node) -> void:
	if is_instance_valid(p) and not p.picked.is_connected(_on_picked):
		p.picked.connect(_on_picked)


func _on_picked(kind: String) -> void:
	match kind:
		"medkit":
			hud.toast("+%d HEALTH" % int(Pickup.HEAL), Color("#7CFFB0"), 1.0)
		"ammo":
			hud.toast("AMMO", UI.ACCENT, 0.8)
		"keycard":
			has_keycard = true
			hud.set_keycard(true)
			hud.toast("KEYCARD ACQUIRED", Color("#2BD9FF"), 2.0)
			hud.set_objective("Open the security door to the Control Room (Boiler Room, west wall)")


func _on_door_opened() -> void:
	level.unlock_room("Control Room")
	level.rebake_nav()
	level.extraction.power_on()
	hud.set_objective("Reach the extraction lift and hold it for %d seconds" % int(level.extraction.HOLD_TIME))
	hud.toast("They heard the door…", UI.DANGER, 2.0)
	waves.ambush("Control Room", AMBUSH_SIZE)


func _process(delta: float) -> void:
	if state == State.PLAYING:
		elapsed += delta
	# Motes are emitted in world space, so moving the emitter only
	# changes where new ones appear.
	_dust.global_position = player.global_position + Vector3.UP * 1.3
	hud.set_wave(waves.wave, waves.in_break, waves.remaining(), waves.kills)
	hud.objective_target = _objective_target()


func _objective_target() -> Variant:
	if state != State.PLAYING:
		return null
	if not has_keycard:
		return level.keycard.global_position if is_instance_valid(level.keycard) else null
	if not level.locked_door.is_open:
		return level.locked_door.global_position
	return level.extraction.global_position


func set_paused(on: bool) -> void:
	if state != State.PLAYING:
		return
	get_tree().paused = on
	Sfx.muffle_music(on)
	hud.show_pause(on)
	UI.use_crosshair(not on)


func _stats() -> String:
	var minutes := int(elapsed) / 60
	var accuracy: float = 100.0 * player.shots_hit / maxf(player.shots_fired, 1.0)
	return "Wave reached: %d    Kills: %d    Accuracy: %d%%    Time: %d:%02d" % [waves.wave, waves.kills, roundi(accuracy), minutes, int(elapsed) % 60]


func _on_player_died() -> void:
	state = State.DEAD
	waves.active = false
	hud.set_countdown("")
	Sound.fade_out_music(2.0)
	await get_tree().create_timer(1.6).timeout
	UI.use_crosshair(false)
	hud.show_end(false, _stats())


func _on_extracted() -> void:
	state = State.WON
	waves.active = false
	player.controls_enabled = false
	player.set_physics_process(false)
	hud.set_countdown("")
	Sfx.play("SFX-CLEAR", 1.0, 3.0)
	Sfx.play("SFX-CLEAR", 0.75, 0.0)
	for z in get_tree().get_nodes_in_group("zombies"):
		z.set_physics_process(false)
	# The lift drops away with the player on it; the zombies stay behind.
	var t := create_tween().set_parallel()
	t.tween_property(level.extraction, "position:y", -4.0, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.4)
	t.tween_property(player, "global_position:y", -4.0, 2.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN).set_delay(0.4)
	await get_tree().create_timer(2.0).timeout
	UI.use_crosshair(false)
	hud.show_end(true, _stats())


func restart() -> void:
	_leave()
	get_tree().reload_current_scene()


func to_menu() -> void:
	_leave()
	get_tree().change_scene_to_file(MENU_SCENE)


func _leave() -> void:
	get_tree().paused = false
	Sfx.muffle_music(false)
	UI.use_crosshair(false)
	# Death fades the music out and stops it; bring it back for the next run.
	if not Sound.is_music_playing():
		Sound._music.volume_db = 0.0
		Sound._music.play()
