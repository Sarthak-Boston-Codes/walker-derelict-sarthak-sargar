extends RefCounted
## Procedural walk cycle for placeholder humanoids: swings the "LegL",
## "LegR", "ArmL", "ArmR" pivots built by placeholder_models.gd and bobs
## "Torso". Real models without those nodes are left alone (they use their
## own AnimationPlayer via ModelTable.play_anim).

const PARTS := ["LegL", "LegR", "ArmL", "ArmR", "Torso"]


## phase: radians, advanced by distance walked. amount: 0..1 stride.
static func walk(model: Node3D, phase: float, amount: float, arm_swing := true) -> void:
	var parts := _parts(model)
	if parts.is_empty():
		return
	var swing := sin(phase) * 0.7 * amount
	_rot(parts, "LegL", swing)
	_rot(parts, "LegR", -swing)
	if arm_swing:
		_rot(parts, "ArmL", -swing * 0.5)
		_rot(parts, "ArmR", swing * 0.5)
	if parts.has("Torso"):
		var torso: Node3D = parts.Torso
		torso.position.y = float(torso.get_meta("base_y")) + absf(cos(phase)) * 0.05 * amount


static func _parts(model: Node3D) -> Dictionary:
	if model.has_meta("anim_parts"):
		return model.get_meta("anim_parts")
	var parts := {}
	for part in PARTS:
		var n := model.find_child(part, true, false) as Node3D
		if n:
			parts[part] = n
			n.set_meta("base_y", n.position.y)
	model.set_meta("anim_parts", parts)
	return parts


static func _rot(parts: Dictionary, part: String, x: float) -> void:
	if parts.has(part):
		(parts[part] as Node3D).rotation.x = x
