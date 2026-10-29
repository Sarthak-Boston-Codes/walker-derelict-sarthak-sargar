# CLAUDE.md — DERELICT, Assignment 5

## Project context

- Engine: Godot 4.7.2 (`godot/project.godot`, `config/features` lists "4.7"). Local binary: `C:\Users\sarth\GotDot\Godot_v4.7.2-stable_win64.exe`.
- Renderer: Forward+. `project.godot` has no `rendering_method` line, so the default applies; `config/features` lists "Forward Plus" and `rendering_device/driver.windows="d3d12"`.
- Main scene: `res://game3d/menu.tscn` (`project.godot`, `run/main_scene`). The game itself is `res://game3d/game.tscn`, script `game3d/game.gd`.
- The ammo label: `_ammo_label`, a Label built in code at `godot/game3d/hud.gd:88` (`UI.label("15 / 45", 30, UI.ACCENT)`), inside the HUD CanvasLayer (`hud.gd:1`, `layer = 10` at `hud.gd:50`). Its text and colour are set in `set_ammo()` at `hud.gd:306-308` (DANGER when `mag == 0`). It inherits a theme drop shadow (`ui_theme.gd:21-23`).
- Ammo state is owned by `godot/game3d/player.gd`: `var mag` (`:37`), `MAG_SIZE` (`:24`), `RELOAD_TIME` (`:28`), `fire()` decrements at `:243`, `_finish_reload()` refills at `:233`. It reports through `signal ammo_changed(mag, reserve)` (`:9`), connected to `hud.set_ammo` at `game.gd:90`.
- 3D floor: one PlaneMesh (42.6 × 32.6) under one StaticBody3D built in `_build_shell()` (`level.gd:379-398`), with `material_override = _mats.floor`. That material is `res://materials/concrete_dry.tres` (ShaderMaterial on `res://shaders/concrete_surface.gdshader`), assigned in `_make_materials()` (`level.gd:130-133`). The Boiler Room gets a visual-only plane `BoilerRoomWetFloor` with `concrete_wet.tres` (`level.gd:403-407`). The old `game3d/shaders/concrete_floor.gdshader` is unused. Room rectangles, including "Boiler Room" Rect2(10, -18, 22, 18), are in `ROOMS` (`level.gd:35-40`). The navmesh bakes from static colliders only (`level.gd:185`), so visual-only meshes do not change it.
- Tests: run every one through the wrapper from the repo root, in Git Bash. It writes `logs/<name>_<fps>fps.log` and fails on SHADER ERROR / SCRIPT ERROR.
  ```
  bash scripts/run-test.sh game3d_smoke_test.tscn 60
  bash scripts/run-test.sh game3d_soak_test.tscn 60
  bash scripts/run-test.sh showcase_3d_test.tscn 60
  bash scripts/run-test.sh trigger_count_test.tscn 60
  bash scripts/run-test.sh low_ammo_test.gd 30      # also 60 and 144
  bash scripts/run-test.sh test_materials.gd 60
  bash scripts/run-test.sh calibrate_normal_map_check.gd 60
  ```
  `godot/tests/game3d_shot.tscn` is a screenshot harness (needs a window, asserts nothing), not a test.
  Import first after any asset change: `"$GODOT" --headless --path godot --import`.

## Current change

@CHANGE-BRIEF.md

## Ownership

- The three A5 shaders (`low_ammo`, `concrete_surface`, `hint_experiment`), the CHANGE-BRIEF colour line, predictions and brief answers were written by Claude (chat). The driver, tests, materials, scenes, tools, MATERIALS.md and LANGUAGE-NOTES.md were written by Claude Code, which also made one fix to `low_ammo.gdshader` (shadow, CHANGE-BRIEF revision 2026-10-29) and flipped the sign in the kit's `normal_map_check.gd`. The TA verbally allowed AI-written work for A5 provided the student understands it; written confirmation is pending from the student.
- The student chose the state and the six design decisions listed in CHANGE-BRIEF.md's opening paragraph by accepting Claude's defaults.
- Shaders in `godot/shaders/` change only when a test or capture shows a real bug, and then a dated revision goes into CHANGE-BRIEF.md first and the fix is its own commit.
- Never write that the student wrote shader code or performed a check they did not perform. HUMAN CHECK rows stay "pending" until the student reports them.

## Out of scope

- Gameplay: collision, movement, input, fire/reload timings, zombies, waves, other HUD elements.
- Existing tests and their expectations; source models and textures.
- `--rendering-driver` flags; committing mp4/mp3/wav under `youtube/`, files over 25 MB, `godot/.godot/`.

## Unconfirmed

- Everything a HUMAN CHECK row covers (HUMAN-CHECK-NOTES.md): Claude Code's capture inspection is not the student's.
- Resolved 2026-10-29: the shadow *was* tinted (fixed, a8f1bc2); HDR 2D is off (`use_hdr_2d` false in the capture, and pixels matched the sRGB-mix prediction); the generated StandardMaterial3D shader is reachable by RID scan (`godot/tools/dump_standard_shader.gd`).

## Headless facts

Observed 2026-10-29 with a probe script under `--headless`:
- `RenderingServer.get_current_rendering_method()` reports `forward_plus` and driver `d3d12`, but storage is the dummy one (errors cite `servers/rendering/dummy/storage/material_storage.cpp`). Nothing is drawn; pixels cannot be checked headless.
- The dummy renderer still parses shaders: a missing `;` prints `SHADER ERROR: Expected a ';'.`, and `Shader.get_shader_uniform_list()` returns the uniforms (a `source_color` vec4 comes back as type 20 Color, a `hint_range` float as hint 1 RANGE).
- `ShaderMaterial.set_shader_parameter()` accepts a name the shader does not declare and returns it from `get_shader_parameter()`.
- `RenderingServer.shader_get_parameter_default()` returns null headless; read defaults from the shader source text.
- `StandardMaterial3D` has no `get_shader_rid()` in GDScript (SCRIPT ERROR "Nonexistent function").
- Freeing an instanced scene with ShaderMaterials prints `ERROR: Parameter "material" is null` (dummy `material_storage.cpp:264`); harmless, not a SHADER/SCRIPT ERROR.
- An imported normal map with `compress/normal_map=1` is RGTC_RG (two channels); check normal maps from the source PNG.
- A `--script` whose `_init()` stops on a SCRIPT ERROR never reaches `quit()`; the wrapper's 120 s timeout (exit 124) catches it.
