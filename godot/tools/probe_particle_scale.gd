extends SceneTree
## Diagnostic (written by Claude Code, A6 Phase 3): how big does a
## GPUParticles3D quad draw for a given QuadMesh size, ParticleProcessMaterial
## scale, billboard_mode and billboard_keep_scale? Needs a window:
##
##   godot --path godot --resolution 1280x720 --script res://tools/probe_particle_scale.gd
##
## Orthographic camera, 10 m view height over 720 px = 72 px per metre; one
## motionless, unshaded white particle per case; measures each particle's
## width in pixels along the centre row.

const CASES := [
	# [quad size m, scale_min = scale_max, billboard_mode, billboard_keep_scale]
	[1.0, 1.0, BaseMaterial3D.BILLBOARD_PARTICLES, false],
	[1.0, 0.5, BaseMaterial3D.BILLBOARD_PARTICLES, false],
	[1.0, 0.1, BaseMaterial3D.BILLBOARD_PARTICLES, false],
	[1.0, 0.5, BaseMaterial3D.BILLBOARD_PARTICLES, true],
	[1.0, 0.5, BaseMaterial3D.BILLBOARD_DISABLED, false],
	[1.0, 0.5, BaseMaterial3D.BILLBOARD_ENABLED, false],
	[1.0, 0.5, BaseMaterial3D.BILLBOARD_ENABLED, true],
]


func _initialize() -> void:
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 10.0
	cam.position = Vector3(0, 0, 10)
	root.add_child(cam)
	var x := -6.0
	for c in CASES:
		var p := GPUParticles3D.new()
		p.amount = 1
		p.lifetime = 100.0
		p.explosiveness = 1.0
		var m := ParticleProcessMaterial.new()
		m.gravity = Vector3.ZERO
		m.initial_velocity_min = 0.0
		m.initial_velocity_max = 0.0
		m.scale_min = c[1]
		m.scale_max = c[1]
		p.process_material = m
		var q := QuadMesh.new()
		q.size = Vector2(c[0], c[0])
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = c[2]
		mat.billboard_keep_scale = c[3]
		q.material = mat
		p.draw_pass_1 = q
		p.position = Vector3(x + 0.6, 0, 0)
		x += 1.65
		root.add_child(p)
	_measure.call_deferred()


func _measure() -> void:
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	var h := img.get_height()
	var y := h / 2
	var runs := []
	var inside := false
	var start := 0
	for xx in img.get_width():
		var on := img.get_pixel(xx, y).v > 0.5
		if on and not inside:
			start = xx
		if not on and inside:
			runs.append(xx - start)
		inside = on
	print("Godot %s, %s, %.0f px per metre" % [Engine.get_version_info().string, RenderingServer.get_video_adapter_name(), h / 10.0])
	for i in CASES.size():
		var c: Array = CASES[i]
		var got: int = runs[i] if i < runs.size() else -1
		print("quad %.2f m, scale %.2f, billboard_mode %d, keep_scale %-5s -> drawn %3d px (scaled would be %4.1f, unscaled %4.1f)" % [
				c[0], c[1], c[2], c[3], got, c[0] * c[1] * h / 10.0, c[0] * h / 10.0])
	quit()
