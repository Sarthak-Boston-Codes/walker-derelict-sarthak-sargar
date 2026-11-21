# CLAUDE.md — DERELICT, Assignment 7 (two animations)

## Project context

- Engine: Godot 4.7.2 (`godot/project.godot:15`, `config/features` lists "4.7"). Local binary: `C:\Users\sarth\GotDot\Godot_v4.7.2-stable_win64.exe` (export as `GODOT`; `scripts/run-test.sh` defaults to it).
- Renderer: Forward+ (`project.godot:15` lists "Forward Plus"; no `rendering_method` line, so the default applies); `rendering_device/driver.windows="d3d12"` (`project.godot:91`).
- Window: 1280 × 720, stretch `canvas_items`, aspect `expand` (`project.godot:25-28`).
- Main scene `res://game3d/menu.tscn` (`project.godot:14`); the game is `res://game3d/game.tscn`, script `game3d/game.gd`, which builds the level, the player (node "Player", `game.gd:57-59`) and the HUD (node "Hud", `game.gd:82-87`).
- HUD: `godot/game3d/hud.gd`, a `CanvasLayer` built in code, `PROCESS_MODE_ALWAYS` (`hud.gd:52`). Keycard element `_key_label` (`hud.gd:102-104`), setter `set_keycard()` (`hud.gd:327`), called from `game.gd:135`.
- Player state machine: owned by `godot/game3d/player.gd` (implicit flags, no enum): `alive` (`:41`), `_reload_left` (`:59`), decremented on the process tick in `_update_weapon()` (`:195-198`, called from `_process` `:168`); fire lock `:204-205`; `start_reload()` `:217`; `_finish_reload()` `:233`; `_die()` `:330` (zeroes `_reload_left`, emits only `died`). Signals `reload_changed(active)` `:10`, `died` `:12`. Constants `MAG_SIZE` `:26`, `FIRE_INTERVAL` `:29`, `RELOAD_TIME` `:30`.
- Clip 1, keycard spin (cycle): route 1, `Sprite2D` `KeycardIcon` + `AnimationPlayer` frame track. Scene `godot/game3d/keycard_icon.tscn`, clip `godot/animations/keycard_spin.tres`, sheet `godot/art/keycard_sheet.png` (from `tools/make_keycard_sheet.py`). 12 fps, `LOOP_LINEAR`.
- Clip 2, pistol reload (committing action): route 3, `Node2D` cutout rig `PistolRig` (`Body`, `Slide`, `Mag` pivots with `Polygon2D` parts). Scene `godot/game3d/pistol_rig.tscn`, clip `godot/animations/pistol_reload.tres`, 24 fps, `LOOP_NONE`, length 1.25 s = `RELOAD_TIME`.
- Animation driver: `godot/game3d/hud_anim.gd` (`HudAnim`), attached from `hud.gd`/`game.gd`.
- Build status: the two clip scenes, the clips, the sheet, `HudAnim`, the previews and the A7 tests below are created in runbook Phases 3-9; until a file exists, its line here is the plan, not a fact (review 2026-11-20).
- Previews: `godot/previews/pistol_reload_preview.tscn`, `keycard_spin_preview.tscn`. Strips: `captures/<clip>/r<N>[-light|-dark]/`, readings in TUNING.md.
- Tests: run every one through the wrapper from the repo root in Git Bash. `bash scripts/run-test.sh <file> <fps|realtime> [timeout]` writes `logs/<name>_<fps>fps.log` (or `_realtime.log`, no `--fixed-fps`) and fails on SHADER ERROR, SCRIPT ERROR or Failed loading resource (`scripts/run-test.sh:23`).
  ```
  bash scripts/run-test.sh game3d_smoke_test.tscn 60        # also soak, showcase_3d, trigger_count (.tscn, 60)
  bash scripts/run-test.sh low_ammo_test.gd 30              # also 60 and 144
  bash scripts/run-test.sh test_materials.gd 60
  bash scripts/run-test.sh calibrate_normal_map_check.gd 60
  bash scripts/run-test.sh test_impact_burst_config.gd 60   # also _state, test_wound_smoke_config/_state
  bash scripts/run-test.sh test_pins_player.gd 60
  bash scripts/run-test.sh test_keycard_spin_readback.gd 60
  bash scripts/run-test.sh test_pistol_reload_readback.gd 60
  bash scripts/run-test.sh test_hud_anim_structure.gd 60
  bash scripts/run-test.sh test_hud_anim_state.gd 60
  bash scripts/run-test.sh test_pistol_reload_edges.gd 60
  bash scripts/run-test.sh test_two_clocks.gd 60            # also 30
  bash scripts/run-test.sh <test> realtime                  # real time, for anything that awaits audio
  ```
  Import first after any asset change: `"$GODOT" --headless --path godot --import`.

## Current change

@CHANGE-BRIEF.md

## Ownership

- `godot/shaders/` holds the A5 shaders and is never edited. `git diff --stat godot/shaders/` must print nothing after every phase.
- A6 effects (`godot/effects/`), their drivers (`impact_fx.gd`, `wound_smoke_driver.gd`) and the ammo label's `low_ammo_driver.gd` stay untouched.
- Clips live as resources in `godot/animations/` or in the scene that owns them (`RESET` lives in `pistol_rig.tscn`), and are never built in code at run time. Code calls only `play()`, `stop()` and reads.
- Authorship: the brief, its predictions, the phase table, the cycle spec and the approvals were written by Claude; the sheet generator, clips, rig, `HudAnim`, tests, pins, previews, captures, strip readings, documents and film were written by Claude Code. Never write that the student wrote any of it or did a check they did not do.
- Human checks and tuning verdicts are the student's; they read "pending: not yet performed by the student" until the student gives them (`HUMAN-CHECK-NOTES.md`).

## One authority

- `HudAnim` (`godot/game3d/hud_anim.gd`) is the only writer of both animated nodes: it calls `play()`/`stop()` on `KeycardIcon`'s `AnimationPlayer` and `PistolRig`'s `AnimationPlayer`, and sets the icon's `visible`. The `AnimationPlayer`s are the only writers of `KeycardIcon:frame` and `Body`/`Slide`/`Mag` `position`/`rotation`.
- No tween, no `autoplay`, no `AnimatedSprite2D`, no `AnimationTree`, no other script writes them. `test_hud_anim_structure.gd` asserts it.
- Both `AnimationPlayer`s: `callback_mode_process` PROCESS_IDLE, `process_mode` PAUSABLE (the HUD root is ALWAYS).

## Godot 4 names

- Godot 4.7.2 names only: `AnimationPlayer`, `Animation.loop_mode` (`LOOP_NONE`/`LOOP_LINEAR`), `speed_scale`, `step`, `value_track_set_update_mode`, `Sprite2D.hframes/vframes/frame`, `callback_mode_process`, `current_animation`.
- Never Godot 3 names: `loop`, `playback_speed`, `AnimatedSprite`, `playback_process_mode`. If unsure a property exists, check `ClassDB.class_get_property_list()` and say so.

## Out of scope

- Gameplay: collision, movement, input mapping, fire/reload timings (`FIRE_INTERVAL`, `RELOAD_TIME`, `MAG_SIZE`), zombies, waves, every other HUD element.
- The A5 shaders, the A6 effects and drivers, the low-ammo driver; existing tests and their expectations; source models and textures.
- Committing mp4/mp3/wav under `youtube/`, files over 25 MB, `godot/.godot/`, credentials. Never move or delete an existing tag.

## Unconfirmed

- Every human check (`HUMAN-CHECK-NOTES.md`): cycle seam over five wraps, the reload in play with an interrupt in each phase, keycard registration, both backgrounds, the student's verdict on each tuning revision.
- The two-clocks disagreement is measured by `test_two_clocks.gd`, not assumed.
- `test_impact_burst_state.gd` (A6) failed its two-hit section once on the first run after a fresh import (A7-LOG.md Phase 0).

## Headless facts

- A headless run uses a dummy renderer: clips advance and structure can be read (`current_animation`, `current_animation_position`, node properties), but nothing is drawn. Pixels and registration cannot be checked headless.
- Key times are stored as 32-bit floats: compare with a tolerance (half a frame period), never `==`.
- `Animation.value_track_get_update_mode()` applies only to value tracks; ask it only of `TYPE_VALUE` tracks.
- Frame strips come from a windowed Movie Maker run (`--write-movie <abs path>/frame.png --fixed-fps 30`), never headless.
- Headless the window is 64 × 64 with the 1280-wide canvas stretched onto it: a mouse event must be in window pixels (`root.get_final_transform() * viewport_pos`).
- Test input goes through `Input.parse_input_event` with events from `project.godot`'s input map (R = physical 82, fire = mouse button 1, pause = Escape), never `Input.action_press`.
- A `--script` whose `_init()` stops on a SCRIPT ERROR never reaches `quit()`; the wrapper's timeout (exit 124) catches it.
