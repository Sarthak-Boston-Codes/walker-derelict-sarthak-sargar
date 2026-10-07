extends RefCounted
## Builds stand-in art and audio at runtime, so no placeholder files live in
## the project. Only used for IDs whose manifest path is "".

const SPRITE_SIZE := 48 # matches CHARACTER-SHEET.md's 48x48 top-down sprite
const OUTLINE := Color("#1C1C1C")
const MIX_RATE := 22050

# One distinct color per state so a state change is visible at a glance.
# Each keeps >= 3:1 contrast against the floor color.
# "body" = filled circle with a north notch (shows facing when rotated).
const ART_SPECS := {
	"CHAR-IDLE": {"shape": "body", "color": Color("#8A938F")},
	"CHAR-WALK": {"shape": "body", "color": Color("#A98BD9")},
	"CHAR-AIM": {"shape": "body", "color": Color("#F2C14E")},
	"CHAR-SHOOT-FOLLOWTHROUGH": {"shape": "body", "color": Color("#FF8A3D")},
	"CHAR-HURT": {"shape": "body", "color": Color("#F06A64")},
	"CHAR-GRABBED-FAIL": {"shape": "body", "color": Color("#F05AB4")},
	"CHAR-RECOVER": {"shape": "body", "color": Color("#4FA3D9")},
	"CHAR-CELEBRATE": {"shape": "body", "color": Color("#F5F5F5")},
	"ZOMBIE-SHAMBLE": {"shape": "body", "color": Color("#9DB84A")},
	"ZOMBIE-DOWN": {"shape": "down", "color": Color("#A3A86B")},
	"ENV-FACTORY-FLOOR": {"shape": "floor", "color": Color("#3A3C3B")},
}

# Each sound is a list of segments: [wave, start_hz, end_hz, seconds].
# Distinct pitch/length per slot so you can tell by ear which one fired.
const AUDIO_SPECS := {
	"SFX-SHOT": {"segments": [["square", 880.0, 440.0, 0.08]], "volume": 0.35},
	"SFX-DOWN": {"segments": [["sine", 300.0, 110.0, 0.35]], "volume": 0.6},
	"SFX-HURT": {"segments": [["square", 160.0, 140.0, 0.25]], "volume": 0.35},
	"SFX-CLEAR": {"segments": [["sine", 523.0, 523.0, 0.18], ["sine", 659.0, 659.0, 0.18], ["sine", 784.0, 784.0, 0.3]], "volume": 0.5},
}


static func make_texture(id: String) -> Texture2D:
	var spec: Dictionary = ART_SPECS[id]
	var img: Image
	match spec.shape:
		"body":
			img = _body(spec.color)
		"down":
			img = _down(spec.color)
		"floor":
			img = _floor(spec.color)
	return ImageTexture.create_from_image(img)


static func make_stream(id: String) -> AudioStream:
	if id == "MUS-LOOP":
		return _music_loop()
	var spec: Dictionary = AUDIO_SPECS[id]
	var samples := PackedFloat32Array()
	for seg in spec.segments:
		samples.append_array(_segment(seg[0], seg[1], seg[2], seg[3]))
	return _to_wav(samples, spec.volume, false)


# --- art -------------------------------------------------------------------

static func _body(color: Color) -> Image:
	var img := Image.create_empty(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var c := Vector2(SPRITE_SIZE, SPRITE_SIZE) / 2.0
	for y in SPRITE_SIZE:
		for x in SPRITE_SIZE:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			if d <= 18.0:
				img.set_pixel(x, y, color)
			elif d <= 20.0:
				img.set_pixel(x, y, OUTLINE)
	# North notch: facing marker, points up like the reference pose.
	img.fill_rect(Rect2i(21, 2, 6, 16), OUTLINE)
	return img


static func _down(color: Color) -> Image:
	var img := Image.create_empty(SPRITE_SIZE, SPRITE_SIZE, false, Image.FORMAT_RGBA8)
	var c := Vector2(SPRITE_SIZE, SPRITE_SIZE) / 2.0
	for y in SPRITE_SIZE:
		for x in SPRITE_SIZE:
			# Flattened ellipse: reads as "on the ground", not just recolored.
			var p := (Vector2(x + 0.5, y + 0.5) - c) / Vector2(22.0, 11.0)
			var r := p.length()
			if r <= 0.88:
				img.set_pixel(x, y, color)
			elif r <= 1.0:
				img.set_pixel(x, y, OUTLINE)
	return img


static func _floor(color: Color) -> Image:
	var size := Vector2i(1280, 720)
	var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	img.fill(color)
	var seam := color.darkened(0.25)
	for x in range(0, size.x, 64):
		img.fill_rect(Rect2i(x, 0, 2, size.y), seam)
	for y in range(0, size.y, 64):
		img.fill_rect(Rect2i(0, y, size.x, 2), seam)
	# Dark border marks the walls.
	var wall := color.darkened(0.6)
	img.fill_rect(Rect2i(0, 0, size.x, 16), wall)
	img.fill_rect(Rect2i(0, size.y - 16, size.x, 16), wall)
	img.fill_rect(Rect2i(0, 0, 16, size.y), wall)
	img.fill_rect(Rect2i(size.x - 16, 0, 16, size.y), wall)
	return img


# --- audio -----------------------------------------------------------------

static func _segment(wave: String, from_hz: float, to_hz: float, seconds: float) -> PackedFloat32Array:
	var n := int(seconds * MIX_RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / n
		phase += lerpf(from_hz, to_hz, t) / MIX_RATE
		var s := sin(TAU * phase)
		if wave == "square":
			s = signf(s)
		# 5 ms attack, then decay to silence -- no click at either end.
		var env := minf(1.0, i / (0.005 * MIX_RATE)) * pow(1.0 - t, 2.0)
		out[i] = s * env
	return out


static func _music_loop() -> AudioStream:
	# 4 s drone: 55 Hz + 82.5 Hz with a slow swell. Every frequency completes
	# a whole number of cycles in 4 s, so the loop seam is sample-continuous.
	var seconds := 4.0
	var n := int(seconds * MIX_RATE)
	var samples := PackedFloat32Array()
	samples.resize(n)
	for i in n:
		var t := float(i) / MIX_RATE
		var swell := 0.6 + 0.4 * sin(TAU * t / seconds)
		samples[i] = (sin(TAU * 55.0 * t) + 0.5 * sin(TAU * 82.5 * t)) / 1.5 * swell
	return _to_wav(samples, 0.25, true)


static func _to_wav(samples: PackedFloat32Array, volume: float, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i] * volume, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = samples.size()
	return wav
