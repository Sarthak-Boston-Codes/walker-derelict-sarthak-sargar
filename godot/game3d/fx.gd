extends RefCounted
## One-shot visual effects. Everything spawns under `Fx.root` (set by
## game.gd) and frees itself. CPU particles so it behaves the same headless.

const MAX_DECALS := 70

static var root: Node3D
static var _decals: Array[Decal] = []
static var _splat: ImageTexture
static var _scorch: ImageTexture
static var _shrink: Curve


static func _ok() -> bool:
	return root != null and root.is_inside_tree()


static func _free_after(node: Node, seconds: float) -> void:
	node.get_tree().create_timer(seconds, false).timeout.connect(node.queue_free)


static func _unshaded(color: Color, energy := 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(color.r * energy, color.g * energy, color.b * energy, color.a)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	m.vertex_color_use_as_albedo = true
	return m


static func _shrink_curve() -> Curve:
	if _shrink == null:
		_shrink = Curve.new()
		_shrink.add_point(Vector2(0, 1))
		_shrink.add_point(Vector2(1, 0))
	return _shrink


static func _burst(pos: Vector3, dir: Vector3, amount: int, mesh_size: float, material: Material,
		speed: Vector2, spread: float, lifetime: float, gravity := Vector3(0, -9.8, 0)) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.emitting = false # it defaults to true and would burst at the origin on add_child
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * mesh_size
	mesh.material = material
	p.mesh = mesh
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = dir if dir.length() > 0.01 else Vector3.UP
	p.spread = spread
	p.initial_velocity_min = speed.x
	p.initial_velocity_max = speed.y
	p.gravity = gravity
	p.scale_amount_min = 0.5
	p.scale_amount_max = 1.2
	p.scale_amount_curve = _shrink_curve()
	p.angular_velocity_min = -360
	p.angular_velocity_max = 360
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.position = root.to_local(pos)
	root.add_child(p)
	p.emitting = true
	_free_after(p, lifetime + 0.2)
	return p


static func flash_light(pos: Vector3, color: Color, energy: float, light_range: float, seconds: float) -> void:
	if not _ok():
		return
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = light_range
	root.add_child(l)
	l.global_position = pos
	var t := l.create_tween()
	t.tween_property(l, "light_energy", 0.0, seconds).set_ease(Tween.EASE_OUT)
	t.tween_callback(l.queue_free)


static func tracer(from: Vector3, to: Vector3) -> void:
	if not _ok() or from.distance_to(to) < 0.1:
		return
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.025, 0.025, from.distance_to(to))
	mi.mesh = mesh
	var m := _unshaded(Color(1.0, 0.85, 0.45, 0.9), 2.5)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mi)
	mi.look_at_from_position((from + to) / 2.0, to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.FORWARD)
	var t := mi.create_tween()
	t.tween_property(m, "albedo_color:a", 0.0, 0.07)
	t.tween_callback(mi.queue_free)


static func sparks(pos: Vector3, normal: Vector3) -> void:
	if not _ok():
		return
	_burst(pos, normal, 12, 0.035, _unshaded(Color(1.0, 0.75, 0.3), 3.0), Vector2(2.5, 6.0), 55.0, 0.35)
	flash_light(pos + normal * 0.2, Color("#FFB347"), 1.5, 2.5, 0.08)


static func blood(pos: Vector3, dir: Vector3, amount := 16) -> void:
	if not _ok():
		return
	_burst(pos, (dir + Vector3.UP * 0.4).normalized(), amount, 0.06, _unshaded(Color(0.35, 0.02, 0.02), 1.0), Vector2(1.5, 4.5), 35.0, 0.55)


static func dust(pos: Vector3, amount := 20) -> void:
	if not _ok():
		return
	_burst(pos + Vector3.UP * 0.2, Vector3.UP, amount, 0.18, _unshaded(Color(0.4, 0.38, 0.35, 0.45)), Vector2(0.5, 1.8), 80.0, 0.9, Vector3(0, -0.6, 0))


static func explosion(pos: Vector3) -> void:
	if not _ok():
		return
	_burst(pos + Vector3.UP * 0.5, Vector3.UP, 40, 0.45, _unshaded(Color(1.0, 0.55, 0.15), 3.5), Vector2(3.0, 9.0), 90.0, 0.5, Vector3(0, 2.0, 0))
	_burst(pos + Vector3.UP * 0.6, Vector3.UP, 30, 0.7, _unshaded(Color(0.12, 0.11, 0.1, 0.7)), Vector2(1.0, 4.0), 70.0, 1.6, Vector3(0, 1.0, 0))
	_burst(pos + Vector3.UP * 0.4, Vector3.UP, 30, 0.06, _unshaded(Color(1.0, 0.8, 0.4), 4.0), Vector2(6.0, 14.0), 75.0, 0.8)
	flash_light(pos + Vector3.UP * 1.2, Color("#FF8A3D"), 14.0, 12.0, 0.6)
	decal(pos, 3.4, true)


static func _splat_tex(scorch: bool) -> ImageTexture:
	if scorch and _scorch:
		return _scorch
	if not scorch and _splat:
		return _splat
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 99 if scorch else 7
	var blobs: Array = []
	blobs.append([Vector2(32, 32), 13.0 if not scorch else 26.0])
	for i in (14 if not scorch else 6):
		var a := rng.randf() * TAU
		var d := rng.randf_range(8.0, 24.0)
		blobs.append([Vector2(32, 32) + Vector2(cos(a), sin(a)) * d, rng.randf_range(1.5, 5.5)])
	for y in 64:
		for x in 64:
			var alpha := 0.0
			for b in blobs:
				var r: float = b[1]
				var dist := Vector2(x, y).distance_to(b[0])
				alpha = maxf(alpha, clampf((r - dist) / 2.0 + 0.5, 0.0, 1.0) * (1.0 if not scorch else clampf(1.0 - dist / r, 0.0, 1.0)))
			var c := Color(0.28, 0.01, 0.01, alpha * 0.92) if not scorch else Color(0.02, 0.02, 0.02, alpha * 0.85)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	var tex := ImageTexture.create_from_image(img)
	if scorch:
		_scorch = tex
	else:
		_splat = tex
	return tex


static func decal(pos: Vector3, size: float, scorch := false) -> void:
	if not _ok():
		return
	var d := Decal.new()
	d.texture_albedo = _splat_tex(scorch)
	d.size = Vector3(size, 1.0, size)
	d.cull_mask = 1
	root.add_child(d)
	d.global_position = Vector3(pos.x, 0.0, pos.z)
	d.rotation.y = randf() * TAU
	_decals.append(d)
	while _decals.size() > MAX_DECALS:
		var old: Decal = _decals.pop_front()
		if is_instance_valid(old):
			old.queue_free()


## Slow drifting dust motes around `follow`. They're lit, not glowing, so
## they only show up where a light (usually the flashlight) hits them.
static func make_dust_field() -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.amount = 260
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(13, 1.2, 10)
	p.direction = Vector3(1, 0.1, 0.3)
	p.spread = 180.0
	p.initial_velocity_min = 0.05
	p.initial_velocity_max = 0.25
	p.gravity = Vector3(0, -0.015, 0)
	p.scale_amount_min = 0.4
	p.scale_amount_max = 1.0
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.035, 0.035)
	var m := StandardMaterial3D.new()
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.9, 0.86, 0.78, 0.55)
	m.roughness = 1.0
	mesh.material = m
	p.mesh = mesh
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return p


static func clear() -> void:
	_decals.clear()
