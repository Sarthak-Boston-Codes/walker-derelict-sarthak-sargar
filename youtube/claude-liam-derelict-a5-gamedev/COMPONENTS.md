# COMPONENTS — what the A5 film takes apart

Source of truth: `gamedev-evidence.json` (hashes, excerpts, code→result pairs), built by `build_sheet.py`.

| Component | Files (under `godot/`) | Beats |
|---|---|---|
| low_ammo_effect | `shaders/low_ammo.gdshader`, `game3d/low_ammo_driver.gd`, `game3d/hud.gd`, `game3d/game.gd`, `game3d/player.gd`, `game3d/ui_theme.gd` | B02, B04→B05, B06→B07, B19 |
| low_ammo_test | `tests/low_ammo_test.gd` | B08, B18 |
| hint_experiment | `shaders/hint_experiment.gdshader`, `materials/hint_as_*.tres`, `scenes/hint_experiment.tscn`, `textures/hint_experiment/*` | B09→B10 |
| concrete_material | `shaders/concrete_surface.gdshader`, `materials/concrete_{dry,wet}.tres`, `scenes/material_lab.tscn`, `game3d/level.gd`, `textures/concrete/*` | B11→B12, B13, B14→B15 |
| generated_shader | `shaders/standard_generated.gdshader`, `tools/dump_standard_shader.gd` | B16→B17 |
| material_audit | `tests/test_materials.gd`, `tests/calibrate_normal_map_check.gd`, `tests/normal_map_check.gd`, `tests/fixtures/*`, `MATERIALS.md` | B18, B20 |
| capture_tool | `tools/a5_capture.gd` | B05, B10, B13, B15 |

97 other files are excluded, each with a reason (unchanged by A5).
