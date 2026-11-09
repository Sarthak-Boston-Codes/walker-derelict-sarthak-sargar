extends SceneTree
## Saves the shader code Godot generates for a ParticleProcessMaterial to
## res://shaders/particles_generated.gdshader (unused by the game).
## Written by Claude Code (A6 Phase 7), adapted from dump_standard_shader.gd.
## Needs a window (not --headless):
##
##   godot --path godot --script res://tools/dump_particles_shader.gd
##
## The material is the Puff emitter's process material from
## effects/impact_burst.tscn, duplicated with duplicate(true) so it is unique
## (the scene's own resource is never touched). Puff has a velocity range,
## gravity, damping, a scale curve, a colour ramp and an alpha curve, so each
## of those appears in the generated code. The shader is found by RID scan
## (shader_get_code on the ids created between two shaders made here), as in
## dump_standard_shader.gd. Invalid ids print "ERROR: ... is null".

const SCENE := "res://effects/impact_burst.tscn"
const OUT := "res://shaders/particles_generated.gdshader"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var burst: Node = (load(SCENE) as PackedScene).instantiate()
	var src: ParticleProcessMaterial = (burst.get_node("Puff") as GPUParticles3D).process_material
	var before := RenderingServer.shader_create()
	var m := src.duplicate(true) as ParticleProcessMaterial
	print("duplicate is a distinct resource: %s; initial_velocity %s..%s, gravity %s, damping %s..%s" % [m != src,
			m.initial_velocity_min, m.initial_velocity_max, m.gravity, m.damping_min, m.damping_max])
	m.get_rid()
	for i in 3: # shader updates may be queued until the frame flushes them
		await process_frame
	var after := RenderingServer.shader_create()
	var found: Array[String] = []
	for slot in range(0, (after.get_id() & 0xffffffff) + 1):
		for v in range(1, (after.get_id() >> 32) + 1):
			var code := RenderingServer.shader_get_code(rid_from_int64((v << 32) | slot))
			if code.contains("shader_type particles") and code.contains("scale_curve") and code.contains("color_ramp") and not found.has(code):
				found.append(code)
	print("generated particle process shaders with scale_curve and color_ramp found: %d" % found.size())
	burst.free()
	RenderingServer.free_rid(before)
	RenderingServer.free_rid(after)
	if found.size() != 1:
		quit(1)
		return
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(found[0])
	f.close()
	print("wrote %s (%d characters, %d lines)" % [OUT, found[0].length(), found[0].count("\n") + 1])
	quit(0)
