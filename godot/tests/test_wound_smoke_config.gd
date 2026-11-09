extends SceneTree
## Configuration test for Effect B, the wound smoke (CHANGE-BRIEF.md,
## Effect B settings table). Written by Claude Code.
## Loads godot/effects/wound_smoke.tscn and reads every setting in the
## brief's table back from the loaded resources, including the turbulence
## settings; one PASS/FAIL line per setting; exit 1 on any failure.
##
##   bash scripts/run-test.sh test_wound_smoke_config.gd 60

const SCENE := "res://effects/wound_smoke.tscn"
const EPS := 1e-4

## The brief's table (with its dated revisions).
const E := {
	"amount": 40, "one_shot": false, "explosiveness": 0.0, "lifetime": 1.8, "preprocess": 0.0,
	"emission_shape": ParticleProcessMaterial.EMISSION_SHAPE_SPHERE, "emission_sphere_radius": 0.15,
	"direction": Vector3(0, 1, 0), "spread": 70.0, # tuning B-r1 (CHANGE-BRIEF revision 2026-11-08)
	"initial_velocity_min": 0.4, "initial_velocity_max": 0.8,
	"gravity": Vector3(0, 0.3, 0), "damping_min": 0.3, "damping_max": 0.6,
	"turbulence_enabled": true, "turbulence_noise_strength": 0.6,
	"scale_min": 0.2, "scale_max": 0.35, "scale_curve": [0.6, 1.8],
	"color": Color(0.18, 0.18, 0.20), "alpha_curve": [0.5, 0.0],
	"quad": 0.5, "blend": BaseMaterial3D.BLEND_MODE_MIX, "keep_scale": false,
	"local_coords": false, "aabb": AABB(Vector3(-3, -1, -3), Vector3(6, 5, 6)),
}

var _failures := 0


func check(ok: bool, what: String) -> void:
	print("%s %s" % ["PASS" if ok else "FAIL", what])
	if not ok:
		_failures += 1


func _near(a: float, b: float) -> bool:
	return absf(a - b) <= EPS


func _num(label: String, got: float, want: float) -> void:
	check(_near(got, want), "%s = %s (got %s)" % [label, want, got])


func _initialize() -> void:
	print("\n== test_wound_smoke_config ==")
	var packed: PackedScene = load(SCENE)
	check(packed != null, "%s loads" % SCENE)
	if packed == null:
		quit(1)
		return
	var root := packed.instantiate()
	check(root.get_class() == "GPUParticles3D" and root.get_child_count() == 0, "one GPUParticles3D, no children (got %s with %d children)" % [root.get_class(), root.get_child_count()])
	var p := root as GPUParticles3D
	if p:
		_check(p)
	root.free()
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	quit(1 if _failures > 0 else 0)


func _check(p: GPUParticles3D) -> void:
	# Emission.
	check(p.amount == E.amount, "amount = %d (got %d)" % [E.amount, p.amount])
	_num("amount_ratio in the scene file (driven at run time)", p.amount_ratio, 1.0)
	check(p.one_shot == E.one_shot, "one_shot = false (got %s)" % p.one_shot)
	_num("explosiveness", p.explosiveness, E.explosiveness)
	_num("lifetime", p.lifetime, E.lifetime)
	_num("preprocess", p.preprocess, E.preprocess)
	check(p.emitting == false, "not emitting in the scene file (nothing at load, full health)")
	check(p.local_coords == E.local_coords, "local_coords = false (got %s)" % p.local_coords)
	check(p.visibility_aabb.is_equal_approx(E.aabb), "visibility_aabb = %s (got %s)" % [E.aabb, p.visibility_aabb])
	# Process.
	var m := p.process_material as ParticleProcessMaterial
	check(m != null and m.get_class() == "ParticleProcessMaterial", "process_material is a ParticleProcessMaterial")
	if m == null:
		return
	check(m.emission_shape == E.emission_shape, "emission_shape = sphere (got %d)" % m.emission_shape)
	_num("emission_sphere_radius", m.emission_sphere_radius, E.emission_sphere_radius)
	check(m.direction.is_equal_approx(E.direction), "direction = %s (got %s)" % [E.direction, m.direction])
	_num("spread", m.spread, E.spread)
	_num("initial_velocity_min", m.initial_velocity_min, E.initial_velocity_min)
	_num("initial_velocity_max", m.initial_velocity_max, E.initial_velocity_max)
	check(m.gravity.is_equal_approx(E.gravity), "gravity = %s (got %s)" % [E.gravity, m.gravity])
	_num("damping_min", m.damping_min, E.damping_min)
	_num("damping_max", m.damping_max, E.damping_max)
	check(m.turbulence_enabled == E.turbulence_enabled, "turbulence_enabled = true (got %s)" % m.turbulence_enabled)
	_num("turbulence_noise_strength", m.turbulence_noise_strength, E.turbulence_noise_strength)
	_num("scale_min", m.scale_min, E.scale_min)
	_num("scale_max", m.scale_max, E.scale_max)
	_curve("scale curve", m.scale_curve, E.scale_curve)
	_curve("alpha curve", m.alpha_curve, E.alpha_curve)
	var ramp := m.color_ramp as GradientTexture1D
	if ramp == null or ramp.gradient == null:
		check(false, "colour ramp is a GradientTexture1D with a Gradient")
	else:
		var c0 := ramp.gradient.sample(0.0)
		var c1 := ramp.gradient.sample(1.0)
		var ok := true
		for c in [c0, c1]:
			ok = ok and _near(c.r, E.color.r) and _near(c.g, E.color.g) and _near(c.b, E.color.b) and _near(c.a, 1.0)
		check(ok, "colour ramp (0.18,0.18,0.20) at both ends, alpha 1 (got %s -> %s)" % [c0, c1])
	# Draw.
	var mesh := p.draw_pass_1 as QuadMesh
	check(mesh != null and mesh.size.is_equal_approx(Vector2(E.quad, E.quad)), "draw_pass_1 is a QuadMesh %s m" % E.quad)
	if mesh == null:
		return
	var mat := mesh.material as StandardMaterial3D
	check(mat != null, "draw material is a StandardMaterial3D")
	if mat == null:
		return
	check(mat.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "draw: unshaded (got %d)" % mat.shading_mode)
	check(mat.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "draw: transparency alpha (got %d)" % mat.transparency)
	check(mat.blend_mode == E.blend, "draw: blend_mode mix (got %d)" % mat.blend_mode)
	check(mat.billboard_mode == BaseMaterial3D.BILLBOARD_PARTICLES, "draw: billboard_mode particles (got %d)" % mat.billboard_mode)
	check(mat.billboard_keep_scale == E.keep_scale, "draw: billboard_keep_scale %s (got %s)" % [E.keep_scale, mat.billboard_keep_scale])
	check(mat.vertex_color_use_as_albedo, "draw: vertex_color_use_as_albedo true")
	var tex := mat.albedo_texture as GradientTexture2D
	var in_scene := tex != null and (tex.resource_path.is_empty() or tex.resource_path.contains("::"))
	check(tex != null and tex.fill == GradientTexture2D.FILL_RADIAL and in_scene, "draw: texture is a radial GradientTexture2D written in the scene")


func _curve(label: String, tex: Texture2D, want: Array) -> void:
	var ct := tex as CurveTexture
	if ct == null or ct.curve == null:
		check(false, "%s is a CurveTexture with a Curve" % label)
		return
	var a := ct.curve.sample(0.0)
	var b := ct.curve.sample(1.0)
	check(_near(a, want[0]) and _near(b, want[1]), "%s %s -> %s (got %s -> %s)" % [label, want[0], want[1], snappedf(a, 0.0001), snappedf(b, 0.0001)])
