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

const Placeholders := preload("res://game3d/placeholder_models.gd")

const MODELS := {
	"player": {"path": "", "scale": 1.0, "yaw": 0.0},
	"zombie_shambler": {"path": "", "scale": 1.0, "yaw": 0.0},
	"zombie_runner": {"path": "", "scale": 1.0, "yaw": 0.0},
	"supply_crate": {"path": "res://assets/3d/supply_crate.glb", "scale": 1.0, "yaw": 0.0},
	"rusted_barrel": {"path": "res://assets/3d/rusted_barrel.glb", "scale": 1.0, "yaw": 0.0},
	"explosive_barrel": {"path": "", "scale": 1.0, "yaw": 0.0},
	"medkit": {"path": "res://assets/3d/medkit.glb", "scale": 1.0, "yaw": 0.0},
	"ammo_box": {"path": "", "scale": 1.0, "yaw": 0.0},
	"keycard": {"path": "", "scale": 1.0, "yaw": 0.0},
}

static var _scenes := {}


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
	model.scale = Vector3.ONE * float(spec.scale)
	model.rotation.y = deg_to_rad(float(spec.yaw))
	var pivot := Node3D.new()
	pivot.name = "Model"
	pivot.add_child(model)
	return pivot


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
static func play_anim(model: Node, names: Array[String]) -> bool:
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
