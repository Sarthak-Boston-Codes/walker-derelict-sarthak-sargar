# COMPONENTS: what the A6 film takes apart

Source of truth: `gamedev-evidence.json` (hashes, excerpts, code→result pairs), built by `build_sheet.py`.

| Component | Files (under `godot/`) | Beats |
|---|---|---|
| impact_burst_effect | `effects/impact_burst.tscn`, `tests/test_impact_burst_config.gd`, `previews/effect_preview.gd`, `previews/impact_burst_preview{,_light}.tscn` | B03, B04→B05, B10 |
| impact_trigger | `game3d/player.gd`, `game3d/impact_fx.gd`, `game3d/game.gd`, `tests/test_impact_burst_state.gd` | B02, B06→B07, B08→B09 |
| wound_smoke_effect | `effects/wound_smoke.tscn`, `tests/test_wound_smoke_config.gd`, `previews/wound_smoke_preview{,_dark}.tscn` | B11→B12, B15 |
| wound_smoke_driver | `game3d/wound_smoke_driver.gd`, `tests/test_wound_smoke_state.gd` | B02, B13→B14 |
| process_shader | `shaders/particles_generated.gdshader`, `tools/dump_particles_shader.gd`, `tools/probe_particle_scale.gd` | B03, B16→B17 |
| price | `tests/cost_effects.gd`, `tools/gpu_price.gd` | B18 |

Every other file under `godot/` is listed in `gamedev-evidence.json` `exclusions` with a reason (unchanged by A6).
