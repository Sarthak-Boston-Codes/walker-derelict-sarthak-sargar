# CHANGE-BRIEF.md — Assignment 5: shaders, materials and the Godot shading language

Game: DERELICT (top-down 3D, Godot 4.7.2). This file holds only the current change; the Assignment 2–3 brief is archived at `docs/archive/CHANGE-BRIEF-a2-a3.md`. Committed 2026-10-29, before the shaders are committed and before any Claude Code prompt for this change. **Authorship, stated plainly:** the state and the six design decisions (threshold of 5 rounds, red #FF3030, 0.25 s in and 0.5 s out, extend on retrigger, scaled time and frozen on pause, steady tint) were chosen by the student by accepting Claude's proposed defaults. The colour line, the predictions and the brief answers in sections 2, 3 and 6 were written and computed by Claude (chat), with the TA's verbal permission, and explained to the student. Dated revisions go at the bottom; the text above them stays as committed.

## 1. The state

**Low ammo**: the player's magazine holds 5 rounds or fewer, `player.mag <= 5` (`godot/game3d/player.gd:37`, `var mag`), reported to the HUD by the `ammo_changed(mag, reserve)` signal (`player.gd:9`). It begins when a shot takes `mag` from 6 to 5 (`player.gd:243`) and ends when `mag` rises above 5, normally when a reload finishes (`player.gd:233`).

Why the player needs it: running dry with a zombie in reach is the easiest death to avoid. The magazine count sits in peripheral vision while the player watches the dark, so the warning has to change colour, not only a number.

## 2. Effect specification

**Object:** the HUD ammo counter, `_ammo_label` (a Label created at `godot/game3d/hud.gd:88`), drawn in `UI.ACCENT` = #F2C14E (`godot/game3d/ui_theme.gd:5`) at font size 30. It is 2D HUD on a CanvasLayer with no 2D lights, so its output is unlit and can be modelled.

**Shader:** `godot/shaders/low_ammo.gdshader`, `shader_type canvas_item;`, no render_mode. No sampler uniforms of its own; the label's glyphs arrive in `COLOR`. No `TIME`: a steady tint.

| Uniform | Type | Hint | Default | Set by |
|---|---|---|---|---|
| `low_ammo` | float | `hint_range(0.0, 1.0)` | `0.0` | the driver, every frame, from the low-ammo state |
| `warning_color` | vec4 | `source_color` | #FF3030 = (1.0, 0.188, 0.188, 1.0) | the label's ShaderMaterial; never by code |

**The colour line**, inside `fragment()` (written by Claude):
```glsl
COLOR.rgb = mix(COLOR.rgb, warning_color.rgb, low_ammo);
```
`COLOR` already holds the label's own colour for this pixel; `mix` blends it toward `warning_color` by `low_ammo` (0 = no change, 1 = fully the warning colour). Alpha is untouched, so glyph edges keep their antialiasing.

**Driver:** a presentation-only node that reads `player.mag` through `ammo_changed` and writes only the `low_ammo` uniform on the label's material. It never writes game state.

### Observable rules

| # | Rule | Predicted behaviour |
|---|---|---|
| R1 | State begins | `low_ammo` rises from its current value at 4.0 per second; from 0.0 it reaches 1.0 after 0.25 s ± one frame period |
| R2 | State ends | falls at 2.0 per second; from 1.0 it reaches 0.0 after 0.50 s ± one frame period |
| R3 | Frame rate | R1 and R2 take the same game time at 30, 60 and 144 fps (tolerance 1/30, 1/60, 1/144 s) |
| R4 | Begins again mid-transition | **extend**: rises from wherever it is and never resets to 0; from value v it reaches 1.0 after (1 − v) × 0.25 s |
| R5 | Time scale | scaled game time: at `Engine.time_scale = 0.5` a full fade-in takes 0.5 s of real time (0.25 s of game time) |
| R6 | Paused tree | the value freezes while paused and continues from the same value on unpause |
| R7 | Ends before a transition finishes | falls from the value reached; from v it reaches 0.0 after v × 0.5 s, with no jump |
| R8 | Instances | one ammo label; its ShaderMaterial is its own and shared with nothing |
| R9 | Only `low_ammo` is driven | `warning_color` keeps its material value throughout |

### Boundaries — must not change

Collision, movement, input, the player's fire and reload state machine and its timings (`MAG_SIZE`, `RELOAD_TIME`), zombies, waves, every other HUD element and 3D object, the source model and texture files, and every existing test and its expectations. Presentation code may read game state; it never writes it.

### Evidence split

| Rule | Checked by | How |
|---|---|---|
| R1–R7, R9 | headless test | drive low ammo with real fire input through the game loop; sample `low_ammo` every frame from a node with a high `process_priority`; run at 30, 60 and 144 fps |
| R8 | headless test + my eyes | assert the label's material is not shared; in play, see only the ammo counter change |
| Uniform names and types | headless test | `get_shader_uniform_list()`; defaults read from the shader source text |
| The look | my eyes | in-engine captures at the controlled values below, compared with my predictions; normal play |

### Controlled inputs and predicted values (computed by Claude with a script; formulas shown so they can be rechecked)

- **Pixel A:** inside a stroke of the magazine digits.
- **Pixel B:** inside the stroke of the "/" separator.

Both are fully covered glyph pixels whose colour before the effect is #F2C14E = (242, 193, 78), so the background behind the label doesn't reach them. Antialiased edge pixels are observed, not predicted.

Assumption, to confirm by capture: HDR 2D is off (`project.godot` sets no `hdr_2d`), so the mix happens on the sRGB values as written, and `source_color` leaves `warning_color` at (255, 48, 48).

Formula, per channel: result = a + (b − a) × t, with a = (242, 193, 78) and b = (255, 48, 48), rounded to the nearest integer.

| `low_ammo` (t) | Pixel A (R, G, B) | Pixel B (R, G, B) |
|---|---|---|
| 0.0 | (242, 193, 78) | (242, 193, 78) |
| 0.5 | (248.5, 120.5, 63): displays 248 or 249, 120 or 121, 63 (the .5 can round either way, so ±1 counts as a match) | same as A |
| 1.0 | (255, 48, 48) | (255, 48, 48) |

Contrast against #0F1112, the HUD panel colour (`ui_theme.gd:9`; the panel is 86 % opaque over the 3D scene, so the real background drifts and this is a best case): ratio at 0.0 = **11.28 : 1**; ratio at 1.0 = **5.15 : 1**.
So the warning stays readable (above 4.5 : 1) but communicates by hue, not contrast: red on dark is less luminous than the yellow it replaces. The capture check records the real figure.
(decode each channel c in 0–1: c/12.92 if c ≤ 0.04045, else ((c + 0.055)/1.055)^2.4. Luminance L = 0.2126 R + 0.7152 G + 0.0722 B on the decoded values. Ratio = (L_lighter + 0.05) / (L_darker + 0.05).)

## 3. The hint experiment

A committed GDScript writes `godot/textures/hint_experiment/greys_3x1.png`: one row of three texels, greys 64, 128 and 192, imported Lossless with no mipmaps. `godot/shaders/hint_experiment.gdshader` (`spatial`, `render_mode unshaded`) binds that file to two samplers, one with `source_color, filter_nearest` and one with `filter_nearest` only, and a bool uniform picks which one writes `ALBEDO`. Two materials (bool true and false) go on two quads facing the camera, under a WorldEnvironment with a Linear tonemap at exposure 1.0 and glow, fog and adjustments off. Renderer: Forward+.

Prediction (computed by Claude with a script). encode(x) = 12.92x for x ≤ 0.0031308, otherwise 1.055·x^(1/2.4) − 0.055, with x = value / 255; displayed = round(255 × result).

| Band in the file | Quad with source_color | Quad without |
|---|---|---|
| 64 | **64** | **137** (encode(0.251) = 0.538) |
| 128 | **128** | **188** (encode(0.502) = 0.737) |
| 192 | **192** | **225** (encode(0.753) = 0.882) |

The quad **with `source_color`** shows the file's values unchanged: the sampler decodes each texel from sRGB to linear on the way in and the display encodes it back on the way out, so the two steps cancel. Without `source_color` the raw numbers are treated as linear and encoded once, which brightens them (64 becomes 137). A colour read as data comes out too bright; data read as colour, such as a roughness map, would come out too dark.

## 4. Material plan — the textured shader

**Object:** the factory floor. **Judged under:** a material lab scene, `godot/scenes/material_lab.tscn`: two floor tiles side by side, one DirectionalLight3D at a fixed 45°, low ambient light, SSAO, SSR, glow and fog off, Linear tonemap at exposure 1.0. In the game, the dry material covers the floors and the wet one the Boiler Room.

**Shader:** `godot/shaders/concrete_surface.gdshader`, `shader_type spatial;`, default (lit) render mode.

| Texture | Role | Source | What its numbers mean | Sampled as | Import settings, set explicitly |
|---|---|---|---|---|---|
| albedo | colour | a Poly Haven concrete floor set (asset ID, authors, licence and date added as a dated revision and in ATTRIBUTION.md at download) | sRGB-encoded surface colour | colour, `source_color` | compress/mode VRAM Compressed, compress/normal_map Disabled, mipmaps/generate on |
| roughness | data | same set | 0 = mirror-smooth, 1 = fully rough, stored linearly | data, no `source_color` | VRAM Compressed, normal_map Disabled, mipmaps on |
| normal | data | same set, `_nor_gl` (the OpenGL convention Godot expects) | tangent-space slopes; (0.5, 0.5, 1.0) = flat | data, `hint_normal` | VRAM Compressed, normal_map Enabled, mipmaps on |

| Uniform | Type | Hint / range | Default | Group | Expected change across its range |
|---|---|---|---|---|---|
| `albedo_tint` | vec4 | `source_color` | white | surface | multiplies the colour: white = the texture as is, darker = a darker floor |
| `uv_scale` | float | `hint_range(0.05, 2.0)` | 0.5 | surface | texture repeats per metre, using world-space UVs set in `vertex()`: low = large slabs, high = a small, busy pattern |
| `roughness_scale` | float | `hint_range(0.0, 1.0)` | 1.0 | response | 0 = glossy everywhere, 1 = the texture's own roughness |
| `normal_strength` | float | `hint_range(0.0, 2.0)` | 1.0 | response | 0 = flat, 2 = exaggerated bumps |
| `wetness` | float | `hint_range(0.0, 1.0)` | 0.0 | wetness | 0 = dry, 1 = darker and glossy |
| `wet_darkening` | float | `hint_range(0.0, 1.0)` | 0.35 | wetness | how much darker the floor gets when fully wet |

**Two materials,** `godot/materials/concrete_dry.tres` and `godot/materials/concrete_wet.tres`, share the shader and differ in `wetness` (0.0 vs 0.8) and `albedo_tint` (white vs a cooler #C8CCD0). Why: most floors are dry; the Boiler Room's leaking pipes leave its floor wet, so it reads as a different place under the flashlight.

## 5. Predicted failure cases

1. **Retrigger resets instead of extending:** the driver restarts a timer from 0. Check: the headless test makes low ammo begin again during a fade-out and asserts the value never drops below its value on that frame.
2. **Duration depends on frame rate:** a frame-counting fade. Check: the test at 30, 60 and 144 fps asserts 0.25 s and 0.5 s of game time within one frame period.
3. **A data texture sampled with source_color:** roughness or normal decoded as colour. Check: the material test asserts each sampler's hints from the shader source, and the source_color mutation must fail it.
4. **Driver and shader disagree on the uniform name:** `set_shader_parameter` silently accepts a name the shader doesn't declare. Check: the uniform-list assertion; the rename mutation must fail it.
5. **The colour line also tints the label's outline or shadow,** if it has one. Check: my eyes on the 1.0 capture.

## 6. Brief answers

1. **Renderer:** `project.godot` names none (it has no `rendering_method` line), so Godot's default, Forward+, applies. That rules out none of the listed features: decals, compute shaders, VoxelGI, SDFGI and SSIL are all available.
2. **What arrives in `fragment()` before I change it, and what would the tempting alternative give?** `COLOR` already holds the label's own colour (#F2C14E, with glyph coverage in alpha): the vertex colour multiplied by the texture sample. The tempting alternative, `texture(TEXTURE, UV)`, returns only the raw glyph texture, which is white coverage, so the label would lose its yellow.
3. **(canvas_item) `texture(TEXTURE, UV)` instead of `COLOR`:** the texture value without the node's own colour. For this label that is white-on-transparent glyphs, so mixing from it would blend white toward red, not yellow toward red.
4. **(spatial) `ALBEDO` and `COLOR`:** if `ALBEDO` is never written the surface is white, `vec3(1.0)`. In a spatial `fragment()`, `COLOR` is the interpolated vertex colour and is read-only, so it is not the surface colour.
5. **A frame-counting fade-in tuned to 0.25 s at 60 fps** is 15 frames, so it lasts 0.50 s at 30 fps, 0.25 s at 60 fps and 0.104 s at 144 fps. Mine moves by `delta`, so it takes the same game time at every rate.
6. **Default vs current value:** the shader holds the default (the `= 0.0` in the declaration); the `ShaderMaterial` holds the current value, set with `set_shader_parameter`. Two objects sharing one material share the current value, so changing it on one changes both.
7. **Does `hint_range` clamp a value set from code?** Prediction: no. It shapes the Inspector slider only, so the shader receives 2.0 as 2.0. Checked in Use It with a capture at 2.0.

## Revisions

(Dated entries below. The text above stays as committed.)

### 2026-10-29 — reference check (Claude Code)

Every file/line reference above was checked against commit 7917c8c and is correct: `player.gd:9` declares `signal ammo_changed(mag: int, reserve: int)`; `:37` is `var mag := MAG_SIZE`; `:233` is `mag += take` in `_finish_reload()`; `:243` is `mag -= 1` in `fire()`; `hud.gd:88` creates `_ammo_label = UI.label("15 / 45", 30, UI.ACCENT)`; `ui_theme.gd:5` is `ACCENT := Color("#F2C14E")`; `ui_theme.gd:9` is `PANEL := Color(0.06, 0.065, 0.07, 0.86)` (= #0F1112 at 86 %); `project.godot` has no `rendering_method` and no `hdr_2d` line (its features list says "Forward Plus").

Three facts the text above does not account for (added, not corrections of it):

1. **The label has a drop shadow.** `ui_theme.gd:21-23` gives every Label a theme shadow (`font_shadow_color` black at 0.8 alpha, offset 2,2), and the HUD root uses that theme (`hud.gd:54`). A Label draws its shadow through the same CanvasItem, so the shader runs on the shadow too, and `mix(black, warning_color, 1.0)` would make the shadow red. Failure case 5 is therefore live, not hypothetical; the 1.0 capture decides it.
2. **At `mag == 0` the label is not #F2C14E.** `hud.gd:308` switches `font_color` to `UI.DANGER` = #E5483B (`ui_theme.gd:8`) when the magazine is empty. The pixel A/B predictions hold for `mag` 1–5; at 0 the input colour is (229, 72, 59) and only the t = 1.0 row (255, 48, 48) still applies.
3. **The HUD never pauses.** `hud.gd:49` sets `process_mode = PROCESS_MODE_ALWAYS` so the pause menu works. A driver added under the HUD inherits that, so R6 (freeze on pause) needs the driver to set its own `process_mode = PROCESS_MODE_PAUSABLE`.
