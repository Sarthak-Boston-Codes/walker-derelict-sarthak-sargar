# A6-LOG — Assignment 6, two particle effects

Written by Claude Code while executing `A6-RUNBOOK.md` (from `a6-kit.zip`). The brief, its predictions, budgets and answers, the tuning approvals and the process-shader notes were written by Claude; the effects, previews, trigger code, tests, cost and GPU scripts, strip readings, documents and film were written by Claude Code. Nothing in this log is a check performed by the student unless it quotes the student.

## Phase 0 — setup (2026-11-08)

Decisions:
- **Kit location.** The runbook says extract to `C:\Users\sarth\a6-kit`; the student's instruction to Claude Code said `C:\Users\sarth\Game Development\a6-kit`. The student's instruction wins: the kit is in `Game Development\a6-kit` (outside the repo, never committed).
- **Repo.** `C:\Users\sarth\Game Development\walker-derelict-sarthak-sargar` (origin `Sarthak-Boston-Codes/walker-derelict-sarthak-sargar`). Working tree was clean on branch `a5` at c076952.
- **Branch.** `git switch -c a6-effects refs/tags/a5`; HEAD = c076952ccf44e60ab99ca7a3a8f1d1a3f68ce8a1 (the tag's commit, as the runbook states).
- **Wrapper.** `scripts/run-test.sh` replaced with the kit's version (adds `realtime` mode and an optional timeout argument; logs now `logs/<name>_<fps>fps.log` or `_realtime.log`). Commit d24082b.
- **Archive.** `TEST-REPORT.md`, `SUBMISSION.md`, `HUMAN-CHECK-NOTES.md`, `A5-LOG.md` moved with `git mv` to `docs/archive/*-a5.md` (content unchanged; new A6 versions are written later). Commit e901213.
- **Import.** `--headless --path godot --import`: exit 0, no ERROR lines.

Baseline (run by Claude Code through the wrapper, each in its pinned mode, at e901213):

| Suite | Mode | Result | A5 report (docs/archive/TEST-REPORT-a5.md) |
|---|---|---|---|
| game3d_smoke_test.tscn | 60 | exit 0, 27 ok, 0 FAIL | 27 ok |
| game3d_soak_test.tscn | 60 | exit 0, PASS (227 shots, 173 zombie hits, died at 133 s) | PASS |
| showcase_3d_test.tscn | 60 | exit 0, 3 ok, 0 FAIL | 3 ok |
| trigger_count_test.tscn | 60 | exit 0, 7 ok, 0 FAIL | 7 ok |
| low_ammo_test.gd | 30 / 60 / 144 | exit 0, 35 PASS each, 0 FAIL | 35 PASS each |
| test_materials.gd | 60 | exit 0, 74 PASS, 0 FAIL | 74 PASS |
| calibrate_normal_map_check.gd | 60 | exit 0, PASS | PASS |

No log contains SHADER ERROR or SCRIPT ERROR. The `ObjectDB instances were leaked` / `resources still in use at exit` lines at exit are present in the baseline too.

## Phase 1: the brief (2026-11-08)

- `CHANGE-BRIEF.md` copied from the kit unedited and committed alone (b23093e) before anything was built.
- Reference check: dated revision d339a95. Line references correct; the hit is resolved at `player.gd:264`; window 1280 × 720; every ClassDB name the brief uses exists in 4.7.2 (probe run headless with `ClassDB.class_get_property_list`).
- **Decision: "a bullet hit" = a bullet hitting a victim** (a collider with `hit()`: zombie, barrel, crate), so the emit goes in the `has_method("hit")` branch. Wall/floor hits keep their existing A5-era `Fx.sparks` and fire no burst. Reason: the brief defines the event through victims (`player.gd:5-6`), and wall hits already have a hit cue.
- Corrections recorded: barrel-blast victims are hit from `barrel.gd`, not through `fire()`, so they fire no bursts and the pool can only be exhausted by emitting more often than fire allows. In 4.7.2, `initial_velocity` and `scale` are existing Vector2 range properties, not missing Godot 3 names.

## Phase 2: CLAUDE.md

- No `AGENTS.md` exists, so there is no `@AGENTS.md` line. Draft committed unedited (a4240a6, 67 lines). Review: every reference re-checked (project.godot:15/:25-28/:91, game.gd:42-54/:81, player.gd:5-6/:8/:23/:27/:36/:241/:257/:264/:266/:297/:315/:327, pickup.gd:72, fx.gd:100, barrel.gd:104-106). Corrections committed separately (9760844): missing line refs, the existing `Fx.sparks` and barrel-blast path, the game.gd wiring precedent, `cost_effects.gd` being new (the runbook says "adapt"; no such file exists at `a5`), and the headless particle claims marked as stated-to-be-checked rather than observed.

## Phase 3: Effect A build, configuration test, preview, strip, mutations

- `godot/effects/impact_burst.tscn`: Node3D root with Flash, Sparks and Puff `GPUParticles3D`, every value from the table, written in the scene file. `emitting = false` in the file (nothing at load). Soft dot: one `GradientTexture2D` (radial, 64 px, white to transparent) shared by the three draw materials.
- `test_impact_burst_config.gd`: 105 checks (3 structure + 34 per emitter), exit 0 at 60 fps (1435dd5).
- **Preview decision:** one script, `godot/previews/effect_preview.gd`, and two scenes. `impact_burst_preview.tscn` is **dark** (Assembly Hall, player at (28, 10.5) aiming into the (31.5, 13.5) corner; the burst sits in the flashlight pool). `impact_burst_preview_light.tscn` is **light** (Loading Bay floor under the non-flickering shadowed lamp at (-3, 7)). The real game scene is loaded: level, environment (glow on), camera rig at its in-game offset (0, 14.5, 6.5), fov 45 → 55–60 px per metre at the effect. Waves are off, zombies removed, controls frozen, and the **HUD layer hidden** (its intro banner covers the centre). The burst sits 2.5 m along the aim at shot height 0.95 m, +Y facing back along the shot: where a zombie hit would land. No zombie is in the fixture.
- **"Triggered at frame 10 and again at the frame the brief gives":** the brief gives only frame 10, so the strip fires once. The script has `second_trigger_frame` (off) and `-- --repeat=N` for a held-trigger capture.
- Seeds: `use_fixed_seed = true`, `seed = 12345` set on the preview instance's emitters at run time, never in the effect scene.
- **Captures (fixture, run by Claude Code):** the runbook's command (`--write-movie <abs>/captures/impact_burst/r0/frame.png --fixed-fps 30 --quit-after 60`), plus the light scene into `r0-light/`. Kept frames 10, 12, 15, 20, 30, 50 **and 11**. Deviation, on purpose: frame 11 is the first frame with any particle drawn (the trigger frame 10 shows nothing). The `frame.wav` Movie Maker writes beside the PNGs was deleted and never committed.
- **Finding:** a windowed probe (`godot/tools/probe_particle_scale.gd`) showed that billboard particles ignore the process material's scale unless `billboard_keep_scale` is true. Brief revision d86b319; first reading in TUNING.md. A glow-off diagnostic capture first ruled out bloom as the cause of the oversized sparks (not committed).
- **Mutation (a)** (Sparks `initial_velocity_min = 3.0` renamed to the Godot 3 `initial_velocity = 3.0`): config test **exit 1**, `FAIL Sparks initial_velocity_min = 3.0 (got 0.0)`. The load printed no warning: the float went to the 4.7.2 Vector2 property `initial_velocity` and was dropped silently, so `initial_velocity_min` kept its default 0.0 (max 6.0 unaffected). The preview still fires (`frame 10: burst fired`). In the strip (`docs/evidence/a6/mutation_a_strip.png`) the flash and puff are unchanged, and at frame 15 several sparks are still at the centre: the slow sparks the 0.0 minimum allows. Logs: `docs/evidence/a6/mutation_a_godot3_name.log`, `mutation_a_preview.log`.
- **Mutation (b)** (Puff `initial_velocity_min` 0.6 → 0.9 in the scene, brief unchanged): **exit 1**, `FAIL Puff initial_velocity_min = 0.6 (got 0.89999997615814)`. Log `docs/evidence/a6/mutation_b_value.log`.
- Restored with `git checkout`; config test exit 0, 105 PASS (`mutation_restored.log`). `git diff --stat godot/shaders/`: empty.

## Phase 4: Effect A wiring and state test

**Plan (written before any code):**
1. `player.gd`: add `signal bullet_hit(point: Vector3, normal: Vector3)` beside the other signals, and one line `bullet_hit.emit(end, hit.normal)` inside the `has_method("hit")` branch of `fire()`, **before** `target_node.hit(...)`. Emitting first means the burst is placed even if `hit()` frees the victim. No other gameplay line changes.
2. `godot/game3d/impact_fx.gd` (presentation only): `attach(level, player)` builds a pool of 12 `impact_burst` instances as children of the level root and connects `bullet_hit`. On a hit it takes the next free instance: free means none of its three emitters reports `emitting` (a one-shot emitter clears `emitting` itself when done). It places the instance at `point`, sets its basis so local +Y = `normal`, and calls `restart()` on the three emitters. If none is free, it restarts the oldest (fire order is kept). It counts fires for tests and never writes game state.
3. `game.gd`: one preload, one var and one `attach` call after `hud.attach_low_ammo(player)`, following the A5 precedent. Presentation wiring, not gameplay.
4. `test_impact_burst_state.gd` (extends SceneTree, 60 fps): real game scene, waves off. Aim with a real `InputEventMouseMotion` at the target's screen position (`Input.parse_input_event`); fire with `Input.action_press("fire")`. Cases: nothing at load (30 frames); a shot into a wall (no victim) fires nothing; one shot into a zombie fires exactly one burst at the signal's point, on the zombie, with +Y = normal; two hits 0.14 s apart give two live bursts; the killing hit, with the zombie freed by the test on that frame, does not stop its burst; held fire gives at most 5 alive at once; pool exhausted (13 `bullet_hit` emits in one frame, synthetic and stated) restarts the oldest.
