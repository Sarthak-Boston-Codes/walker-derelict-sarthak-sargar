extends SceneTree
## Saves the shader code Godot generates for a StandardMaterial3D with an
## albedo texture, a normal map and a roughness texture, to
## res://shaders/standard_generated.gdshader (unused by the game).
## Written by Claude Code. Needs a window (not --headless):
##
##   godot --path godot --script res://tools/dump_standard_shader.gd
##
## Why the RID scan: Material._get_shader_rid() is bound only as a virtual,
## so GDScript cannot call it ("Nonexistent function"). BaseMaterial3D still
## hands its generated code to the RenderingServer as a shader. Shader RIDs
## are (counter << 32) | slot, so the one created between two shaders made
## here is found by trying the ids in between with shader_get_code().
## Invalid ids print "ERROR: ... is null" and return "", which is expected.

const OUT := "res://shaders/standard_generated.gdshader"


func _initialize() -> void:
	var before := RenderingServer.shader_create()
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://textures/concrete/concrete_floor_worn_001_diff_1k.png")
	m.normal_enabled = true
	m.normal_texture = load("res://textures/concrete/concrete_floor_worn_001_nor_gl_1k.png")
	m.roughness_texture = load("res://textures/concrete/concrete_floor_worn_001_rough_1k.png")
	m.get_rid() # builds the material's shader now
	var after := RenderingServer.shader_create()
	var found: Array[String] = []
	for slot in range(0, (after.get_id() & 0xffffffff) + 1):
		for v in range((before.get_id() >> 32) + 1, after.get_id() >> 32):
			var code := RenderingServer.shader_get_code(rid_from_int64((v << 32) | slot))
			if code.contains("shader_type spatial") and code.contains("texture_albedo") and code.contains("texture_normal"):
				found.append(code)
	print("generated StandardMaterial3D shaders found: %d" % found.size())
	if found.size() != 1:
		quit(1)
		return
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(found[0])
	f.close()
	print("wrote %s (%d characters)" % [OUT, found[0].length()])
	RenderingServer.free_rid(before)
	RenderingServer.free_rid(after)
	quit(0)
