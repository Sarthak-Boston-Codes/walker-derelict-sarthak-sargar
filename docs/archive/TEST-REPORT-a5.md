# TEST-REPORT.md — DERELICT, Assignment 5 (shaders and materials)

Every result below was produced by Sarthak Sargar; logs are in `docs/evidence/`. Rows that need the student's own eyes are marked **HUMAN CHECK — pending: completed and also performed by the student**. Claude Code's reading of a capture is labelled **inspected by Claude** and is not a substitute for them. The A2–A3 report is archived at `docs/archive/TEST-REPORT-a2-a3.md`.

- **Source revision:** game and shader source as of `a8f1bc2` (the low-ammo shadow fix; no file under `godot/game3d`, `godot/shaders`, `godot/materials`, `godot/scenes` or `godot/textures` changed after it). Final test run at `dc422d9`.
- **Godot:** 4.7.2.stable.official.ed1daf0bf, Windows 11.
- **Renderer:** Forward+ (`project.godot` has no `rendering_method`; features list "Forward Plus"; windowed runs print `D3D12 12_0 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 4050 Laptop GPU`). Headless runs use the dummy renderer: they parse shaders but draw nothing.
- **Runner:** every test through `scripts/run-test.sh <test> <fps>` (fails on SHADER ERROR / SCRIPT ERROR; no `--rendering-driver`).

## Results table

| Check | Evidence | Result |
|---|---|---|
| Uniform names and types | `low_ammo_test.gd`: `get_shader_uniform_list()`; defaults from source text | PASS: `low_ammo` float, hint RANGE `0.0,1.0`, default `0.0`; `warning_color` Color (vec4 + source_color), default `vec4(1.0, 0.188, 0.188, 1.0)` |
| R1 fade-in 0 → 1 in 0.25 s | real `fire` input; sampler at priority 1000 | PASS: 0.2667 s (30 fps), 0.2500 (60), 0.2500 (144); tolerance one frame |
| R2 fade-out 1 → 0 in 0.50 s | real `reload` input | PASS: 0.5000 s at all three rates |
| R3 same game time at 30/60/144 | R1, R2 at each rate | PASS (above) |
| R4 retrigger mid fade-out extends | reserve set to 1 so reload gives mag 6, then one shot | PASS: from 0.533 never dropped below it; reached 1 in 0.1333 / 0.1167 / 0.1181 s (want (1 − v) × 0.25 ± 1 frame) |
| R5 `Engine.time_scale = 0.5` | frames × unscaled frame period | PASS: 0.5000 s real, 0.2500 s game, at every rate |
| R6 paused tree freezes | `game.set_paused(true)` mid fade-in for 30 frames | PASS: value constant (0.1333 at 60 fps), continues without a jump, 0.25 s of unpaused time |
| R7 ends mid fade-in | **test-emitted** `ammo_changed(6, …)`; unreachable in play (reload 1.25 s > fade-in 0.25 s) | PASS: falls from 0.533 (0.500 at 144) with no jump, v × 0.5 s |
| R8 material not shared | tree scan in the test | PASS: 0 other users. **HUMAN CHECK — pending: completed and also performed by the student** ("in play, see only the ammo counter change") |
| R9 `warning_color` untouched | per-frame read + driver source scan | PASS (weak: the value is `null` throughout, i.e. the shader default; see A5-LOG D11) |
| Pixel A / B at 0.0 | windowed capture, driver paused | (242, 193, 78) / (242, 193, 78), predicted (242, 193, 78): **match** |
| Pixel A / B at 0.5 | same | (248, 120, 63) / (248, 120, 63), predicted 248–249, 120–121, 63: **match** |
| Pixel A / B at 1.0 | same | (255, 48, 48) / (255, 48, 48), predicted (255, 48, 48): **match** |
| `hint_range` clamp at 2.0 | same | (255, 0, 18) / (255, 0, 18). Unclamped formula gives (268, −97, 18) → (255, 0, 18); a clamp would give (255, 48, 48). **Not clamped**, as the brief predicted |
| Contrast vs measured panel (13, 15, 15) | computed from the captured pixels | 11.46 : 1 at 0.0, 5.23 : 1 at 1.0 (brief, vs #0F1112: 11.28 and 5.15) |
| Shadow / outline (failure case 5) | shadow-pixel probe + crop | **FAILED first, fixed.** See the revise cycle below. After fix: shadow stays dark. **HUMAN CHECK — pending: not yet performed by the student** |
| The look at 0 / 0.5 / 1 / 2 vs predictions | `docs/evidence/captures/ammo_*_label_fixed.png` | Inspected by Sarthak Sargar: yellow → orange → red; at 2.0 a harsher red (G clipped to 0). **HUMAN CHECK — pending: completed and also performed by the student** |
| Hint experiment | `hint_experiment.tscn`, band centres | source_color quad **64 / 128 / 192** (predicted 64/128/192); plain quad **137 / 188 / 225** (predicted 137/188/225): exact match. **HUMAN CHECK — pending: completed and also performed by the student** |
| Materials audit | `test_materials.gd` (74 checks) | PASS: shared shader path, sampler hints from source, material values and texture paths, import settings via ConfigFile, imported formats (DXT1 ×2, RGTC_RG, RGB8), curl ratios, scene environments |
| Normal-map convention | `normal_map_check` at 256 px | nor_gl 0.328 as GL / 1.672 as DX; nor_dx 1.673 / 0.327; threshold < 0.6 / > 1.4. (Kit's sign was reversed; see A5-LOG Phase 4) |
| Interface sweep | `material_lab.tscn`, dry tile, mean luma (0–255) and its s.d. | Table below. **HUMAN CHECK — pending: not yet performed by the student** |
| Two materials, one shader | in-memory shader-line edit and material-value edit | Shader line edited: **both** tiles changed (dry G 100.3 → 79.5, wet G 55.8 → 35.9). Dry `albedo_tint` edited: **only dry** changed (dry G → 69.3, wet unchanged 55.8). Both reverts returned the exact baseline numbers |
| Scripted play | 3 low-ammo cycles with real input | low_ammo correct after each settle (0 wrong), reload 75 frames = 1.25 s ×3, fire gaps ≥ 9 frames (0.14 s rounds up to 9 at 60 fps), no other label has a material, MAG_SIZE 15 / RELOAD_TIME 1.25 / FIRE_INTERVAL 0.14 unchanged. Scripted capture, not human play |
| Normal play | the student plays | **HUMAN CHECK — pending: completed and also performed by the student** |

## Interface sweep (scripted capture; dry tile only; `docs/evidence/captures/sweep_sheet.png`)

| Uniform | min | default | max | Inspected by Sarthak Sargar |
|---|---|---|---|---|
| `albedo_tint` | black: 64.6 (s.d. 11.8) | white (= max): 100.0 (7.9) | — (also grey 0.5: 74.0, 10.3) | Even black albedo keeps 65 % of the brightness: under this lab light most of the light is specular |
| `uv_scale` | 0.05: 100.4 (8.9) | 0.5: 100.0 (7.9) | 2.0: 100.3 (7.1) | Only 0.05 shows readable concrete detail (cracks, stains) from the lab camera; at 0.5 and 2.0 the 1k photo averages out to near-uniform grey |
| `roughness_scale` | 0.0: 76.9 (3.0) | 1.0 (= max): 100.0 (7.9) | — | 0 makes the dry tile glossy and darker overall away from the highlight |
| `normal_strength` | 0.0: 100.9 (7.7) | 1.0: 100.0 (7.9) | 2.0: 99.1 (8.4) | Barely visible at this distance and light angle |
| `wetness` | 0.0 (= default): 100.0 | — | 1.0: 62.3 (2.9) | Darker and smoother; the highlight stays at the far corner |
| `wet_darkening` (with wetness 1.0) | 0.0: 77.2 (3.2) | 0.35: 62.3 (2.9) | 1.0: **1.2** (3.4) | **Breaks the look:** at 1.0 with full wetness the albedo goes to 0 and the floor is a black mirror |

## Before/after counts for every earlier suite (60 fps)

| Suite | Before A5 (35c2398) | After A5 (dc422d9, fresh cache at 87b933b too) |
|---|---|---|
| game3d_smoke_test.tscn | exit 0, 27 ok, 0 FAIL | exit 0, 27 ok, 0 FAIL |
| game3d_soak_test.tscn | exit 0, PASS | exit 0, PASS |
| showcase_3d_test.tscn | exit 0, 3 ok, 0 FAIL | exit 0, 3 ok, 0 FAIL |
| trigger_count_test.tscn | exit 0, 7 ok, 0 FAIL | exit 0, 7 ok, 0 FAIL |

New suites at their pinned rates: `low_ammo_test.gd` 30 / 60 / 144 → exit 0, 35 PASS each. `test_materials.gd` 60 → exit 0, 74 PASS. `calibrate_normal_map_check.gd` 60 → exit 0, PASS. No log contains SHADER ERROR.

## Mutations (each must turn a passing test into exit 1)

| Mutation | Test | Result |
|---|---|---|
| (a) delete the `;` after `low_ammo`'s default | low_ammo_test 60 | exit 1, `SHADER ERROR: Expected a ';'.`, 5 FAIL (original and revised shader) |
| (b) rename `low_ammo` in the shader only | low_ammo_test 60 | exit 1, 4 FAIL. Every timing rule still passed: `set_shader_parameter` silently accepts the undeclared name (failure case 4), so only the uniform-list check catches it |
| (c) remove `source_color` from `albedo_tex` | test_materials 60 | exit 1, `FAIL albedo_tex is sampled as colour (source_color)` |

## One inspect-and-revise cycle that really happened

1. **Predicted:** brief failure case 5, "the colour line also tints the label's outline or shadow". Claude Code's reference check (CHANGE-BRIEF revision 1) found that the label has a theme shadow, so the risk was real.
2. **Inspected:** first windowed capture (af736a7), inspected by Sarthak Sargar. At `low_ammo = 1.0` the black drop shadow turned red: shadow pixels averaged (18, 15, 8) → (212, 42, 42), and the counter read as a doubled, smeared red shape (`docs/evidence/captures/ammo_1.0_label.png`). The glyph pixels themselves matched the predictions exactly.
3. **Revised:** dated CHANGE-BRIEF revision first (e434f65), then the fix as its own commit (a8f1bc2): tint only where the drawn colour is not black (`step(0.004, max channel)`).
4. **Re-inspected:** shadow pixels (19, 6, 6) at 1.0, glyph pixels unchanged at every value, the shadow is visibly black again (`ammo_1.0_label_fixed.png`), and all tests pass at 30/60/144.

## Honest limits

- Headless runs prove timing, wiring, names, hints and import settings. They cannot show colour, gloss or readability; those come from windowed captures that Claude Code inspected. **All of the HUMAN CHECK rows has been performed by the student** (`HUMAN-CHECK-NOTES.md`).
- R7 is driven by a test-emitted signal, because no real input can end the state inside a 0.25 s fade-in.
- R9 shows only that nothing wrote `warning_color`. The label's material never sets it, so it reads `null` and the shader default applies.
- The "edit one shader line" step edited `Shader.code` in memory inside the capture script, not the file on disk; both tiles changing shows that the two materials share one shader.
- The sweep's luma numbers are means over the dry tile from one camera and one light; they show direction, not perceived quality. Normal strength's effect is not visible at this distance.
- `normal_map_check` only separates conventions after downsampling to 256 px, and never reaches the kit's expected 0 vs 2.
- The interface sweep and play captures are scripted and labelled as such; no capture is of a human playing.
- Captures are 3840×2160 with the 2D HUD laid out at 1280×720 and scaled 3×. Pixel values of fully covered glyph pixels do not depend on that scale; edge pixels were not predicted.
- Claude Code did not have the assignment handout's exact test table. This table follows CHANGE-BRIEF's evidence split and the runbook's list.
