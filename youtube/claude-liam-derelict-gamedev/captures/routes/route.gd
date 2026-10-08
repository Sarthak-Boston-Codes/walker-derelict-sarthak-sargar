extends SceneTree
## Input-only capture routes for the DERELICT gamedev film (Godot Movie Maker).
##
##   godot --path godot --write-movie OUT.avi --fixed-fps 30 -s route.gd
##   ROUTE env var: clear | grab | mute
##
## Every action is an input event (the project's input-map actions, mouse
## motion, OS cursor warp). The route reads the player's state/position to
## decide its next input, the way a player reacts; it never moves, frees or
## edits a game node, and never changes simulation speed.

const FPS := 30.0

var route := OS.get_environment("ROUTE")
var main: Node2D
var player: Node2D
var zombie: Node2D
var exit_marker: Node2D
var frame := 0
var phase := 0
var phase_start := 0
var aim_point := Vector2(1200, 300)
var held := {}
var log_lines := PackedStringArray()


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	player = main.get_node("Player")
	zombie = main.get_node("Zombie")
	exit_marker = main.get_node("ExitMarker")
	assert(route in ["clear", "grab", "mute"], "ROUTE must be clear|grab|mute")


func _process(_delta: float) -> bool:
	frame += 1
	_mouse(aim_point)
	var done := false
	match route:
		"clear": done = _clear()
		"grab": done = _grab()
		"mute": done = _mute()
	if frame > 30 * FPS: # a route that misses its cue must not run forever
		log_lines.append("TIMEOUT: route did not finish")
		done = true
	if done:
		_write_log()
	return done


# --- routes -------------------------------------------------------------------

func _clear() -> bool:
	match phase:
		0: # idle
			if _t() >= 0.6: _next("walk east")
		1:
			_hold("move_right", true)
			if _t() >= 1.0:
				_hold("move_right", false)
				_next("aim at zombie")
		2:
			aim_point = zombie.global_position
			_hold("aim", true)
			if _t() >= 0.6: # wind-up done, ready cue visible
				_tap("fire")
				_next("fired; wait for ZOMBIE-DOWN")
		3:
			aim_point = zombie.global_position
			if zombie.state == 1 and _t() >= 1.5: # let the collapse sound play
				_hold("aim", false)
				_next("walk to exit")
		4:
			_steer(exit_marker.global_position)
			if player.art_id() == "CHAR-CELEBRATE":
				_release_moves()
				_next("celebrating; hold for chime + music fade")
		5:
			return _t() >= 3.0
	return false


func _grab() -> bool:
	match phase:
		0:
			if _t() >= 0.3: _next("walk toward the zombie")
		1:
			_steer(zombie.global_position)
			if player.art_id() == "CHAR-HURT":
				_release_moves()
				_next("grabbed; no input")
		2:
			if player.art_id() == "CHAR-RECOVER":
				_next("recover; walk away west")
		3:
			_hold("move_left", true)
			if _t() >= 1.6:
				_hold("move_left", false)
				_next("stop")
		4:
			return _t() >= 1.0
		_: # safety stop
			return true
	return _t() > 12.0


func _mute() -> bool:
	# Muted kill (readable without sound), then wait past the 2.4 s SFX-DOWN so
	# unmuting doesn't reveal a still-playing muted tail, then an audible shot.
	aim_point = zombie.global_position if phase <= 3 else Vector2(160, 100)
	match phase:
		0:
			if _t() >= 1.0:
				_tap("toggle_music")
				_next("music muted")
		1:
			if _t() >= 1.0:
				_tap("toggle_sfx")
				_hold("aim", true)
				_next("sfx muted; aiming at zombie")
		2:
			if _t() >= 0.6:
				_tap("fire")
				_next("muted shot (kills zombie)")
		3:
			if _t() >= 3.0:
				_tap("toggle_music")
				_tap("toggle_sfx")
				_next("both unmuted; aim at north wall")
		4:
			if _t() >= 0.8:
				_tap("fire")
				_next("audible shot into wall")
		5:
			if _t() >= 1.2:
				_hold("aim", false)
				return true
	return false


# --- input helpers --------------------------------------------------------------

func _t() -> float:
	return (frame - phase_start) / FPS


func _next(label: String) -> void:
	phase += 1
	phase_start = frame
	log_lines.append("%6.3f s  frame %4d  phase %d: %s" % [frame / FPS, frame, phase, label])


func _event(action: String, pressed: bool) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _hold(action: String, pressed: bool) -> void:
	if held.get(action, false) == pressed:
		return
	held[action] = pressed
	_event(action, pressed)
	if action == "aim" or action.begins_with("move_"):
		# Polled actions also need the Input state, as a held key would set.
		if pressed:
			Input.action_press(action)
		else:
			Input.action_release(action)


func _tap(action: String) -> void:
	_event(action, true)
	_event(action, false)


func _release_moves() -> void:
	for a in ["move_up", "move_down", "move_left", "move_right"]:
		_hold(a, false)


func _steer(target: Vector2) -> void:
	var d := target - player.global_position
	_hold("move_right", d.x > 8.0)
	_hold("move_left", d.x < -8.0)
	_hold("move_down", d.y > 8.0)
	_hold("move_up", d.y < -8.0)


func _mouse(world: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = root.get_final_transform() * root.get_canvas_transform() * world
	ev.global_position = ev.position
	Input.parse_input_event(ev)
	# A real cursor outside the window would otherwise override the aim.
	Input.warp_mouse(ev.position)


func _write_log() -> void:
	log_lines.append("%6.3f s  frame %4d  end" % [frame / FPS, frame])
	var path := OS.get_environment("ROUTE_LOG")
	if path != "":
		var f := FileAccess.open(path, FileAccess.WRITE)
		f.store_string("\n".join(log_lines) + "\n")
