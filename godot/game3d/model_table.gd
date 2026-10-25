extends RefCounted
## The 3D model swap table for the top-down game.
##
## Every 3D thing the game spawns asks for it here by ID. An empty "path"
## means "build the generated placeholder". To drop in a real model, put its
## res:// path in that one line (and fix "scale"/"yaw" if the model is not
## 1 unit = 1 metre, facing -Z). Nothing else needs to change.
##
## "yaw" is degrees around Y applied to the model so it faces -Z (Godot
## forward). Models are expected to have their origin at their feet/base.
## Optional "tint" multiplies every surface's albedo colour, so two IDs can
## share one mesh and still read as different (shambler vs runner).
## Optional "eyes" lists points in the model's own space (before yaw/scale)
## where small glowing eyes are added, so zombies read in the dark.

const Placeholders := preload("res://game3d/placeholder_models.gd")
const EYE_COLOR := Color("#FF3B1F")
const ZOMBIE_EYES := [Vector3(0.705, 1.635, 0.025), Vector3(0.705, 1.635, 0.135)]

const MODELS := {
	"player": {"path": "res://assets/3d/characters/player.glb", "scale": 1.0, "yaw": 180.0},
	"zombie_shambler": {"path": "res://assets/3d/characters/zombie.glb", "scale": 1.0, "yaw": 90.0, "eyes": ZOMBIE_EYES},
	"zombie_runner": {"path": "res://assets/3d/characters/zombie.glb", "scale": 0.9, "yaw": 90.0, "tint": Color(1.0, 0.5, 0.42), "eyes": ZOMBIE_EYES},
	"supply_crate": {"path": "res://assets/3d/supply_crate.glb", "scale": 1.0, "yaw": 0.0},
	"rusted_barrel": {"path": "res://assets/3d/rusted_barrel.glb", "scale": 1.0, "yaw": 0.0},
	"explosive_barrel": {"path": "", "scale": 1.0, "yaw": 0.0},
	"medkit": {"path": "res://assets/3d/medkit.glb", "scale": 1.0, "yaw": 0.0},
	"ammo_box": {"path": "", "scale": 1.0, "yaw": 0.0},
	"keycard": {"path": "", "scale": 1.0, "yaw": 0.0},
}

static var _scenes := {}
## Tinted copies of materials, shared by every instance of the same ID.
static var _tinted := {}


## Returns a fresh "Model" pivot node holding the model for `id`.
static func make(id: String) -> Node3D:
	assert(MODELS.has(id), "Unknown model ID: %s" % id)
	var spec: Dictionary = MODELS[id]
	var model: Node3D
	if spec.path != "":
		if not _scenes.has(id):
			_scenes[id] = load(spec.path)
		model = (_scenes[id] as PackedScene).instantiate()
	else:
		model = Placeholders.build(id)
	if spec.has("tint"):
		_apply_tint(id, model, spec.tint)
	if spec.has("eyes") and spec.path != "":
		var mid := Vector3.ZERO
		for p in spec.eyes:
			model.add_child(eye(p))
			mid += p / spec.eyes.size()
		model.add_child(eye_glow(mid))
	model.scale = Vector3.ONE * float(spec.scale)
	model.rotation.y = deg_to_rad(float(spec.yaw))
	var pivot := Node3D.new()
	pivot.name = "Model"
	pivot.add_child(model)
	return pivot


## A small glowing eye (unshaded-bright, so it shows outside any light).
## Named "Eye" so the owner can find and dim it.
static func eye(pos: Vector3, radius := 0.042) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "Eye"
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 8
	mesh.rings = 4
	mi.mesh = mesh
	mi.material_override = Placeholders.glow(EYE_COLOR, 2.2)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = pos
	return mi


## Faint red light just in front of the eyes: tints the face and floor so a
## zombie still reads in the dark when it faces away from the camera.
static func eye_glow(pos: Vector3) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = "EyeGlow"
	l.light_color = EYE_COLOR
	l.light_energy = 0.35
	l.omni_range = 0.75
	l.light_volumetric_fog_energy = 0.0
	l.position = pos + Vector3(0.12, 0.0, 0.0)
	return l


static func _apply_tint(id: String, model: Node, tint: Color) -> void:
	for mi in meshes_of(model):
		for i in mi.mesh.get_surface_count():
			var base := mi.get_active_material(i) as BaseMaterial3D
			if base == null:
				continue
			var key := "%s/%d" % [id, base.get_instance_id()]
			if not _tinted.has(key):
				var m := base.duplicate() as BaseMaterial3D
				m.albedo_color *= tint
				_tinted[key] = m
			mi.set_surface_override_material(i, _tinted[key])


## All mesh instances under a model, for hit flashes and tinting.
static func meshes_of(model: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for n in model.find_children("*", "MeshInstance3D", true, false):
		out.append(n)
	if model is MeshInstance3D:
		out.append(model)
	return out


## Plays the first animation whose name contains one of `names`, if the
## model has an AnimationPlayer (real models). Placeholders have none.
static func play_anim(model: Node, names: Array) -> bool:
	var players := model.find_children("*", "AnimationPlayer", true, false)
	if players.is_empty():
		return false
	var ap: AnimationPlayer = players[0]
	for want in names:
		for anim in ap.get_animation_list():
			if anim.to_lower().contains(want):
				if ap.current_animation != anim:
					ap.play(anim, 0.2)
				return true
	return false
