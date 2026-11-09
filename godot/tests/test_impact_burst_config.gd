extends SceneTree
## Configuration test for Effect A, the impact burst (CHANGE-BRIEF.md,
## Effect A settings table). Written by Claude Code.
## Loads godot/effects/impact_burst.tscn and reads every setting in the
## brief's table back from the loaded resources. The expected values are
## the brief's (with its dated revisions); one PASS/FAIL line per setting;
## exit 1 on any failure.
##
##   bash scripts/run-test.sh test_impact_burst_config.gd 60

const SCENE := "res://effects/impact_burst.tscn"
const EPS := 1e-4
const AABB_ALL := AABB(Vector3(-2, -1, -2), Vector3(4, 3, 4))

## The brief's table, one dictionary per emitter. `scale_curve` and
## `alpha_curve` are [value at 0, value at 1]; `colors` are the ramp's
## first and last colour (rgb); `blend` is BaseMaterial3D.BlendMode.
const EXPECT := {
	"Flash": {
		"amount": 2, "one_shot": true, "explosiveness": 1.0, "lifetime": 0.08,
		"lifetime_randomness": 0.0,
		"direction": Vector3(0, 1, 0), "spread": 180.0,
		"initial_velocity_min": 0.0, "initial_velocity_max": 0.0,
		"gravity": Vector3(0, 0, 0), "damping_min": 0.0, "damping_max": 0.0,
		"scale_min": 0.8, "scale_max": 1.2, "scale_curve": [1.0, 0.3],
		"colors": [Color(1.0, 0.95, 0.8), Color(1.0, 0.95, 0.8)],
		"alpha_curve": [1.0, 0.0], "quad": 0.3, "blend": BaseMaterial3D.BLEND_MODE_ADD,
		"keep_scale": false,
	},
	"Sparks": {
		"amount": 14, "one_shot": true, "explosiveness": 1.0, "lifetime": 0.45,
		"lifetime_randomness": 0.3,
		"direction": Vector3(0, 1, 0), "spread": 55.0,
		"initial_velocity_min": 3.0, "initial_velocity_max": 6.0,
		"gravity": Vector3(0, -9.8, 0), "damping_min": 0.5, "damping_max": 1.5,
		"scale_min": 0.03, "scale_max": 0.06, "scale_curve": null,
		"colors": [Color(1.0, 0.7, 0.2), Color(1.0, 0.25, 0.06)],
		"alpha_curve": [1.0, 0.0], "quad": 0.1, "blend": BaseMaterial3D.BLEND_MODE_ADD,
		"keep_scale": false,
	},
	"Puff": {
		"amount": 8, "one_shot": true, "explosiveness": 0.9, "lifetime": 0.6,
		"lifetime_randomness": 0.0,
		"direction": Vector3(0, 1, 0), "spread": 70.0,
		"initial_velocity_min": 0.6, "initial_velocity_max": 1.4,
		"gravity": Vector3(0, 0.4, 0), "damping_min": 2.5, "damping_max": 4.0,
		"scale_min": 0.15, "scale_max": 0.3, "scale_curve": [0.5, 1.6],
		"colors": [Color(0.23, 0.06, 0.04), Color(0.23, 0.06, 0.04)],
		"alpha_curve": [0.6, 0.0], "quad": 0.5, "blend": BaseMaterial3D.BLEND_MODE_MIX,
		# Tuning A-r1 (CHANGE-BRIEF revision 2026-11-08): billboard particles
		# ignore the process scale unless this is true.
		"keep_scale": true,
	},
}

var _failures := 0


func check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func _initialize() -> void:
	print("\n== test_impact_burst_config ==")
	var packed: PackedScene = load(SCENE)
	check(packed != null, "%s loads" % SCENE)
	if packed == null:
		quit(1)
		return
	var root := packed.instantiate()
	check(root.get_class() == "Node3D", "root is a Node3D (got %s)" % root.get_class())
	var names := []
	for c in root.get_children():
		names.append(String(c.name))
	check(names == ["Flash", "Sparks", "Puff"], "root has exactly three emitters Flash, Sparks, Puff (got %s)" % [names])
	for n in EXPECT:
		var node := root.get_node_or_null(n)
		if node == null:
			check(false, "%s exists" % n)
			continue
		_emitter(n, node, EXPECT[n])
	root.free()
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(1 if _failures > 0 else 0)


func _near(a: float, b: float) -> bool:
	return absf(a - b) <= EPS


func _num(label: String, got: float, want: float) -> void:
	check(_near(got, want), "%s = %s (got %s)" % [label, want, got])


func _vec(label: String, got: Vector3, want: Vector3) -> void:
	check(got.is_equal_approx(want), "%s = %s (got %s)" % [label, want, got])


func _rgb(a: Color, b: Color) -> bool:
	return _near(a.r, b.r) and _near(a.g, b.g) and _near(a.b, b.b)


func _emitter(n: String, node: Node, e: Dictionary) -> void:
	check(node.get_class() == "GPUParticles3D", "%s is a GPUParticles3D (got %s)" % [n, node.get_class()])
	var p := node as GPUParticles3D
	if p == null:
		return
	# Emission (node).
	check(p.amount == e.amount, "%s amount = %d (got %d)" % [n, e.amount, p.amount])
	check(p.one_shot == e.one_shot, "%s one_shot = %s (got %s)" % [n, e.one_shot, p.one_shot])
	_num("%s explosiveness" % n, p.explosiveness, e.explosiveness)
	_num("%s lifetime" % n, p.lifetime, e.lifetime)
	check(p.local_coords == false, "%s local_coords = false (got %s)" % [n, p.local_coords])
	_num("%s preprocess" % n, p.preprocess, 0.0)
	check(p.visibility_aabb.is_equal_approx(AABB_ALL), "%s visibility_aabb = %s (got %s)" % [n, AABB_ALL, p.visibility_aabb])
	check(p.emitting == false, "%s is not emitting in the scene file (nothing at load)" % n)
	# Process.
	var m := p.process_material as ParticleProcessMaterial
	check(m != null and m.get_class() == "ParticleProcessMaterial", "%s process_material is a ParticleProcessMaterial (got %s)" % [n, p.process_material.get_class() if p.process_material else "null"])
	if m == null:
		return
	_num("%s lifetime_randomness" % n, m.lifetime_randomness, e.lifetime_randomness)
	check(m.emission_shape == ParticleProcessMaterial.EMISSION_SHAPE_POINT, "%s emission_shape = point (got %d)" % [n, m.emission_shape])
	_vec("%s direction" % n, m.direction, e.direction)
	_num("%s spread" % n, m.spread, e.spread)
	_num("%s initial_velocity_min" % n, m.initial_velocity_min, e.initial_velocity_min)
	_num("%s initial_velocity_max" % n, m.initial_velocity_max, e.initial_velocity_max)
	_vec("%s gravity" % n, m.gravity, e.gravity)
	_num("%s damping_min" % n, m.damping_min, e.damping_min)
	_num("%s damping_max" % n, m.damping_max, e.damping_max)
	_num("%s scale_min" % n, m.scale_min, e.scale_min)
	_num("%s scale_max" % n, m.scale_max, e.scale_max)
	if e.scale_curve == null:
		check(m.scale_curve == null, "%s scale curve: none (got %s)" % [n, m.scale_curve])
	else:
		_curve("%s scale curve" % n, m.scale_curve, e.scale_curve)
	_curve("%s alpha curve" % n, m.alpha_curve, e.alpha_curve)
	var ramp := m.color_ramp as GradientTexture1D
	if ramp == null or ramp.gradient == null:
		check(false, "%s colour ramp is a GradientTexture1D with a Gradient" % n)
	else:
		var g := ramp.gradient
		var c0 := g.sample(0.0)
		var c1 := g.sample(1.0)
		check(_rgb(c0, e.colors[0]) and _rgb(c1, e.colors[1]),
				"%s colour ramp %s -> %s (got %s -> %s)" % [n, _c(e.colors[0]), _c(e.colors[1]), _c(c0), _c(c1)])
		check(_near(c0.a, 1.0) and _near(c1.a, 1.0), "%s colour ramp alpha is 1 at both ends (the fade is the alpha curve)" % n)
	# Draw.
	var mesh := p.draw_pass_1 as QuadMesh
	check(mesh != null, "%s draw_pass_1 is a QuadMesh (got %s)" % [n, p.draw_pass_1.get_class() if p.draw_pass_1 else "null"])
	if mesh == null:
		return
	check(mesh.size.is_equal_approx(Vector2(e.quad, e.quad)), "%s QuadMesh size = %s m (got %s)" % [n, e.quad, mesh.size])
	var mat := mesh.material as StandardMaterial3D
	check(mat != null, "%s draw material is a StandardMaterial3D (got %s)" % [n, mesh.material.get_class() if mesh.material else "null"])
	if mat == null:
		return
	check(mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "%s draw: unshaded (got %d)" % [n, mat.shading_mode])
	check(mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "%s draw: transparency alpha (got %d)" % [n, mat.transparency])
	check(mat.blend_mode == e.blend, "%s draw: blend_mode %s (got %d)" % [n, "add" if e.blend == BaseMaterial3D.BLEND_MODE_ADD else "mix", mat.blend_mode])
	check(mat.billboard_mode == BaseMaterial3D.BILLBOARD_PARTICLES, "%s draw: billboard_mode particles (got %d)" % [n, mat.billboard_mode])
	check(mat.vertex_color_use_as_albedo, "%s draw: vertex_color_use_as_albedo true" % n)
	check(mat.billboard_keep_scale == e.keep_scale, "%s draw: billboard_keep_scale %s (got %s)" % [n, e.keep_scale, mat.billboard_keep_scale])
	var tex := mat.albedo_texture as GradientTexture2D
	var in_scene := tex != null and (tex.resource_path.is_empty() or tex.resource_path.contains("::"))
	check(tex != null and tex.fill == GradientTexture2D.FILL_RADIAL and in_scene,
			"%s draw: texture is a radial GradientTexture2D written in the scene (got %s)" % [n, mat.albedo_texture])


func _curve(label: String, tex: Texture2D, want: Array) -> void:
	var ct := tex as CurveTexture
	if ct == null or ct.curve == null:
		check(false, "%s is a CurveTexture with a Curve (got %s)" % [label, tex])
		return
	var a := ct.curve.sample(0.0)
	var b := ct.curve.sample(1.0)
	check(_near(a, want[0]) and _near(b, want[1]), "%s %s -> %s (got %s -> %s)" % [label, want[0], want[1], snappedf(a, 0.0001), snappedf(b, 0.0001)])


func _c(c: Color) -> String:
	return "(%.2f,%.2f,%.2f)" % [c.r, c.g, c.b]
