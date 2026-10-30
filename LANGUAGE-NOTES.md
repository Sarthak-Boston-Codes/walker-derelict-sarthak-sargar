# LANGUAGE-NOTES.md — the Godot shading language in DERELICT's A5 shaders

**Written by Sarthak Sargar.**

The three shaders referred to:
- **G** = `godot/shaders/standard_generated.gdshader`: the code Godot 4.7.2 generated for a StandardMaterial3D with an albedo texture, a normal map and a roughness texture (saved by `godot/tools/dump_standard_shader.gd`; unused by the game).
- **L** = `godot/shaders/low_ammo.gdshader` (as revised 2026-10-29, commit a8f1bc2).
- **C** = `godot/shaders/concrete_surface.gdshader`. (**H** = `godot/shaders/hint_experiment.gdshader` where the hint experiment is cited.)

## Where things are in the generated shader (G)

| What | Line | Text |
|---|---|---|
| `shader_type` | G:3 | `shader_type spatial;` |
| `render_mode` | G:4 | `render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;` |
| albedo colour uniform | G:6 | `uniform vec4 albedo : source_color;` |
| normal strength uniform | G:20 | `uniform float normal_scale : hint_range(-16.0, 16.0);` |
| albedo sampler + hints | G:7 | `uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;` |
| normal sampler + hints | G:19 | `uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;` |
| (roughness sampler) | G:14 | `uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;` |
| writes `ALBEDO` | G:35 | `ALBEDO = albedo.rgb * albedo_tex.rgb;` (sampled at G:34) |
| writes `ROUGHNESS` | G:43 | `ROUGHNESS = roughness_tex * roughness;` |
| writes `NORMAL_MAP` | G:46 | `NORMAL_MAP = texture(texture_normal, base_uv).rgb;` (strength at G:47, `NORMAL_MAP_DEPTH = normal_scale;`) |

## The eight questions

**1. What does `shader_type` decide, for each type used?**
It picks which pipeline the shader belongs to, so which processor functions exist, which built-ins they see, and which render modes are legal. `canvas_item` (L:1) is a 2D shader for CanvasItems such as the HUD Label: its `fragment()` gets `COLOR` (vertex colour × texture), `TEXTURE` and `UV`, and nothing is lit because the HUD has no 2D lights. `spatial` (C:1, H:1, G:3) is a 3D shader for meshes: `vertex()` gets `VERTEX` in model space and `MODEL_MATRIX`; `fragment()` writes surface properties (`ALBEDO`, `ROUGHNESS`, `NORMAL_MAP`) that Godot's lighting then uses. Spatial is lit by default (C has no render_mode). H adds `render_mode unshaded` (H:2), so `ALBEDO` goes to the screen with no lighting. That is why the hint experiment can be read as plain numbers.

**2. Which processor functions are written, and what would moving the colour line into `vertex()` change?**
L writes only `fragment()` (L:9). C writes `vertex()` (C:25) and `fragment()` (C:31). H writes `fragment()` (H:11). G writes `vertex()` and `fragment()`. *Reasoned, not captured:* in a canvas_item `vertex()`, `COLOR` is the per-vertex colour (the label's font colour, or black for the shadow quads). Mixing it there would run 4 times per glyph quad instead of once per pixel, and the default fragment would then multiply the result by the glyph texture. The tint is the same across a quad, so the glyphs would look the same; the revised shadow check would also still work, because the shadow quads' vertex colour is black. What would change is where the work happens (per vertex, then interpolated). Also, if `fragment()` were kept and still mixed, the tint would be applied twice.

**3. Three built-ins read and two written; which are read-only?**
Read: `COLOR` (L:12–13), `MODEL_MATRIX` and `VERTEX` (C:27), `UV` (H:12). Written: `COLOR` (L:13), `ALBEDO` (C:34), `ROUGHNESS` (C:35), `NORMAL_MAP` (C:36), `NORMAL_MAP_DEPTH` (C:37). Read-only (`in` in Godot's built-in tables): `MODEL_MATRIX`, and `UV` in a spatial `fragment()`. `COLOR` in a canvas_item `fragment()` and `VERTEX` in `vertex()` are `inout`, so they can be read and written. (Also per the brief, §6.4: in a spatial `fragment()`, `COLOR` is the interpolated vertex colour and is read-only.)

**4. What does each hint do to the Inspector and to the value the shader receives? (the hint experiment)**
- `source_color` on a sampler (H:7, C:9, G:7) marks the texture as sRGB colour: each texel is decoded to linear when sampled. **Observed** (`docs/evidence/captures/hint_experiment.png`, `logs/capture_hint.log`): the same PNG greys 64/128/192 display as **64/128/192** through the `source_color` sampler and as **137/188/225** through the plain one (H:8), exactly as CHANGE-BRIEF §3 predicted. With the hint, decode and the display's encode cancel. Without it the raw numbers are treated as linear and encoded once, so they come out brighter. On a `vec4` (L:7, C:7, G:6) `source_color` makes the uniform a Color: `get_shader_uniform_list()` reports `warning_color` as type 20 (`TYPE_COLOR`) rather than a Vector4 (low_ammo_test log), and that is what gives the Inspector a colour picker.
- `hint_range(min, max)` (L:6, C:8, C:14–15, C:18–19) turns the uniform into a slider: the uniform list reports hint 1 (`PROPERTY_HINT_RANGE`) with `"0.0,1.0,0.0010000000475"` for `low_ammo`. As question 5 shows, it does not change the value the shader receives.
- `hint_normal` (C:13) declares the sampler a normal map, i.e. data, not colour; G instead uses `hint_roughness_normal` (G:19), the variant BaseMaterial3D emits. The value-level effect of either was **not measured** here. Neither has `source_color`, which `test_materials.gd` asserts and the source_color mutation proved it checks (`docs/evidence/mutation_c_source_color.log`).
- `filter_nearest` (H:7–8): no interpolation between texels, so the 3-texel strip shows three hard bands, sampled at each band's centre.
- Inspector caveat: Claude Code never opened the editor Inspector. The Inspector statements above come from the uniform list's types and hints, which is the data the Inspector is built from.

**5. Does `hint_range` clamp values set from code?**
No. **Observed** (`docs/evidence/capture_ammo_fixed.log`, `docs/evidence/captures/ammo_2.0_label_fixed.png`): with the driver paused and `low_ammo` set to 2.0 by `set_shader_parameter`, pixels A and B read **(255, 0, 18)**. The unclamped formula 242 + (255 − 242)·2, 193 + (48 − 193)·2, 78 + (48 − 78)·2 gives (268, −97, 18), which the display stores as (255, 0, 18). A clamp to 1.0 would have given (255, 48, 48). `hint_range` at L:6 only shapes the slider; the driver keeps the value in 0–1 itself (`low_ammo_driver.gd:44`, `move_toward` toward 0 or 1).

**6. Which generated line samples albedo as colour and normal as data, and what is the equivalent in concrete_surface?**
Albedo as colour: the declaration G:7 (`source_color`) plus the sample at G:34, `vec4 albedo_tex = texture(texture_albedo, base_uv);`. Equivalent: C:9 declaration and C:32, `vec3 base = texture(albedo_tex, world_uv).rgb * albedo_tint.rgb;`. Normal as data: the declaration G:19 (no `source_color`) plus G:46, `NORMAL_MAP = texture(texture_normal, base_uv).rgb;`. Equivalent: C:13 and C:36, `NORMAL_MAP = texture(normal_tex, world_uv).rgb;`. In both shaders, whether a texture is colour or data is decided by the declaration's hint, not by the `texture()` call. The one real difference is the UVs: G uses mesh `UV` scaled by `uv1_scale` (G:28), while C builds world-space UVs in `vertex()` (C:27–28), so every floor piece tiles seamlessly.

**7. Why can't `fragment()` read a neighbour's result, and how does game state reach it?**
`fragment()` runs once per pixel, many at once on the GPU, and each invocation only sees its own inputs: built-ins, varyings (C:23), uniforms and textures. No other pixel's output exists yet, and no shared result is written back to read. (A texture can be sampled at a neighbouring UV, but that reads the input, not the neighbour's result.) Game state reaches the shader only through uniforms: `player.mag` changes → the `ammo_changed` signal (`player.gd:9`) → `low_ammo_driver.gd:37` sets the target → `:44` moves the value by `delta` → `:45` `material.set_shader_parameter(PARAM, value)` → the `low_ammo` uniform (L:6) that the colour line reads (L:13).

**8. Two things the Godot shading language provides that plain GLSL doesn't.**
(a) **Processor functions and built-ins instead of a hand-written pipeline.** `shader_type spatial;` (C:1) plus `void fragment()` writing `ALBEDO`/`ROUGHNESS`/`NORMAL_MAP` (C:34–36) is the whole shader. There is no `main()`, no `in`/`out` declarations and no lighting code. Godot wraps it in its own GLSL, adds its lighting, and `render_mode` (G:4, H:2) picks among built-in options. (b) **Uniform hints that reach the editor and the sampler.** `source_color`, `hint_range`, `hint_normal`, filter and repeat hints (C:7–15) and `group_uniforms` (C:6, C:11, C:17) are part of the declaration. They decide sRGB decoding (observed in question 4), the Inspector widget and grouping, and sampler state. In plain GLSL those would be engine-side code.
