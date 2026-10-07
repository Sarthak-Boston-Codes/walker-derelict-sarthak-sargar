extends Node
## CHANGE-BRIEF failure case #2: does any sound fire more than once for a
## single event? Runs scripted repeated-input scenarios against the real
## main scene for a fixed number of physics ticks and logs the trigger
## count per event. Also checks every asset ID still loads, so rerun this
## after each placeholder -> real file swap.
##
##   godot --headless --path godot res://tests/trigger_count_test.tscn
##
## Exit code = number of failures (0 = pass).

const MAIN := preload("res://scenes/main.tscn")
const PLAYER_IDLE := 0
const ZOMBIE_SHAMBLE := 0

var _failures := 0
var _main: Node2D
var _player: CharacterBody2D
var _zombie: CharacterBody2D
var _exit: Area2D


func _ready() -> void:
	# Counts don't depend on hearing anything; keep test runs quiet.
	AudioServer.set_bus_mute(0, true)
	_run.call_deferred()


func _run() -> void:
	print("\n== trigger_count_test ==")
	_check_assets()
	print("\n%-10s %-48s %6s %6s %-9s %s" % ["EVENT", "SCENARIO", "TICKS", "COUNT", "EXPECTED", "RESULT"])
	await _shot_held()
	await _shot_spam()
	await _hurt_pinned()
	await _down_repeat()
	await _clear_reenter()
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	AudioServer.set_bus_mute(0, false)
	get_tree().quit(_failures)


# --- scenarios ---------------------------------------------------------------

func _shot_held() -> void:
	await _fresh()
	_zombie.detect_radius = 0.0
	Input.action_press("aim")
	await _ticks(30) # past the wind-up
	var before := _count("SFX-SHOT")
	_fire_event(true) # one press, never released
	await _ticks(120)
	_fire_event(false)
	_report("SFX-SHOT", "fire held 120 ticks after wind-up", 120, _count("SFX-SHOT") - before, 1, 1)
	Input.action_release("aim")


func _shot_spam() -> void:
	await _fresh()
	_zombie.detect_radius = 0.0
	Input.action_press("aim")
	var before := _count("SFX-SHOT")
	var ticks := 180
	for i in ticks:
		_fire_event(true)
		await get_tree().physics_frame
		_fire_event(false)
	# Min shot interval = follow-through + wind-up.
	var interval: float = _player.followthrough_time + _player.aim_windup
	var most := ceili(ticks / (interval * Engine.physics_ticks_per_second))
	_report("SFX-SHOT", "fire pressed every tick (cap %.2fs)" % interval, ticks, _count("SFX-SHOT") - before, 1, most)
	Input.action_release("aim")


func _hurt_pinned() -> void:
	await _fresh()
	var before := _count("SFX-HURT")
	# Whole hit chain + post-hit window, minus a margin, held on the zombie.
	var chain: float = _player.hurt_time + _player.grabbed_time + _player.recover_time + _player.post_hit_invuln
	var ticks := int((chain - 0.2) * Engine.physics_ticks_per_second)
	for i in ticks:
		_player.global_position = _zombie.global_position + Vector2(10, 0)
		await get_tree().physics_frame
	_report("SFX-HURT", "pinned on zombie through hit chain (%.1fs)" % chain, ticks, _count("SFX-HURT") - before, 1, 1)


func _down_repeat() -> void:
	await _fresh()
	var before := _count("SFX-DOWN")
	_zombie.take_shot()
	_zombie.take_shot() # same tick
	await _ticks(60)
	_zombie.take_shot() # already down
	await _ticks(60)
	_report("SFX-DOWN", "3 hits (2 same tick) + 120 ticks down", 120, _count("SFX-DOWN") - before, 1, 1)
	_check("zombie actually went down", _zombie.state != ZOMBIE_SHAMBLE)


func _clear_reenter() -> void:
	await _fresh()
	_zombie.detect_radius = 0.0
	var before := _count("SFX-CLEAR")
	var ticks := 0
	for i in 3:
		_player.global_position = _exit.global_position
		await _ticks(20)
		_player.global_position = _exit.global_position + Vector2(-200, 200)
		await _ticks(20)
		ticks += 40
	_report("SFX-CLEAR", "enter/leave exit zone 3 times", ticks, _count("SFX-CLEAR") - before, 1, 1)


# --- helpers -----------------------------------------------------------------

func _check_assets() -> void:
	var bad := PackedStringArray()
	for id in Assets.ART:
		if Assets.texture(id) == null:
			bad.append(id)
	for id in Assets.AUDIO:
		if Assets.stream(id) == null:
			bad.append(id)
	_check("all %d asset IDs load" % (Assets.ART.size() + Assets.AUDIO.size()), bad.is_empty(), ", ".join(bad))


func _fresh() -> void:
	if _main:
		remove_child(_main)
		_main.free()
	for a in ["aim", "fire", "move_up", "move_down", "move_left", "move_right"]:
		Input.action_release(a)
	_main = MAIN.instantiate()
	add_child(_main)
	_player = _main.get_node("Player")
	_zombie = _main.get_node("Zombie")
	_exit = _main.get_node("ExitMarker")
	await _ticks(2)


func _ticks(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _fire_event(pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = "fire"
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _count(id: String) -> int:
	return Sound.counts[id]


func _report(event: String, scenario: String, ticks: int, got: int, lo: int, hi: int) -> void:
	var ok := got >= lo and got <= hi
	var expected := str(lo) if lo == hi else "%d-%d" % [lo, hi]
	print("%-10s %-48s %6d %6d %-9s %s" % [event, scenario, ticks, got, expected, "ok" if ok else "FAIL"])
	if not ok:
		_failures += 1


func _check(label: String, ok: bool, detail := "") -> void:
	print("%s %s%s" % ["ok  " if ok else "FAIL", label, "" if detail.is_empty() else " (" + detail + ")"])
	if not ok:
		_failures += 1
