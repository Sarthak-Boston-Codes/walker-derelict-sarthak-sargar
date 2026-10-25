extends Node3D
## Builds the derelict factory at runtime from primitives: four connected
## rooms, their machinery, lights, props, zombie spawn points, the
## environment, and the navmesh zombies path on.
##
## Map (north is up on screen, camera looks north):
##
##   +----------------+--------------------+
##   |  CONTROL ROOM  |    BOILER ROOM     |
##   |  (extraction)  ] locked   (keycard) |
##   +----------------+-------[ ]----------+
##   |  LOADING BAY   [    ASSEMBLY HALL   |
##   |  (start)       [                    |
##   +----------------+--------------------+
##
## Everything solid sits on Phys.WORLD under the NavigationRegion3D so the
## navmesh bakes around it; props live on Phys.PROP and are left out.

signal nav_rebaked

const Phys := preload("res://game3d/phys.gd")
const ModelTable := preload("res://game3d/model_table.gd")
const P := preload("res://game3d/placeholder_models.gd")
const FloorShader := preload("res://game3d/shaders/concrete_floor.gdshader")
const Crate := preload("res://game3d/crate.gd")
const Barrel := preload("res://game3d/barrel.gd")
const Pickup := preload("res://game3d/pickup.gd")
const LockedDoor := preload("res://game3d/locked_door.gd")
const Extraction := preload("res://game3d/extraction.gd")
const LightAnimator := preload("res://game3d/light_animator.gd")

const WALL_H := 2.4
const WALL_T := 0.6

## Room rectangles on the XZ plane: Rect2(x, z, width, depth).
const ROOMS := {
	"Loading Bay": Rect2(-10, 0, 20, 14),
	"Assembly Hall": Rect2(10, 0, 22, 14),
	"Boiler Room": Rect2(10, -18, 22, 18),
	"Control Room": Rect2(-10, -18, 20, 18),
}

var nav_region: NavigationRegion3D
var player_start := Vector3(-5, 0, 9.5)
## {pos: Vector3, room: String}
var spawn_points: Array[Dictionary] = []
## Rooms zombies may not spawn in yet.
var locked_rooms := {"Control Room": true}
## Filled by _place_props(); game.gd hooks these up.
var locked_door: Node3D
var extraction: Node3D
var keycard: Node3D

var _mats := {}


func _ready() -> void:
	_make_materials()
	_build_environment()
	nav_region = NavigationRegion3D.new()
	nav_region.name = "Nav"
	nav_region.navigation_mesh = _nav_settings()
	nav_region.bake_finished.connect(func() -> void: nav_rebaked.emit())
	add_child(nav_region)
	_build_shell()
	_build_loading_bay()
	_build_assembly_hall()
	_build_boiler_room()
	_build_control_room()
	_place_props()
	_place_spawns()
	add_child(LightAnimator.new())
	nav_region.bake_navigation_mesh(false)


func room_at(pos: Vector3) -> String:
	for room in ROOMS:
		if (ROOMS[room] as Rect2).grow(0.01).has_point(Vector2(pos.x, pos.z)):
			return room
	return ""


func unlock_room(room: String) -> void:
	locked_rooms.erase(room)


## Call after a door opens so zombies can path through it.
func rebake_nav() -> void:
	nav_region.bake_navigation_mesh(true)


# --- materials & environment -------------------------------------------------

func _noise_tex(freq: float, seed_value: int, size := 256) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_value
	n.frequency = freq
	n.fractal_octaves = 4
	var t := NoiseTexture2D.new()
	t.width = size
	t.height = size
	t.seamless = true
	t.generate_mipmaps = true
	t.noise = n
	return t


func _tex_mat(color: Color, tex: Texture2D, scale: float, roughness := 0.9, metallic := 0.0) -> StandardMaterial3D:
	var m := P.mat(color, roughness, metallic)
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	return m


func _stripe_tex() -> ImageTexture:
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var band := int((x + y) / 16.0) % 2 == 0
			img.set_pixel(x, y, Color("#D9A42B") if band else Color("#1C1C1C"))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


func _make_materials() -> void:
	var grit := _noise_tex(0.03, 7)
	var floor_mat := ShaderMaterial.new()
	floor_mat.shader = FloorShader
	floor_mat.set_shader_parameter("grit", grit)
	floor_mat.set_shader_parameter("stains", _noise_tex(0.012, 21))
	_mats.floor = floor_mat
	_mats.concrete = _tex_mat(Color("#7A7C76"), grit, 0.35)
	_mats.paint = _tex_mat(Color("#3F5A52"), grit, 0.5, 0.8)
	_mats.cap = P.mat(Color("#202322"), 1.0)
	_mats.rust = _tex_mat(Color("#8B4A2B"), _noise_tex(0.05, 3), 0.6, 0.75, 0.45)
	_mats.steel = _tex_mat(Color("#5A6066"), grit, 0.6, 0.5, 0.7)
	_mats.container = _tex_mat(Color("#2F5A5E"), _noise_tex(0.08, 11), 0.4, 0.7, 0.4)
	_mats.container2 = _tex_mat(Color("#7A3524"), _noise_tex(0.08, 12), 0.4, 0.7, 0.4)
	_mats.belt = P.mat(Color("#141515"), 0.6)
	_mats.dark = P.mat(Color("#1C1C1C"), 0.7, 0.3)
	var stripes := P.mat(Color.WHITE, 0.7)
	stripes.albedo_texture = _stripe_tex()
	stripes.uv1_triplanar = true
	stripes.uv1_scale = Vector3.ONE * 1.2
	_mats.stripes = stripes
	_mats.screen = P.glow(Color("#3BE07A"), 1.6)
	_mats.screen_red = P.glow(Color("#FF3B2B"), 1.8)
	_mats.lamp = P.glow(Color("#FFD9A0"), 4.0)
	_mats.emergency = P.glow(Color("#FF2A1A"), 5.0)


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.008, 0.01)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#3A4250")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.35
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.0
	env.ssao_enabled = true
	env.ssao_intensity = 2.0
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.012
	env.volumetric_fog_albedo = Color(0.75, 0.75, 0.8)
	env.volumetric_fog_anisotropy = 0.55
	env.volumetric_fog_length = 48.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.85
	env.adjustment_contrast = 1.08
	var we := WorldEnvironment.new()
	we.name = "Environment"
	we.environment = env
	add_child(we)


func _nav_settings() -> NavigationMesh:
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = Phys.WORLD
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.agent_radius = 0.5
	nm.agent_height = 1.75
	nm.agent_max_climb = 0.25
	return nm


# --- building blocks ---------------------------------------------------------

## A solid axis-aligned box standing on the floor (or at `y0`), on WORLD.
func _block(center_xz: Vector2, size: Vector3, material: Material, y0 := 0.0, collide := true, yaw_deg := 0.0) -> Node3D:
	var root: Node3D
	if collide:
		var body := StaticBody3D.new()
		body.collision_layer = Phys.WORLD
		body.collision_mask = 0
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		root = body
	else:
		root = Node3D.new()
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = material
	root.add_child(mi)
	root.position = Vector3(center_xz.x, y0 + size.y / 2.0, center_xz.y)
	root.rotation_degrees.y = yaw_deg
	nav_region.add_child(root)
	return root


## A solid vertical cylinder (boilers, pillars, tanks), on WORLD.
func _cylinder(center_xz: Vector2, radius: float, height: float, material: Material, collide := true) -> Node3D:
	var root: Node3D
	if collide:
		var body := StaticBody3D.new()
		body.collision_layer = Phys.WORLD
		body.collision_mask = 0
		var cs := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		cs.shape = shape
		body.add_child(cs)
		root = body
	else:
		root = Node3D.new()
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 24
	mi.mesh = mesh
	mi.material_override = material
	root.add_child(mi)
	root.position = Vector3(center_xz.x, height / 2.0, center_xz.y)
	nav_region.add_child(root)
	return root


## Pure decoration: mesh only, no collision.
func _deco(mesh: Mesh, material: Material, pos: Vector3, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	mi.position = pos
	mi.rotation_degrees = rot_deg
	add_child(mi)
	return mi


## A wall along X (constant z) or along Z (constant x), with door gaps given
## as [from, to] ranges along the wall. Painted lower band, concrete above,
## dark cap so wall tops read clearly from the top-down camera.
func _wall(a: Vector2, b: Vector2, gaps: Array = []) -> void:
	var along_x := is_equal_approx(a.y, b.y)
	var lo := minf(a.x, b.x) if along_x else minf(a.y, b.y)
	var hi := maxf(a.x, b.x) if along_x else maxf(a.y, b.y)
	var spans: Array = [[lo, hi]]
	for gap in gaps:
		var next: Array = []
		for s in spans:
			if gap[1] <= s[0] or gap[0] >= s[1]:
				next.append(s)
				continue
			if gap[0] > s[0]:
				next.append([s[0], gap[0]])
			if gap[1] < s[1]:
				next.append([gap[1], s[1]])
		spans = next
	for s in spans:
		var length: float = s[1] - s[0]
		if length < 0.05:
			continue
		var mid: float = (s[0] + s[1]) / 2.0
		var c := Vector2(mid, a.y) if along_x else Vector2(a.x, mid)
		var size := Vector3(length, WALL_H, WALL_T) if along_x else Vector3(WALL_T, WALL_H, length)
		var wall := _block(c, size, _mats.concrete)
		# Visual layers on the same body: painted band and dark cap.
		var band := MeshInstance3D.new()
		var band_mesh := BoxMesh.new()
		band_mesh.size = size + Vector3(0.02, 0, 0.02)
		band_mesh.size.y = 1.1
		band.mesh = band_mesh
		band.material_override = _mats.paint
		band.position.y = -WALL_H / 2.0 + 0.55
		wall.add_child(band)
		var cap := MeshInstance3D.new()
		var cap_mesh := BoxMesh.new()
		cap_mesh.size = size + Vector3(0.04, 0, 0.04)
		cap_mesh.size.y = 0.08
		cap.mesh = cap_mesh
		cap.material_override = _mats.cap
		cap.position.y = WALL_H / 2.0
		wall.add_child(cap)
	for gap in gaps:
		_door_frame(along_x, a.y if along_x else a.x, gap[0], gap[1])


func _door_frame(along_x: bool, line: float, from: float, to: float) -> void:
	var mid := (from + to) / 2.0
	var width := to - from
	for edge in [from, to]:
		var c := Vector2(edge, line) if along_x else Vector2(line, edge)
		var size := Vector3(0.25, WALL_H, WALL_T + 0.3) if along_x else Vector3(WALL_T + 0.3, WALL_H, 0.25)
		_block(c, size, _mats.stripes)
	var lintel := Vector3(width, 0.5, WALL_T) if along_x else Vector3(WALL_T, 0.5, width)
	var lc := Vector2(mid, line) if along_x else Vector2(line, mid)
	_block(lc, lintel, _mats.concrete, WALL_H - 0.5, false)
	var stripe := BoxMesh.new()
	stripe.size = Vector3(width, 0.01, 1.2) if along_x else Vector3(1.2, 0.01, width)
	_deco(stripe, _mats.stripes, Vector3(lc.x, 0.005, lc.y))


func _lamp(pos_xz: Vector2, energy := 1.6, light_range := 8.0, color := Color("#FFD9A0"), shadow := false) -> OmniLight3D:
	var bulb := SphereMesh.new()
	bulb.radius = 0.12
	bulb.height = 0.24
	var bulb_mi := _deco(bulb, _mats.lamp.duplicate(), Vector3(pos_xz.x, WALL_H + 0.02, pos_xz.y))
	bulb_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var light := OmniLight3D.new()
	light.position = Vector3(pos_xz.x, WALL_H - 0.1, pos_xz.y)
	light.light_color = color
	light.light_energy = energy * 2.0
	light.omni_range = light_range
	light.omni_attenuation = 0.9
	light.shadow_enabled = shadow
	light.set_meta("bulb", bulb_mi)
	add_child(light)
	return light


func _emergency(pos: Vector3) -> OmniLight3D:
	var box := BoxMesh.new()
	box.size = Vector3(0.3, 0.16, 0.3)
	var bulb := _deco(box, _mats.emergency.duplicate(), pos)
	bulb.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var light := OmniLight3D.new()
	light.position = pos + Vector3(0, -0.3, 0)
	light.light_color = Color("#FF2A1A")
	light.light_energy = 2.0
	light.omni_range = 6.0
	light.omni_attenuation = 1.2
	light.set_meta("bulb", bulb)
	light.add_to_group("emergency_lights")
	add_child(light)
	return light


func _pipe(from: Vector3, to: Vector3, radius := 0.12, material: Material = null) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = from.distance_to(to)
	mesh.radial_segments = 12
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material if material else _mats.rust
	add_child(mi)
	mi.look_at_from_position((from + to) / 2.0, to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.FORWARD)
	mi.rotate_object_local(Vector3.RIGHT, PI / 2.0)


# --- rooms -------------------------------------------------------------------

func _build_shell() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = Phys.WORLD
	floor_body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(44, 1, 34)
	cs.shape = shape
	floor_body.add_child(cs)
	var mi := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(42.6, 32.6)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	mi.mesh = plane
	mi.material_override = _mats.floor
	mi.position.y = 0.5
	floor_body.add_child(mi)
	floor_body.position = Vector3(11, -0.5, -2)
	nav_region.add_child(floor_body)
	var h := WALL_T / 2.0
	# Outer walls (south wall has the loading-dock shutters as decoration).
	_wall(Vector2(-10 - h, 14), Vector2(32 + h, 14))
	_wall(Vector2(-10 - h, -18), Vector2(32 + h, -18))
	_wall(Vector2(-10, -18), Vector2(-10, 14))
	_wall(Vector2(32, -18), Vector2(32, 14))
	# Inner walls.
	_wall(Vector2(10, 0), Vector2(10, 14), [[5.5, 8.5]]) # bay <-> hall
	_wall(Vector2(10 + h, 0), Vector2(32, 0), [[19.5, 22.5]]) # hall <-> boiler
	_wall(Vector2(-10, 0), Vector2(10 + h, 0)) # bay | control: solid
	_wall(Vector2(10, -18), Vector2(10, 0), [[-10.5, -7.5]]) # boiler <-> control (locked)


func _build_loading_bay() -> void:
	# Two shipping containers and a forklift-ish machine block.
	var c1 := _block(Vector2(-4.5, 3.2), Vector3(6, 2.3, 2.4), _mats.container)
	_ribs(c1, Vector3(6, 2.3, 2.4))
	var c2 := _block(Vector2(-8.4, 9.0), Vector3(2.4, 2.3, 5.0), _mats.container2)
	_ribs(c2, Vector3(2.4, 2.3, 5.0))
	_block(Vector2(4.0, 3.0), Vector3(1.6, 1.4, 2.4), _mats.steel) # forklift body
	_block(Vector2(4.0, 1.5), Vector3(1.4, 0.12, 1.0), _mats.dark, 0.2, false) # forks
	# Loading dock shutters on the south wall.
	for x in [-4.0, 3.0]:
		var shutter := BoxMesh.new()
		shutter.size = Vector3(3.6, 2.2, 0.1)
		_deco(shutter, _mats.steel, Vector3(x, 1.1, 13.62))
		var stripe := BoxMesh.new()
		stripe.size = Vector3(3.6, 0.01, 0.8)
		_deco(stripe, _mats.stripes, Vector3(x, 0.005, 13.1))
	# Pallets.
	for p in [Vector2(1.5, 11.5), Vector2(7.5, 11.8), Vector2(-1.5, 1.2)]:
		_block(p, Vector3(1.2, 0.15, 1.0), _mats.rust, 0.0, false)
	_lamp(Vector2(-3, 7), 1.6, 9.0, Color("#FFD9A0"), true)
	_lamp(Vector2(5, 9), 1.2, 7.0).set_meta("flicker", true)
	_emergency(Vector3(9.4, 2.1, 4.6))


## Corrugation ribs on a container so it doesn't read as a flat box.
func _ribs(container: Node3D, size: Vector3) -> void:
	var long_x := size.x > size.z
	var length := size.x if long_x else size.z
	var count := int(length / 0.5)
	for i in count:
		var t := -length / 2.0 + 0.25 + i * 0.5
		var rib := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.08, size.y - 0.2, size.z + 0.06) if long_x else Vector3(size.x + 0.06, size.y - 0.2, 0.08)
		rib.mesh = m
		rib.material_override = container.get_child(1).material_override
		rib.position = Vector3(t, 0, 0) if long_x else Vector3(0, 0, t)
		container.add_child(rib)


func _build_assembly_hall() -> void:
	# Two conveyor lines leave a middle lane; go round their ends to reach
	# the boiler room door.
	for z in [3.6, 10.4]:
		_block(Vector2(21, z), Vector3(13, 0.85, 1.4), _mats.steel)
		_block(Vector2(21, z), Vector3(13, 0.06, 1.1), _mats.belt, 0.85, false)
		for x in [15.5, 21.0, 26.5]:
			_block(Vector2(x, z), Vector3(1.2, 1.9, 1.7), _mats.rust, 0.0, false) # press frames over the belt
	_block(Vector2(30.4, 7.0), Vector3(2.0, 2.2, 3.0), _mats.steel) # generator
	_block(Vector2(30.4, 7.0), Vector3(1.4, 0.4, 2.2), _mats.dark, 2.2, false)
	_cylinder(Vector2(13.0, 12.6), 0.45, WALL_H, _mats.concrete) # pillars
	_cylinder(Vector2(29.0, 12.6), 0.45, WALL_H, _mats.concrete)
	_lamp(Vector2(15, 7), 1.4, 8.0)
	_lamp(Vector2(27, 7), 1.3, 8.0).set_meta("flicker", true)
	_lamp(Vector2(21, 1.8), 1.0, 6.0).set_meta("dead", true)
	_emergency(Vector3(21, 2.1, 0.6))
	_pipe(Vector3(10.4, 2.1, 13.2), Vector3(31.6, 2.1, 13.2), 0.14)
	_pipe(Vector3(10.4, 1.85, 13.5), Vector3(31.6, 1.85, 13.5), 0.09, _mats.steel)


func _build_boiler_room() -> void:
	for c in [Vector2(15.5, -5.5), Vector2(26.5, -5.5), Vector2(21.0, -13.5)]:
		_cylinder(c, 1.4, 2.6, _mats.rust)
		var top := CylinderMesh.new()
		top.top_radius = 0.7
		top.bottom_radius = 1.3
		top.height = 0.5
		_deco(top, _mats.steel, Vector3(c.x, 2.85, c.y))
		var gauge := SphereMesh.new()
		gauge.radius = 0.12
		gauge.height = 0.24
		_deco(gauge, _mats.screen_red, Vector3(c.x, 1.5, c.y + 1.42))
	# Feed pipes run from each boiler to the nearest wall, never across a
	# walkway (from the top-down camera a pipe overhead hides the player).
	_pipe(Vector3(15.5, 2.2, -4.0), Vector3(15.5, 2.2, -0.3), 0.18)
	_pipe(Vector3(26.5, 2.2, -4.0), Vector3(26.5, 2.2, -0.3), 0.18)
	_pipe(Vector3(21.0, 2.2, -15.0), Vector3(21.0, 2.2, -17.7), 0.18)
	_pipe(Vector3(10.4, 2.0, -17.5), Vector3(31.6, 2.0, -17.5), 0.16, _mats.steel)
	# Keycard desk in the far north-east corner.
	_block(Vector2(29.6, -16.6), Vector3(2.2, 0.85, 1.0), _mats.steel)
	var monitor := BoxMesh.new()
	monitor.size = Vector3(0.6, 0.4, 0.05)
	_deco(monitor, _mats.screen, Vector3(29.0, 1.1, -16.95))
	_block(Vector2(13.0, -16.5), Vector3(3.0, 1.2, 1.4), _mats.steel) # tool bench
	_lamp(Vector2(15.5, -10), 1.2, 7.0).set_meta("flicker", true)
	_lamp(Vector2(27, -11), 1.0, 7.0)
	_emergency(Vector3(31.4, 2.1, -9))
	_emergency(Vector3(10.6, 2.1, -6.6))
	_emergency(Vector3(21, 2.1, -17.4))


func _build_control_room() -> void:
	# Console bank along the north wall.
	for x in [-6.0, -2.0, 2.0]:
		_block(Vector2(x, -16.9), Vector3(3.4, 1.0, 1.2), _mats.steel)
		var screen := BoxMesh.new()
		screen.size = Vector3(2.8, 0.7, 0.06)
		_deco(screen, _mats.screen, Vector3(x, 1.5, -17.3), Vector3(-15, 0, 0))
	_block(Vector2(7.0, -3.0), Vector3(2.0, 2.4, 1.0), _mats.steel) # server racks
	_block(Vector2(4.6, -3.0), Vector3(2.0, 2.4, 1.0), _mats.steel)
	for x in [4.6, 7.0]:
		for y in [0.6, 1.2, 1.8]:
			var led := BoxMesh.new()
			led.size = Vector3(1.4, 0.04, 0.02)
			_deco(led, _mats.screen if y != 1.2 else _mats.screen_red, Vector3(x, y, -2.48))
	_lamp(Vector2(-2, -9), 1.3, 9.0)
	locked_door = LockedDoor.new()
	locked_door.name = "LockedDoor"
	nav_region.add_child(locked_door)
	locked_door.position = Vector3(10, 0, -9)
	extraction = Extraction.new()
	extraction.name = "Extraction"
	add_child(extraction)
	extraction.position = Vector3(-5, 0, -11)
	_lamp(Vector2(-7, -4), 1.0, 6.0).set_meta("flicker", true)
	_emergency(Vector3(9.4, 2.1, -11.4))


# --- props & spawns ----------------------------------------------------------

func _place_props() -> void:
	for p in [Vector3(-0.5, 0, 1.0), Vector3(-0.5, 0, 1.6), Vector3(8.5, 0, 12.8),
			Vector3(14.0, 0, 1.0), Vector3(29.5, 0, 12.8), Vector3(12.0, 0, -1.2),
			Vector3(30.5, 0, -2.0), Vector3(-8.8, 0, -1.2), Vector3(24.0, 0, -16.8)]:
		_prop("supply_crate", p)
	for p in [Vector3(7.5, 0, 1.8), Vector3(8.2, 0, 2.4), Vector3(7.3, 0, 2.6),
			Vector3(17.0, 0, 12.8), Vector3(30.8, 0, 3.2), Vector3(31.0, 0, 10.8),
			Vector3(11.0, 0, -4.0), Vector3(18.5, 0, -1.0), Vector3(30.8, 0, -13.0),
			Vector3(-9.0, 0, -9.0), Vector3(-8.6, 0, -15.6)]:
		_prop("rusted_barrel", p)
	for p in [Vector3(1.0, 0, 6.5), Vector3(28.6, 0, 7.0), Vector3(21.0, 0, -9.8), Vector3(5.0, 0, -9.0)]:
		_prop("explosive_barrel", p)
	for p in [Vector3(-1.2, 0, 12.6), Vector3(25.5, 0, 1.0), Vector3(12.0, 0, -13.0), Vector3(-8.5, 0, -4.0)]:
		_prop("medkit", p)
	keycard = _prop("keycard", Vector3(29.8, 0.85, -16.6))


## Places one interactive prop.
func _prop(id: String, pos: Vector3) -> Node3D:
	var node: Node3D
	match id:
		"supply_crate":
			node = Crate.new()
		"rusted_barrel", "explosive_barrel":
			node = Barrel.new()
			node.explosive = id == "explosive_barrel"
		"medkit", "keycard":
			node = Pickup.new()
			node.kind = id
			node.bob = id == "keycard"
	add_child(node)
	node.global_position = pos
	if id != "keycard":
		node.rotation.y = randf() * TAU
	return node


func _place_spawns() -> void:
	var points := {
		"Loading Bay": [Vector2(-6, 13), Vector2(3, 13), Vector2(8.5, 0.8)],
		"Assembly Hall": [Vector2(31, 13), Vector2(31, 1), Vector2(13, 1), Vector2(21, 7)],
		"Boiler Room": [Vector2(31, -1.5), Vector2(11.5, -17), Vector2(31, -9.5), Vector2(21, -1.5)],
		"Control Room": [Vector2(-9, -1), Vector2(8, -16.5), Vector2(-9, -17)],
	}
	for room in points:
		for p in points[room]:
			spawn_points.append({"pos": Vector3(p.x, 0, p.y), "room": room})
