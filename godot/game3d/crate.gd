extends StaticBody3D
## Supply crate. Two shots splinter it into debris and drop an ammo box.

const ModelTable := preload("res://game3d/model_table.gd")
const Fx := preload("res://game3d/fx.gd")
const Sfx := preload("res://game3d/sfx.gd")
const Phys := preload("res://game3d/phys.gd")
const Pickup := preload("res://game3d/pickup.gd")

const SIZE := 0.5

var hp := 2.0
var _model: Node3D


func _ready() -> void:
	add_to_group("crates")
	collision_layer = Phys.PROP
	collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * SIZE
	cs.shape = shape
	cs.position.y = SIZE / 2.0
	add_child(cs)
	_model = ModelTable.make("supply_crate")
	add_child(_model)


func hit(damage: float, point: Vector3, dir: Vector3, normal: Vector3) -> void:
	if hp <= 0.0:
		return
	hp -= damage
	Fx.sparks(point, normal)
	Sfx.play_at("SFX-HURT", point, 1.8, -8.0)
	var t := create_tween()
	t.tween_property(_model, "scale", Vector3(1.08, 0.92, 1.08), 0.05)
	t.tween_property(_model, "scale", Vector3.ONE, 0.08)
	if hp <= 0.0:
		_break(dir)


func _break(dir: Vector3) -> void:
	var material: Material = null
	var meshes := ModelTable.meshes_of(_model)
	if not meshes.is_empty():
		material = meshes[0].get_active_material(0)
	for i in 7:
		var chunk := RigidBody3D.new()
		chunk.collision_layer = 0
		chunk.collision_mask = Phys.WORLD
		var s := randf_range(0.1, 0.22)
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(s, s * 0.5, s * 1.4)
		cs.shape = shape
		chunk.add_child(cs)
		var mi := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = shape.size
		mi.mesh = mesh
		mi.material_override = material
		chunk.add_child(mi)
		get_parent().add_child(chunk)
		chunk.global_position = global_position + Vector3(randf_range(-0.2, 0.2), randf_range(0.15, 0.45), randf_range(-0.2, 0.2))
		chunk.apply_central_impulse((dir * 0.6 + Vector3(randf_range(-1, 1), randf_range(1.0, 2.0), randf_range(-1, 1))) * 0.25)
		chunk.angular_velocity = Vector3(randf(), randf(), randf()) * 8.0
		var tw := chunk.create_tween()
		tw.tween_interval(3.0)
		tw.tween_property(chunk, "scale", Vector3.ONE * 0.01, 0.6)
		tw.tween_callback(chunk.queue_free)
	Fx.dust(global_position, 14)
	Sfx.play_at("SFX-DOWN", global_position, 1.6, -2.0)
	var ammo := Pickup.new()
	ammo.kind = "ammo"
	get_parent().add_child(ammo)
	ammo.global_position = global_position
	queue_free()
