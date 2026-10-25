extends RigidBody3D
## Physics barrel. Rusted ones get shoved by bullets, the player and zombies
## and topple over. Red explosive ones also take 2 shots and then blow up:
## blast damage with line-of-sight, knockback on every rigid body nearby,
## and chain reactions into other explosive barrels.

const ModelTable := preload("res://game3d/model_table.gd")
const Fx := preload("res://game3d/fx.gd")
const Sfx := preload("res://game3d/sfx.gd")
const Phys := preload("res://game3d/phys.gd")

const RADIUS := 0.3
const HEIGHT := 0.9
const BLAST_RADIUS := 5.0
const BLAST_DAMAGE_PLAYER := 55.0 # at the centre, falls off to ~10 at the edge
const BLAST_DAMAGE_ZOMBIE := 10.0
const BULLET_IMPULSE := 9.0

var explosive := false
var hp := 2.0

var _model: Node3D
var _exploded := false
var _hazard_light: OmniLight3D


func _ready() -> void:
	add_to_group("barrels")
	collision_layer = Phys.PROP
	collision_mask = Phys.WORLD | Phys.PROP | Phys.PLAYER | Phys.ZOMBIE
	mass = 25.0 if explosive else 14.0
	linear_damp = 0.4
	angular_damp = 1.0
	var pm := PhysicsMaterial.new()
	pm.friction = 0.9
	pm.bounce = 0.1
	physics_material_override = pm
	continuous_cd = true
	var cs := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = RADIUS
	shape.height = HEIGHT
	cs.shape = shape
	cs.position.y = HEIGHT / 2.0
	add_child(cs)
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, HEIGHT * 0.45, 0)
	_model = ModelTable.make("explosive_barrel" if explosive else "rusted_barrel")
	add_child(_model)
	if explosive:
		add_to_group("explosive_barrels")
		_hazard_light = OmniLight3D.new()
		_hazard_light.light_color = Color("#FF5A2A")
		_hazard_light.light_energy = 0.5
		_hazard_light.omni_range = 1.8
		_hazard_light.position.y = 1.0
		add_child(_hazard_light)


func _process(_delta: float) -> void:
	if _hazard_light and hp < 2.0:
		# Damaged: the hazard light stutters like it's about to go.
		_hazard_light.light_energy = 0.4 + randf() * 2.0


func hit(damage: float, point: Vector3, dir: Vector3, normal: Vector3) -> void:
	if _exploded:
		return
	apply_impulse(dir * BULLET_IMPULSE, point - global_position)
	Fx.sparks(point, normal)
	Sfx.play("SFX-SHOT", 2.2, -10.0) # metallic ping
	if explosive:
		hp -= damage
		if hp <= 0.0:
			explode()


func explode() -> void:
	if _exploded:
		return
	_exploded = true
	var center := global_position + Vector3.UP * 0.5
	Fx.explosion(global_position)
	Sfx.play("SFX-DOWN", 0.45, 6.0)
	Sfx.play("SFX-SHOT", 0.35, 4.0)
	var space := get_world_3d().direct_space_state
	var tree := get_tree()
	var cam := get_viewport().get_camera_3d()
	if cam and cam.has_method("add_trauma") and is_instance_valid(cam.target):
		var d: float = cam.target.global_position.distance_to(center)
		cam.add_trauma(clampf(1.2 - d / 14.0, 0.15, 0.9))
	for node in tree.get_nodes_in_group("zombies") + tree.get_nodes_in_group("player") + tree.get_nodes_in_group("barrels") + tree.get_nodes_in_group("crates"):
		if node == self or not is_instance_valid(node):
			continue
		var target: Vector3 = node.global_position + Vector3.UP * 0.6
		var dist := center.distance_to(target)
		if dist > BLAST_RADIUS or not _clear_line(space, center, target):
			continue
		var falloff := 1.0 - dist / BLAST_RADIUS
		var away := (target - center).normalized()
		if node.is_in_group("player"):
			node.take_damage(lerpf(10.0, BLAST_DAMAGE_PLAYER, falloff), center)
		elif node.is_in_group("zombies"):
			node.hit(BLAST_DAMAGE_ZOMBIE, target, away, -away)
		elif node.is_in_group("crates"):
			node.hit(5.0, target, away, -away)
		elif node is RigidBody3D:
			node.apply_central_impulse((away + Vector3.UP * 0.6) * 260.0 * falloff)
			if node.explosive and not node._exploded:
				# Chain reaction, slightly delayed so it reads as a sequence.
				tree.create_timer(0.18, false).timeout.connect(func() -> void:
					if is_instance_valid(node):
						node.explode())
	queue_free()


func _clear_line(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from, to, Phys.WORLD)
	return space.intersect_ray(q).is_empty()
