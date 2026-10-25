extends RefCounted
## Builds stand-in 3D models from primitives for every ModelTable ID whose
## path is empty. All face -Z with their origin at floor level.
##
## Humanoids get hip/shoulder pivots named "LegL", "LegR", "ArmL", "ArmR" so
## the procedural walk cycle in actor_anim.gd has something to swing.

const GEAR := Color("#4A4F4D")
const SKIN := Color("#C9A27E")
const ACCENT := Color("#F2C14E")
const RUST := Color("#8B4A2B")
const DARK := Color("#1C1C1C")


static func build(id: String) -> Node3D:
	match id:
		"player":
			return _player()
		"zombie_shambler":
			return _zombie(Color("#6F7F45"), Color("#4B4A3A"), 1.0, false)
		"zombie_runner":
			return _zombie(Color("#8E5A48"), Color("#3A2E2A"), 0.92, true)
		"explosive_barrel":
			return _explosive_barrel()
		"ammo_box":
			return _ammo_box()
		"keycard":
			return _keycard()
	push_warning("No placeholder for %s; using a box" % id)
	var root := Node3D.new()
	_part(root, _box(Vector3(0.5, 0.5, 0.5)), mat(Color.MAGENTA), Vector3(0, 0.25, 0))
	return root


static func mat(color: Color, roughness := 0.8, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m


static func glow(color: Color, energy := 2.0) -> StandardMaterial3D:
	var m := mat(color)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


static func _part(parent: Node3D, mesh: Mesh, material: Material, pos: Vector3, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	parent.add_child(mi)
	return mi


static func _pivot(parent: Node3D, node_name: String, pos: Vector3) -> Node3D:
	var p := Node3D.new()
	p.name = node_name
	p.position = pos
	parent.add_child(p)
	return p


static func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m


static func _capsule(radius: float, height: float) -> CapsuleMesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = 12
	m.rings = 4
	return m


static func _cyl(radius: float, height: float, segments := 16) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = height
	m.radial_segments = segments
	return m


static func _sphere(radius: float) -> SphereMesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = 12
	m.rings = 6
	return m


static func _player() -> Node3D:
	var root := Node3D.new()
	var gear := mat(GEAR)
	var skin := mat(SKIN)
	var dark := mat(DARK, 0.5, 0.4)
	for side in [-1, 1]:
		var leg := _pivot(root, "LegL" if side < 0 else "LegR", Vector3(0.12 * side, 0.85, 0))
		_part(leg, _capsule(0.1, 0.85), dark, Vector3(0, -0.42, 0))
	var torso := _pivot(root, "Torso", Vector3(0, 0.85, 0))
	_part(torso, _capsule(0.22, 0.75), gear, Vector3(0, 0.33, 0))
	_part(torso, _box(Vector3(0.36, 0.42, 0.16)), mat(RUST), Vector3(0, 0.38, 0.2)) # backpack
	_part(torso, _sphere(0.15), skin, Vector3(0, 0.86, 0))
	_part(torso, _box(Vector3(0.3, 0.08, 0.3)), dark, Vector3(0, 0.98, 0.02)) # cap
	# Both arms reach forward to hold the weapon.
	for side in [-1, 1]:
		var arm := _pivot(torso, "ArmL" if side < 0 else "ArmR", Vector3(0.26 * side, 0.6, 0))
		_part(arm, _capsule(0.07, 0.5), gear, Vector3(-0.06 * side, -0.05, -0.2), Vector3(-70, 0, 0))
	var gun := _pivot(torso, "Gun", Vector3(0.05, 0.5, -0.45))
	_part(gun, _box(Vector3(0.08, 0.12, 0.55)), dark, Vector3.ZERO)
	_part(gun, _cyl(0.035, 0.12), glow(ACCENT, 3.0), Vector3(-0.07, 0.04, -0.2), Vector3(90, 0, 0)) # flashlight
	return root


static func _zombie(flesh_color: Color, cloth_color: Color, height_scale: float, lean: bool) -> Node3D:
	var root := Node3D.new()
	var flesh := mat(flesh_color, 0.9)
	var cloth := mat(cloth_color, 0.95)
	for side in [-1, 1]:
		var leg := _pivot(root, "LegL" if side < 0 else "LegR", Vector3(0.13 * side, 0.85 * height_scale, 0))
		_part(leg, _capsule(0.11, 0.85 * height_scale), cloth, Vector3(0, -0.42 * height_scale, 0))
	var torso := _pivot(root, "Torso", Vector3(0, 0.85 * height_scale, 0))
	torso.rotation_degrees.x = -25.0 if lean else -8.0
	_part(torso, _capsule(0.24, 0.75), cloth, Vector3(0, 0.33, 0))
	var head := _part(torso, _sphere(0.16), flesh, Vector3(0.03, 0.83, -0.05))
	head.rotation_degrees.z = 14.0
	for side in [-1, 1]:
		_part(head, _sphere(0.03), glow(Color("#FF3B1F"), 6.0), Vector3(0.06 * side, 0.03, -0.14)).name = "Eye"
	# Arms reach out towards the player, the classic silhouette.
	for side in [-1, 1]:
		var arm := _pivot(torso, "ArmL" if side < 0 else "ArmR", Vector3(0.28 * side, 0.6, 0))
		_part(arm, _capsule(0.075, 0.6), flesh, Vector3(0, 0, -0.28), Vector3(-90, 0, 0))
	return root


static func _explosive_barrel() -> Node3D:
	var root := Node3D.new()
	var red := mat(Color("#9E1B12"), 0.55, 0.3)
	_part(root, _cyl(0.3, 0.9, 20), red, Vector3(0, 0.45, 0))
	for y in [0.2, 0.7]:
		_part(root, _cyl(0.31, 0.04, 20), mat(DARK, 0.6, 0.6), Vector3(0, y, 0))
	_part(root, _cyl(0.305, 0.14, 20), glow(Color("#F2C14E"), 1.2), Vector3(0, 0.45, 0))
	_part(root, _cyl(0.06, 0.05), mat(DARK, 0.4, 0.8), Vector3(0.12, 0.92, 0)) # cap
	return root


static func _ammo_box() -> Node3D:
	var root := Node3D.new()
	_part(root, _box(Vector3(0.34, 0.18, 0.22)), mat(Color("#4E5A2E"), 0.6, 0.3), Vector3(0, 0.09, 0))
	_part(root, _box(Vector3(0.36, 0.04, 0.24)), glow(ACCENT, 1.5), Vector3(0, 0.19, 0))
	return root


static func _keycard() -> Node3D:
	var root := Node3D.new()
	_part(root, _box(Vector3(0.24, 0.015, 0.36)), glow(Color("#2BD9FF"), 2.5), Vector3(0, 0.02, 0))
	_part(root, _box(Vector3(0.08, 0.02, 0.06)), mat(Color("#D9C25A"), 0.3, 0.9), Vector3(0.05, 0.03, -0.1))
	return root
