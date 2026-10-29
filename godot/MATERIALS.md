# MATERIALS.md — A5 material audit

Written by Claude Code. Evidence lines are quoted from `logs/test_materials_60fps.log` (run `bash scripts/run-test.sh test_materials.gd 60`; copy in `docs/evidence/`) unless another source is named.

## Materials

| Material | Shader | Used by | Values that differ | Shared values |
|---|---|---|---|---|
| `materials/concrete_dry.tres` | `shaders/concrete_surface.gdshader` | the main floor plane (`level.gd` `_build_shell()`, via `_mats.floor`); `scenes/material_lab.tscn` TileDry | `wetness` 0.0, `albedo_tint` white | `uv_scale` 0.5, `roughness_scale` 1.0, `normal_strength` 1.0, `wet_darkening` 0.35, the three textures below |
| `materials/concrete_wet.tres` | same Shader resource | `BoilerRoomWetFloor` plane over `ROOMS["Boiler Room"]` (`level.gd`); material lab TileWet | `wetness` 0.8, `albedo_tint` #C8CCD0 | as above |
| `materials/hint_as_colour.tres` | `shaders/hint_experiment.gdshader` | `scenes/hint_experiment.tscn` QuadSourceColor | `read_as_colour` true | both samplers bound to `greys_3x1.png` |
| `materials/hint_as_data.tres` | same | QuadNoHint | `read_as_colour` false | as above |
| (code-built) ammo label ShaderMaterial | `shaders/low_ammo.gdshader` | `_ammo_label` only (`low_ammo_driver.gd` `setup()`) | `low_ammo` driven 0–1 | `warning_color` never set: shader default #FF3030 |

Evidence: `PASS dry and wet share one Shader resource`, `PASS wet albedo_tint = #C8CCD0 (got c8ccd0)`, `PASS R8 no other node uses the label's material (0 sharers)` (low_ammo_test).

## Samplers

| Shader / sampler | Hints (source text) | Texture | Import settings (`.import`) | Imported as |
|---|---|---|---|---|
| concrete_surface `albedo_tex` | `source_color, filter_linear_mipmap, repeat_enable` | `concrete_floor_worn_001_diff_1k.png` | `compress/mode=2` VRAM Compressed, `compress/normal_map=2` Disable, `mipmaps/generate=true` | format 17 (DXT1), 10 mip levels |
| concrete_surface `roughness_tex` | `filter_linear_mipmap, repeat_enable` (data) | `..._rough_1k.png` | mode 2, normal_map 2, mipmaps on | format 17 (DXT1), 10 mip levels |
| concrete_surface `normal_tex` | `hint_normal, filter_linear_mipmap, repeat_enable` (data) | `..._nor_gl_1k.png` | mode 2, `compress/normal_map=1` Enable, mipmaps on | format 21 (RGTC_RG, two channels), 10 mip levels |
| hint_experiment `tex_as_colour` | `source_color, filter_nearest` | `greys_3x1.png` | `compress/mode=0` Lossless, `mipmaps/generate=false` | format 4 (RGB8), 3×1, no mipmaps; texels 64, 128, 192 |
| hint_experiment `tex_as_data` | `filter_nearest` | same file | same | same |

All four textures also set `detect_3d/compress_to=0` (Disabled), so the importer's 3D-use detection cannot switch their compression later (in 4.7.2 it only acts when that value is non-zero, `resource_importer_texture.cpp:127`).

Enum values, looked up during review: `compress/mode` 0 Lossless, 2 VRAM Compressed; `compress/normal_map` 0 Detect, 1 Enable, 2 Disabled; `detect_3d/compress_to` 0 Disabled (Godot 4.7.2-stable `editor/import/resource_importer_texture.cpp:232,241,260`). Image formats printed by the engine: `FORMAT_RGB8` = 4, `FORMAT_DXT1` = 17, `FORMAT_RGTC_RG` = 21. Uniform types: `TYPE_FLOAT` = 3, `TYPE_COLOR` = 20, `TYPE_OBJECT` = 24; samplers report hint 17 = `PROPERTY_HINT_RESOURCE_TYPE` "Texture2D". Formats and mip counts were read with `get_image().get_format()` / `get_mipmap_count()`.

Evidence: `PASS roughness_tex is sampled as data (no source_color)`, `PASS nor_gl compress/normal_map = 1 (Enable)`, `PASS nor_gl imported as format 21, mipmaps true`, `PASS greys_3x1 texels are 64, 128, 192`.

## Uniform interface (concrete_surface, from `get_shader_uniform_list()`)

| Uniform | Type | Range | Group in source |
|---|---|---|---|
| `albedo_tint` | Color (vec4 + source_color) | — | surface |
| `uv_scale` | float | 0.05–2.0 | surface |
| `albedo_tex` | Texture2D | — | surface |
| `roughness_tex`, `normal_tex` | Texture2D | — | response |
| `roughness_scale` | float | 0.0–1.0 | response |
| `normal_strength` | float | 0.0–2.0 | response |
| `wetness`, `wet_darkening` | float | 0.0–1.0 | wet |

## Lights and environment

| Scene | Light | Environment |
|---|---|---|
| `scenes/material_lab.tscn` | one DirectionalLight3D `Sun45`, `rotation_degrees (-45, 180, 0)`, energy 1.0, no shadow | background `Color(0.02, 0.02, 0.025)`, ambient colour white at energy 0.1, Linear tonemap, exposure 1.0; SSAO, SSR, SSIL, SDFGI, glow, fog, volumetric fog, adjustments off |
| `scenes/hint_experiment.tscn` | none (both quads `render_mode unshaded`) | black background, ambient disabled, Linear tonemap, exposure 1.0; glow, fog, adjustments, SSAO, SSR off |
| the game (`game3d/game.tscn`) | unchanged by A5: built by `level.gd` and `light_animator.gd` | unchanged by A5 |

Evidence: `PASS material lab: Linear 1.0, SSAO/SSR/glow/fog off`, `PASS hint scene: glow, fog, adjustments off`.

## Normal-map convention

`normal_map_check.curl_ratio` on maps downsampled to 256 px (threshold set in `tests/calibrate_normal_map_check.gd`: own convention < 0.6, other > 1.4):

| Map | directx=false | directx=true | Reads as |
|---|---|---|---|
| `nor_gl` (used) | 0.328 | 1.672 | OpenGL ✔ |
| `nor_dx` (fixture) | 1.673 | 0.327 | DirectX ✔ |
| flat (0.5, 0.5, 1.0) | 0.000 | — | — |

## Findings

1. **The kit's normal check had its sign reversed.** As copied, nor_gl scored 1.299 as GL and 0.701 as DX. Image rows run downward while OpenGL green points up. Flipped in `tests/normal_map_check.gd` (commit 1ddd300). Evidence: `docs/evidence/calibrate_normal_map_check_60fps.log`.
2. **At 1k the check barely separates the conventions** (0.70 vs 1.30). Measured: 512 px gives 0.39/1.61, 256 px 0.33/1.67, 128 px 0.38/1.62. Inference, not measured: fine photographic noise, which the kit's comment says scores about 1, dilutes the 1k result. It never came near the 0 vs 2 the kit's comment expects.
3. **The imported normal map has two channels** (format 21, RGTC_RG). Its blue channel is not stored, so a curl check on `get_image()` would see no Z; the check reads the source PNG instead.
4. **Group name differs from the spec:** `group_uniforms wet;` vs the brief's "wetness". Inspector heading only; shader not changed.
5. **The old procedural floor shader is now unused** (`game3d/shaders/concrete_floor.gdshader`); left in place.
6. **The wet Boiler Room floor is a second, visual-only plane** at y = 0.01 (no collider). Navmesh and collision unchanged; all earlier suites pass.
7. **Headless cannot judge the look:** the dummy renderer imports and parses but draws nothing. Brightness, gloss and the hint-experiment values come from windowed captures (TEST-REPORT.md).

## Attribution

Concrete textures: Poly Haven `concrete_floor_worn_001`, Dimitrios Savva (photography), Rico Cilliers (processing), CC0 1.0, checked 2026-10-29. Full record: `godot/textures/concrete/ATTRIBUTION.md`. `greys_3x1.png` is generated by `textures/hint_experiment/make_greys_3x1.gd` (Claude Code).
