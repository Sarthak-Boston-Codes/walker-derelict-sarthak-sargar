# walker-derelict-sarthak-sargar

**DERELICT**: a top-down 3D zombie shooter in a derelict factory, built for CSYE 7270. Assignment 5 adds shaders and materials.

## Start point
An empty Godot 4 project (Assignment 2). It was redone as a top-down 3D shooter on branch `a2-redo-3d` (tag `a2-redo`; see REDO-LOG.md), and A5 builds on that. The original 2D slice still runs from `scenes/main.tscn`; the A3 assets are placed in the 3D level as props.

## Engine and renderer
Godot 4.7.2 (stable), GDScript. Renderer: Forward+ (the default; `project.godot` names no `rendering_method`), D3D12 on Windows. Physics: Jolt.

## Run instructions
- Play: open `godot/project.godot` in Godot 4.7.2 and press F5, or `godot --path godot`. The main scene is `res://game3d/menu.tscn`.
- Tests (Git Bash, from the repo root; pinned frame rates):
  ```
  bash scripts/run-test.sh game3d_smoke_test.tscn 60
  bash scripts/run-test.sh game3d_soak_test.tscn 60
  bash scripts/run-test.sh showcase_3d_test.tscn 60
  bash scripts/run-test.sh trigger_count_test.tscn 60
  bash scripts/run-test.sh low_ammo_test.gd 30      # and 60, 144
  bash scripts/run-test.sh test_materials.gd 60
  bash scripts/run-test.sh calibrate_normal_map_check.gd 60
  ```
  Import first on a fresh clone: `godot --headless --path godot --import`.

## Controls
WASD move · mouse aim (the flashlight follows) · hold left click to fire · R reload · F flashlight · Esc pause · M / N mute music / SFX.

## What Assignment 5 added
- **A shader that shows game state:** the HUD ammo counter turns from yellow to red when the magazine holds 5 rounds or fewer (`godot/shaders/low_ammo.gdshader`, canvas_item). A presentation-only driver (`godot/game3d/low_ammo_driver.gd`) eases it in over 0.25 s and out over 0.5 s in scaled game time, freezes it on pause, and writes only the `low_ammo` uniform.
- **A textured material:** `godot/shaders/concrete_surface.gdshader` with a Poly Haven CC0 concrete set (albedo as colour, roughness and normal as data). It drives two materials from one shader: dry on the factory floor, wet on the Boiler Room floor. A material lab scene, `godot/scenes/material_lab.tscn`, is used to judge them.
- **A hint experiment** (`godot/scenes/hint_experiment.tscn`): one grey strip read with and without `source_color`, measured 64/128/192 vs 137/188/225.
- **Godot's own generated StandardMaterial3D shader** (`godot/shaders/standard_generated.gdshader`) for comparison, with LANGUAGE-NOTES.md.
- Specification: CHANGE-BRIEF.md. Tests and captures: TEST-REPORT.md, godot/MATERIALS.md, A5-LOG.md.
- **Authorship:** the A5 shaders, the brief's colour line, predictions and answers were written by Claude (chat). The driver, tests, materials, scenes, tools and documents were written by Claude Code. The TA verbally allowed AI-written work for A5 provided the student understands it (written confirmation pending). See SOURCES.md.

## Known limitations
- The look has been checked by Claude Code's inspection of captures only. The student's own checks (HUMAN-CHECK-NOTES.md) are pending.
- The low-ammo shader skips pure-black pixels so the label's drop shadow stays black. A deliberately black label would never tint.
- At the default `uv_scale` the 1k concrete photo reads as fairly uniform grey from the game's camera; `normal_strength` is hardly visible at that distance.
- The wet Boiler Room floor is a second, visual-only plane over the main floor (no collider).
- `normal_map_check` separates the GL and DX conventions only after downsampling to 256 px.
- From A2/A3: character textures are projected (sides and back stretched; REDO-LOG.md). The old procedural floor shader `game3d/shaders/concrete_floor.gdshader` is now unused.

## Final film
Assignment 5: *link pending: added after upload.* Sources: `youtube/claude-liam-derelict-a5-gamedev/`.

Assignment 3: [claude-liam-derelict-a3-gamedev.mp4](https://northeastern-my.sharepoint.com/:v:/g/personal/sargar_s_northeastern_edu/IQBald7nRCFHS49Ti14FlqiNAdEhDYcTMONK6Qb8iQPGJq8?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=o8xobl) (4K, 5:30, SHA-256 `5608a5c80dd7b3063de7e98a053fe0ec3273a57fddc8cf886828d83a52b65000`).

Assignment 2: [claude-liam-derelict-gamedev.mp4](https://northeastern-my.sharepoint.com/:v:/g/personal/sargar_s_northeastern_edu/IQCFoi1kkFy2Q4daIwhOXtEYAXZkEDaRUn4HmrIvm5dfSfs?nav=eyJyZWZlcnJhbEluZm8iOnsicmVmZXJyYWxBcHAiOiJPbmVEcml2ZUZvckJ1c2luZXNzIiwicmVmZXJyYWxBcHBQbGF0Zm9ybSI6IldlYiIsInJlZmVycmFsTW9kZSI6InZpZXciLCJyZWZlcnJhbFZpZXciOiJNeUZpbGVzTGlua0NvcHkifX0&e=LiBMqC) (4K, 5:03, SHA-256 `6f4d313043854ce67adaaf5a8509140ba76a20bc89d3593a7f2b627f3cff82b1`).

## Earlier assignments
- A3 added a 3D showcase scene (`godot/scenes/showcase_3d.tscn`) with a supply crate, rusted barrel and medkit built in Blender 5.2.2 via the Blender MCP; `godot/tests/showcase_3d_test.gd` checks them. Archived reports: `docs/archive/`.
