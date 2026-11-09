# walker-derelict-sarthak-sargar

**DERELICT**: a top-down 3D zombie shooter in a derelict factory, built for CSYE 7270. Assignment 6 adds two particle effects.

## Start point
An empty Godot 4 project (Assignment 2). It was redone as a top-down 3D shooter on branch `a2-redo-3d` (tag `a2-redo`; see REDO-LOG.md). A5 added shaders and materials (tag `a5`), and A6 builds on tag `a5` (commit c076952) on branch `a6-effects`. The original 2D slice still runs from `scenes/main.tscn`.

## Engine and renderer
Godot 4.7.2 (stable), GDScript. Renderer: Forward+ (the default; `project.godot` names no `rendering_method`), D3D12 on Windows. Physics: Jolt.

## Run instructions
- Play: open `godot/project.godot` in Godot 4.7.2 and press F5, or `godot --path godot`. The main scene is `res://game3d/menu.tscn`.
- Import first on a fresh clone: `godot --headless --path godot --import`.
- Tests (Git Bash, from the repo root; `GODOT` defaults to the local install; logs in `logs/`):
  ```
  bash scripts/run-test.sh game3d_smoke_test.tscn 60
  bash scripts/run-test.sh game3d_soak_test.tscn 60
  bash scripts/run-test.sh showcase_3d_test.tscn 60
  bash scripts/run-test.sh trigger_count_test.tscn 60
  bash scripts/run-test.sh low_ammo_test.gd 30      # and 60, 144
  bash scripts/run-test.sh test_materials.gd 60
  bash scripts/run-test.sh calibrate_normal_map_check.gd 60
  bash scripts/run-test.sh test_impact_burst_config.gd 60
  bash scripts/run-test.sh test_impact_burst_state.gd 60
  bash scripts/run-test.sh test_wound_smoke_config.gd 60
  bash scripts/run-test.sh test_wound_smoke_state.gd 60
  bash scripts/run-test.sh cost_effects.gd 60 300   # headless CPU price
  ```
  `realtime` in place of the frame rate runs without `--fixed-fps` (none of the A6 tests needs it).
- GPU price (needs a window): `godot --path godot --resolution 1280x720 --script res://tools/gpu_price.gd`. The script turns vsync off itself. No F9 vsync toggle was added: F9 is unused, but an in-game key would be an input change the brief keeps out of scope.
- Frame strips: the commands are in TUNING.md.

## Controls
WASD move · mouse aim (the flashlight follows) · hold left click to fire · R reload · F flashlight · Esc pause · M / N mute music / SFX.

## What Assignment 6 added
- **Effect A, impact burst** (`godot/effects/impact_burst.tscn`): three `GPUParticles3D` (Flash, Sparks, Puff) under one Node3D. It fires on every bullet that hits a zombie, barrel or crate. `player.gd` gained one signal, `bullet_hit(point, normal)`, and one emit line (the only gameplay edit). `godot/game3d/impact_fx.gd` keeps a pool of 12 bursts under the level root, so rapid hits overlap, a burst outlives the zombie it hit, and a full pool restarts the oldest.
- **Effect B, wound smoke** (`godot/effects/wound_smoke.tscn`): one `GPUParticles3D` at the player's chest with turbulence. `godot/game3d/wound_smoke_driver.gd` reads `health_changed` and writes only `emitting` and `amount_ratio` = clamp((60 − hp) / 50, 0.2, 1.0) while hp ≤ 60; it never writes `amount`.
- Configuration tests read every brief setting back from the scenes; state tests drive real fire, real zombie damage and a real medkit; Godot's generated particle process shader is saved in `godot/shaders/particles_generated.gdshader`.
- Specification: CHANGE-BRIEF.md (with dated revisions). Results: TEST-REPORT.md. Strips and tuning: TUNING.md, `captures/`. Run log: A6-LOG.md. Human checks: HUMAN-CHECK-NOTES.md.
- **Authorship:** the brief, its predictions, budgets and answers, the tuning approvals and the process-shader notes were written by Claude; the effects, previews, trigger code, tests, cost and GPU scripts, strip readings, documents and film were written by Claude Code. Per-file detail: SOURCES.md.

## Known limitations
- Every human check and every tuning verdict is pending: not yet performed by the student (HUMAN-CHECK-NOTES.md).
- Effect A sizes do not change over life: billboard particles in 4.7.2 ignore the process scale unless `billboard_keep_scale` is on, which the brief's table doesn't set. The one-setting fix (A-r1) made the puff too small and was reverted; a two-setting fix awaits approval.
- The first particles of a burst appear one frame (33 ms at 30 fps) after the trigger.
- Wound smoke, seen from the near-vertical camera with the player standing still, stays mostly over the player's silhouette and reads lighter than its background. In motion it should trail behind; that is the student's check.
- Barrel-blast hits fire no burst (they don't go through `fire()`); wall hits keep the earlier sparks and fire no burst.
- Both effects' headless CPU price is not separable from frame-to-frame drift; their GPU price is at the counter's noise floor (+0.02 ms, budgets 0.30 / 0.20 ms).
- From earlier assignments: the low-ammo tint skips pure-black pixels; the concrete reads near-uniform at the default `uv_scale`; the wet floor is a visual-only plane; character textures are projected (REDO-LOG.md).

## Final film
Assignment 6: *link pending: added after upload.* Sources: `youtube/claude-liam-derelict-a6-gamedev/`.

Assignment 5: *link pending: added after upload.* Sources: `youtube/claude-liam-derelict-a5-gamedev/`.

Assignment 3: [claude-liam-derelict-a3-gamedev.mp4](https://northeastern-my.sharepoint.com/:v:/g/personal/sargar_s_northeastern_edu/IQBald7nRCFHS49Ti14FlqiNAdEhDYcTMONK6Qb8iQPGJq8?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=o8xobl) (4K, 5:30, SHA-256 `5608a5c80dd7b3063de7e98a053fe0ec3273a57fddc8cf886828d83a52b65000`).

Assignment 2: [claude-liam-derelict-gamedev.mp4](https://northeastern-my.sharepoint.com/:v:/g/personal/sargar_s_northeastern_edu/IQCFoi1kkFy2Q4daIwhOXtEYAXZkEDaRUn4HmrIvm5dfSfs?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=LiBMqC) (4K, 5:03, SHA-256 `6f4d313043854ce67adaaf5a8509140ba76a20bc89d3593a7f2b627f3cff82b1`).

## Earlier assignments
- A5 added the low-ammo HUD shader, the textured concrete floor (dry and wet), the hint experiment and the saved StandardMaterial3D shader; see tag `a5`, `docs/archive/TEST-REPORT-a5.md` and SOURCES.md.
- A3 added a 3D showcase scene (`godot/scenes/showcase_3d.tscn`) with a supply crate, rusted barrel and medkit built in Blender 5.2.2 via the Blender MCP; `godot/tests/showcase_3d_test.gd` checks them. Archived reports: `docs/archive/`.
