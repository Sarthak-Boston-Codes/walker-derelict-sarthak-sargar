extends Node
## Animates the level's practical lights each frame:
## - lamps tagged "flicker": steady, with sudden stutters and blackouts
## - lamps tagged "dead": mostly off, with brief sputters
## - lights in group "emergency_lights": slow red pulse, staggered phases
## Each light's bulb mesh (meta "bulb") dims with it.

var _lights: Array[Dictionary] = []
var _t := 0.0


func _ready() -> void:
	for light in get_parent().find_children("*", "OmniLight3D", false, false):
		var mode := ""
		if light.has_meta("flicker"):
			mode = "flicker"
		elif light.has_meta("dead"):
			mode = "dead"
		elif light.is_in_group("emergency_lights"):
			mode = "emergency"
		if mode == "":
			continue
		var bulb: MeshInstance3D = light.get_meta("bulb")
		var mat := bulb.material_override as StandardMaterial3D
		_lights.append({
			"light": light, "bulb": mat, "mode": mode,
			"base": light.light_energy, "glow": mat.emission_energy_multiplier,
			"phase": randf() * TAU, "next": randf_range(0.5, 4.0), "level": 1.0,
		})


func _process(delta: float) -> void:
	_t += delta
	for l in _lights:
		var k := 1.0
		match l.mode:
			"emergency":
				k = 0.25 + 0.75 * pow(0.5 + 0.5 * sin(_t * 2.6 + l.phase), 2.0)
			"flicker", "dead":
				l.next -= delta
				if l.next <= 0.0:
					_reroll(l)
				k = l.level
		(l.light as OmniLight3D).light_energy = l.base * k
		(l.bulb as StandardMaterial3D).emission_energy_multiplier = l.glow * maxf(k, 0.04)


func _reroll(l: Dictionary) -> void:
	if l.mode == "dead":
		# Off almost always; sputters on for a frame or two.
		var on: bool = l.level < 0.5 and randf() < 0.35
		l.level = randf_range(0.5, 1.0) if on else 0.0
		l.next = randf_range(0.03, 0.09) if on else randf_range(0.2, 2.5)
	else:
		var r := randf()
		if r < 0.6:
			l.level = 1.0
			l.next = randf_range(0.8, 4.0)
		elif r < 0.9:
			l.level = randf_range(0.0, 0.5)
			l.next = randf_range(0.03, 0.12)
		else:
			l.level = 0.0
			l.next = randf_range(0.3, 1.2)
