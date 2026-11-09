# CLAUDE.md — DERELICT, Assignment 6 (two particle effects)

## Project context

- Engine: Godot 4.7.2 (`godot/project.godot`, `config/features` lists "4.7"). Local binary: `C:\Users\sarth\GotDot\Godot_v4.7.2-stable_win64.exe` (export it as `GODOT` for `scripts/run-test.sh`).
- Renderer: Forward+. `project.godot` has no `rendering_method` line, so the default applies; `config/features` lists "Forward Plus"; `rendering_device/driver.windows="d3d12"`.
- Window: 1280 × 720, stretch `canvas_items`, aspect `expand` (`project.godot:25-28`).
- Main scene `res://game3d/menu.tscn` (`run/main_scene`); the game is `res://game3d/game.tscn`, script `game3d/game.gd`, which builds the level (`game.gd:42-44`, node "Level"), the player (`game.gd:51-54`, node "Player", built in code, no scene) and the HUD.
- Effect A's event, a bullet hitting a victim: `fire()` in `godot/game3d/player.gd:241`; the shot ray is cast at `:257`; a collider with `hit()` (zombie, barrel, crate) is hit at `:264` with `end = hit.position` and `hit.normal`. Victims implement `hit(damage, point, dir, normal)` (`player.gd:5-6`). `FIRE_INTERVAL := 0.14` (`:27`). A6 adds `signal bullet_hit(point, normal)` and one emit there (the only gameplay edit).
- Effect B's condition: `player.hp` (`player.gd:36`), `MAX_HP := 100.0` (`:23`), reported by `signal health_changed(hp, max_hp)` (`:8`), emitted by `take_damage()` (`:297`) and `heal()` (`:315`, used by medkits through `pickup.gd:72`). Death: `_die()` (`:327`) sets `alive = false` and emits `died`.
- Effects (A6): `godot/effects/impact_burst.tscn` (Node3D root, three `GPUParticles3D`: Flash, Sparks, Puff) and `godot/effects/wound_smoke.tscn` (one `GPUParticles3D`), each with a `ParticleProcessMaterial` and a `StandardMaterial3D` draw material, all written in the scene file.
- Trigger code (A6): `godot/game3d/impact_fx.gd` (pool of 12 bursts under the level root, listens to `bullet_hit`) and `godot/game3d/wound_smoke_driver.gd` (listens to `health_changed`/`died`, writes only `emitting` and `amount_ratio`).
- Preview scenes: `godot/previews/impact_burst_preview.tscn`, `godot/previews/wound_smoke_preview.tscn`. Frame strips: `captures/<effect>/r<N>/`.
- Tests: run every one through the wrapper from the repo root in Git Bash. `bash scripts/run-test.sh <file> <fps|realtime> [timeout]` writes `logs/<name>_<fps>fps.log` (or `_realtime.log`, no `--fixed-fps`) and fails on SHADER ERROR / SCRIPT ERROR.
  ```
  bash scripts/run-test.sh game3d_smoke_test.tscn 60
  bash scripts/run-test.sh game3d_soak_test.tscn 60
  bash scripts/run-test.sh showcase_3d_test.tscn 60
  bash scripts/run-test.sh trigger_count_test.tscn 60
  bash scripts/run-test.sh low_ammo_test.gd 30          # also 60 and 144
  bash scripts/run-test.sh test_materials.gd 60
  bash scripts/run-test.sh calibrate_normal_map_check.gd 60
  bash scripts/run-test.sh test_impact_burst_config.gd 60
  bash scripts/run-test.sh test_impact_burst_state.gd 60
  bash scripts/run-test.sh test_wound_smoke_config.gd 60
  bash scripts/run-test.sh test_wound_smoke_state.gd 60
  bash scripts/run-test.sh cost_effects.gd 60 300
  bash scripts/run-test.sh <test> realtime               # real time, for anything that awaits audio
  ```
  Import first after any asset change: `"$GODOT" --headless --path godot --import`.

## Current change

@CHANGE-BRIEF.md

## Ownership

- `godot/shaders/` holds the A5 shaders and is never edited in A6. `git diff --stat godot/shaders/` must print nothing after every phase. The one exception is the new, unused `godot/shaders/particles_generated.gdshader` (Phase 7 dump).
- Effect settings live in the scene files in `godot/effects/`, never in code. Code writes only `emitting`, `amount_ratio`, transforms and `restart()`.
- Authorship: the brief, its predictions, budgets and answers, the tuning approvals and the process-shader notes were written by Claude; the effects, previews, trigger code, tests, cost and GPU scripts, strip readings, documents and film were written by Claude Code. Never write that the student wrote any of it, and never record a check the student has not performed.
- Human checks and tuning verdicts are the student's; they read "pending: not yet performed by the student" until the student gives them (`HUMAN-CHECK-NOTES.md`).

## Godot 4 names

- Use Godot 4.7.2 names only: `GPUParticles3D`, `ParticleProcessMaterial`, `initial_velocity_min/max`, `scale_min/max`, `damping_min/max`, `turbulence_enabled`, `turbulence_noise_strength`, `amount_ratio`, `visibility_aabb`, `use_fixed_seed`.
- Never Godot 3 names such as `ParticlesMaterial`, `Particles`, a float `initial_velocity` or `scale`. If unsure a property exists, check `ClassDB.class_get_property_list()` or the class reference, and say so.

## Out of scope

- Gameplay: collision, movement, input, fire/reload timings, zombies, waves, the state machine, HUD.
- The A5 shaders in `godot/shaders/`; existing tests and their expectations; source models and textures.
- Committing mp4/mp3/wav under `youtube/`, files over 25 MB, `godot/.godot/`, credentials.

## Unconfirmed

- Every human check (HUMAN-CHECK-NOTES.md): rapid repeats in play, Effect B start/stop/pause/hide, size at 1280 × 720, dark and light backgrounds, screen edge, scene load, the Visual Profiler read, and the student's verdict on each tuning revision.
- What a float written to `initial_velocity` does in 4.7.2 (it is a Vector2 range property there).

## Headless facts

- A headless run uses a dummy renderer (`servers/rendering/dummy/`): nothing is drawn and no particles are simulated or drawn. Pixels and particle positions cannot be checked headless.
- A GPU effect's headless CPU price is near zero by construction: the dummy renderer runs no particle process shader.
- Frame strips come from a windowed Movie Maker run (`--write-movie <abs path>/frame.png --fixed-fps 30`), never headless.
- The dummy renderer still parses shaders; a broken one prints `SHADER ERROR`.
- `ShaderMaterial.set_shader_parameter()` accepts names the shader does not declare; read back from resources to check.
- A `--script` whose `_init()` stops on a SCRIPT ERROR never reaches `quit()`; the wrapper's timeout (exit 124) catches it.
- `StandardMaterial3D` has no `get_shader_rid()` in GDScript; generated shaders are reached by RID scan (`godot/tools/dump_standard_shader.gd`).
