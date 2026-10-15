extends SceneTree
## 4K captures of the A3 showcase scene for the film.
##
##   godot --path <project> --fixed-fps 30 -s showcase_capture.gd
##   env MODE   = scene | orbit   (scene: the scene's own Camera3D; orbit: a capture-only camera)
##       FRAMES = frame count (30 per second)
##       OUT    = output folder; frames saved as f00000.png ...
##
## The laptop screen is 1920x1080, which caps the window, so the scene renders
## into an off-screen 3840x2160 SubViewport and every frame is saved from it.
## Nothing in the scene is edited: orbit mode adds its own camera and makes it
## current; scene mode uses the saved Camera3D unchanged.

const SIZE := Vector2i(3840, 2160)
const ORBIT_CENTER := Vector3(0, 0.3, 0)
const ORBIT_RADIUS := 2.8

var mode := OS.get_environment("MODE")
var frames := int(OS.get_environment("FRAMES"))
var out := OS.get_environment("OUT")
var view: SubViewport
var cam: Camera3D
var frame := -1


func _initialize() -> void:
	assert(mode in ["scene", "orbit"] and frames > 0 and out != "", "set MODE, FRAMES, OUT")
	DirAccess.make_dir_recursive_absolute(out)
	view = SubViewport.new()
	view.size = SIZE
	view.msaa_3d = Viewport.MSAA_4X
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	view.add_child(load("res://scenes/showcase_3d.tscn").instantiate())
	if mode == "orbit":
		cam = Camera3D.new()
		cam.name = "CaptureCamera"
		view.add_child(cam)
		cam.current = true
	_run.call_deferred()


func _run() -> void:
	for i in 10: # settle shadows before frame 0
		await process_frame
	for f in frames:
		if cam:
			_place(float(f) / max(frames - 1, 1))
		await RenderingServer.frame_post_draw
		view.get_texture().get_image().save_png(out.path_join("f%05d.png" % f))
	print("saved %d frames %dx%d mode=%s camera=%s" % [frames, SIZE.x, SIZE.y, mode,
			"CaptureCamera (capture-only)" if cam else "scene Camera3D"])
	quit()


func _place(t: float) -> void:
	# 0-75%: one full turn at 28 deg elevation. 75-100%: a further 60 deg while
	# dipping to -12 deg, below the floor plane, to see behind and underneath.
	var az: float
	var el: float
	if t <= 0.75:
		az = TAU * t / 0.75
		el = deg_to_rad(28.0)
	else:
		var u := smoothstep(0.0, 1.0, (t - 0.75) / 0.25)
		az = TAU + deg_to_rad(60.0) * u
		el = deg_to_rad(lerpf(28.0, -12.0, u))
	cam.position = ORBIT_CENTER + ORBIT_RADIUS * Vector3(sin(az) * cos(el), sin(el), cos(az) * cos(el))
	cam.look_at(ORBIT_CENTER)
