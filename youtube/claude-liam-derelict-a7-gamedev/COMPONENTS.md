# COMPONENTS: what the A7 film takes apart

Source of truth: `gamedev-evidence.json` (hashes, excerpts, code→result pairs), built by `build_sheet.py` (Claude Code).

| Component | Files (under `godot/`) | Beats |
|---|---|---|
| keycard_spin | `animations/keycard_spin.tres`, `game3d/keycard_icon.tscn`, `art/keycard_sheet.png` (+ `.import`), `tests/test_keycard_spin_readback.gd`, `tests/anim_readback_lib.gd`, `previews/keycard_spin_preview{,_dark}.tscn` | B02, B03, B04→B05 |
| pistol_reload | `animations/pistol_reload.tres`, `game3d/pistol_rig.tscn`, `tests/test_pistol_reload_readback.gd`, `tests/test_pistol_reload_edges.gd`, `previews/hud_anim_preview.gd`, `previews/pistol_reload_preview{,_light}.tscn` | B02, B06→B07, B14 |
| hud_anim_authority | `game3d/hud_anim.gd`, `game3d/game.gd`, `tests/test_hud_anim_structure.gd`, `tests/test_hud_anim_state.gd` | B08→B09, B10→B11 |
| game_clock | `game3d/player.gd`, `tests/test_pins_player.gd`, `tests/test_two_clocks.gd` | B12→B13, B15 |
| hud | `game3d/hud.gd` (unchanged) | B08 |

The sheet generator `tools/make_keycard_sheet.py` is outside `godot/`; B05 shows its output and names it. Every other file under `godot/` is in `gamedev-evidence.json` `exclusions` with a reason.
