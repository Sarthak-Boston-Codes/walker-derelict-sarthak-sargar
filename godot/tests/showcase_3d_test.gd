extends Node
## CHANGE-BRIEF Assignment 3 failure cases #1-#3 for the 3D showcase scene:
## each imported asset must be upright (rotation 0,0,0), unscaled (1,1,1),
## sit on the floor plane (no gap, no sinking), match its brief size and
## stay inside its triangle budget.
##
##   godot --headless --path godot res://tests/showcase_3d_test.tscn
##
## Run without --headless and pass `-- --shot=<path.png>` to also save a
## screenshot through the showcase camera.
##
## Exit code = number of failures (0 = pass).

const SHOWCASE := preload("res://scenes/showcase_3d.tscn")
const TOLERANCE := 0.001 # metres
const ASSETS := {
	# Brief sizes are Blender X x Y x Z (Z-up); Godot is Y-up, so Godot
	# size = (Blender X, Blender Z, Blender Y).
	"SupplyCrate": {"size": Vector3(0.5, 0.5, 0.5), "budget": 100},
	"RustedBarrel": {"size": Vector3(0.6, 0.9, 0.6), "budget": 200},
	"Medkit": {"size": Vector3(0.3, 0.15, 0.2), "budget": 150},
}

var _failures := 0


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	print("\n== showcase_3d_test ==")
	var showcase: Node3D = SHOWCASE.instantiate()
	add_child(showcase)
	var floor_y: float = (showcase.get_node("Floor") as Node3D).global_position.y
	print("%-13s %-10s %-17s %-9s %-20s %-20s %-9s %s" % ["ASSET", "ROT", "SCALE", "BASE-Y", "SIZE", "EXPECTED", "TRIS", "RESULT"])
	for asset_name in ASSETS:
		_check(showcase.get_node(asset_name), ASSETS[asset_name], floor_y)
	await _maybe_screenshot()
	print("\n%s: %d failure(s)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	# --headless still prints a leak warning at exit: that's MUS-LOOP from the
	# Sound autoload (see audio_director.gd _exit_tree), not this scene.
	showcase.queue_free()
	await get_tree().process_frame
	get_tree().quit(_failures)


func _check(root: Node3D, spec: Dictionary, floor_y: float) -> void:
	var meshes := root.find_children("*", "MeshInstance3D", true, false)
	var ok := meshes.size() > 0
	var rot := root.rotation_degrees
	var scl := root.scale
	var aabb := AABB()
	var tris := 0
	for i in meshes.size():
		var mi: MeshInstance3D = meshes[i]
		# Failure cases #1/#2 also apply to the imported mesh node itself.
		ok = ok and mi.rotation_degrees.is_zero_approx() and mi.scale.is_equal_approx(Vector3.ONE)
		var box: AABB = mi.global_transform * mi.get_aabb()
		aabb = box if i == 0 else aabb.merge(box)
		tris += _triangles(mi.mesh)
	ok = ok and rot.is_zero_approx() and scl.is_equal_approx(Vector3.ONE)
	ok = ok and absf(aabb.position.y - floor_y) <= TOLERANCE
	ok = ok and _within(aabb.size, spec.size)
	ok = ok and tris <= spec.budget
	if not ok:
		_failures += 1
	print("%-13s %-10s %-17s %-9.4f %-20s %-20s %-9s %s" % [root.name, _v(rot, 0), _v(scl, 2), aabb.position.y,
			_v(aabb.size, 3), _v(spec.size, 3), "%d/%d" % [tris, spec.budget], "ok" if ok else "FAIL"])


func _within(a: Vector3, b: Vector3) -> bool:
	return absf(a.x - b.x) <= TOLERANCE and absf(a.y - b.y) <= TOLERANCE and absf(a.z - b.z) <= TOLERANCE


func _triangles(mesh: Mesh) -> int:
	var count := 0
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		count += (indices.size() if indices.size() > 0 else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return count


func _v(v: Vector3, decimals: int) -> String:
	var f := "%." + str(decimals) + "f"
	return ("(" + f + "," + f + "," + f + ")") % [v.x, v.y, v.z]


func _maybe_screenshot() -> void:
	var shot := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shot="):
			shot = arg.trim_prefix("--shot=")
	if shot.is_empty() or DisplayServer.get_name() == "headless":
		return
	for i in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var err := get_viewport().get_texture().get_image().save_png(shot)
	print("screenshot -> %s (%s)" % [shot, error_string(err)])
