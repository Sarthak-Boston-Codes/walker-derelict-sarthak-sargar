# TEST-REPORT.md: DERELICT, Assignment 6 (two particle effects)

Authorship: the effects, previews, trigger code, tests, cost and GPU scripts, strip readings and this report were written by Claude Code. The brief, its predictions, budgets and answers, the tuning approvals and the process-shader notes (marked below) were written by Claude. Every result here was run by Claude Code; strip readings are labelled "read by Claude". Nothing here is a check performed by the student. Those rows say **pending: not yet performed by the student** and live in `HUMAN-CHECK-NOTES.md`. The A5 report is archived at `docs/archive/TEST-REPORT-a5.md`.

- **Source revision:** game and effect source as of `f4af1c4` (tuning B-r2; no file under `godot/effects`, `godot/game3d` or `godot/previews` changed after it). Final test run at `ab3cbe7` (later commits are documents only). Logs: `docs/evidence/a6/final/`.
- **Godot:** 4.7.2.stable.official.ed1daf0bf, Windows 11.
- **Renderer:** Forward+ (`project.godot` has no `rendering_method`; features list "Forward Plus"; windowed runs print `D3D12 12_0 - Forward+ - Using Device #0: NVIDIA - NVIDIA GeForce RTX 4050 Laptop GPU`). Headless runs use the dummy renderer: they parse shaders but draw nothing and simulate no particles.
- **GPU:** NVIDIA GeForce RTX 4050 Laptop GPU (`RenderingServer.get_video_adapter_name()`), screen refresh 144 Hz.
- **Runner:** every test through `scripts/run-test.sh <test> <fps|realtime> [timeout]` (fails on SHADER ERROR / SCRIPT ERROR). None of the A6 tests awaits audio, so all run at a pinned 60 fps.

## Results table

| Rule / check | Checked by | Result |
|---|---|---|
| Effect A settings (every row of the table, plus `visibility_aabb`, `local_coords`, `preprocess`, `emitting` at load, `billboard_keep_scale`) | `test_impact_burst_config.gd` @60 | exit 0, **108 PASS**, 0 FAIL |
| Effect B settings (incl. turbulence enabled, noise strength 0.6, influence 0.03 after B-r2, spread 70 after B-r1) | `test_wound_smoke_config.gd` @60 | exit 0, **39 PASS**, 0 FAIL |
| A1 fires once per hit, never on load or on a shot that hits no victim, at the hit point | `test_impact_burst_state.gd` @60, real mouse aim + real fire | PASS: 0 bursts in the first 42 frames; a wall shot → 0; one zombie hit → exactly 1 burst at the signal's point, on the zombie's capsule; held fire 2 s: one burst per hit (final run 14 shots, 10 hits, 10 bursts) |
| A2 overlap: two hits inside one lifetime → two live bursts | same | PASS: hits 9 frames (0.150 s) apart → 2 live; node truth: the first burst's Puff had not reported `finished` |
| A2 continuous fire ≤ 5 alive | same | PASS: peak 5 in the final run (3 and 4 in earlier runs; spread is random) |
| A2 pool exhausted → oldest restarted | same, **13 synthetic `bullet_hit` emits in one frame** (fire cannot fill the pool) | PASS: the oldest (index 0) restarted at the 13th point |
| A3 freed victim does not cut the burst | same, the killed zombie freed by the test on the killing frame | PASS: burst still under the level root 10 frames later; its Puff finished 40 frames after the hit |
| A4 +Y = hit normal | same | PASS: `global_basis.y` equals the normal |
| B1 starts at hp ≤ 60, stops above 60 and on death | `test_wound_smoke_state.gd` @60, real zombie swipes (18 hp) and a real medkit (+40) | PASS: 82/64 off; 46 on; medkit 28 → 68 off; 50 on; death → off |
| B2 `amount_ratio` driven (≥ 2 values), `amount` never written | same + driver source scan | PASS: 46 → 0.28, 28 → 0.64, 50 → 0.20, 32 → 0.56; `amount` 40 on every one of 2534 frames |
| B3 paused | same, the game's own `set_paused(true)` | Node reports: `can_process()` true → **false**, `emitting` true, `amount_ratio` 0.20, `speed_scale` 1.00 unchanged; on unpause processing resumes with the same values. **Not provable headless:** that the particles visibly freeze and resume in place. |
| B4 hidden | same, test sets `visible = false` | Node reports: `is_visible_in_tree()` false, `emitting` true; the mapping still follows hp (32 → 0.56). Nothing drawn: not provable headless. |
| B5 nothing at scene load (full health, preprocess 0) | same | PASS: `emitting` false for the first 32 frames, preprocess 0.0 |
| Effect A mutation (a): Sparks `initial_velocity_min` → Godot 3 `initial_velocity` | config test | **exit 1**: `initial_velocity_min = 3.0 (got 0.0)`. No load warning: the float went to 4.7.2's Vector2 `initial_velocity` and was dropped. The preview still fires; slow sparks linger at the centre (`docs/evidence/a6/mutation_a_strip.png`) |
| Effect A mutation (b): Puff `initial_velocity_min` 0.6 → 0.9 in the scene only | config test | **exit 1** |
| Effect B mutations: the same Godot 3 rename; `turbulence_noise_strength` 0.6 → 1.2 | config test | **exit 1** each; restored 37 PASS (before B-r1/B-r2) |
| The look of A (timing phases, contrast, scale, change over life) | frame strips, fixture, read by Claude | see TUNING.md. Flash, sparks and puff appear and are gone by +20 frames. **A one-frame delay**: the trigger frame shows nothing, the first particles show on trigger + 1. Sizes do not change over life (billboard particles ignore process scale without `billboard_keep_scale`, `godot/tools/probe_particle_scale.gd`). The puff is red-brown rather than dark. |
| The look of B | frame strips + diffs against a no-smoke control run, read by Claude | see TUNING.md. Timing right (wisps by +0.5 s after B-r2, gone within one lifetime of the stop). In the stationary fixture the cloud stays mostly over the player's silhouette and reads lighter, not darker. |
| Every tuning revision: the student's verdict in the running game | the student | **pending: not yet performed by the student** (A-r1, B-r1, B-r2) |
| Claude's strip readings against the student's own view | the student | **pending: not yet performed by the student** |
| Edge of screen, scene load, dark and light backgrounds, rapid repeats in play, B start/stop/pause/hide in play, size at 1280 × 720 | the student | **pending: not yet performed by the student** |
| Headless CPU price | `cost_effects.gd` @60, timeout 300 | see Price |
| GPU price | `godot/tools/gpu_price.gd`, windowed | see Price |
| Visual Profiler read | the student | **pending: not yet performed by the student** |

## Earlier suites (baseline at e901213, before any A6 change; final at ab3cbe7)

| Suite | Baseline | Final |
|---|---|---|
| game3d_smoke_test.tscn @60 | exit 0, 27 ok | exit 0, 27 ok |
| game3d_soak_test.tscn @60 | exit 0, PASS | exit 0, PASS (bot run is random: 170 shots, died at 112 s) |
| showcase_3d_test.tscn @60 | exit 0, 3 ok | exit 0, 3 ok |
| trigger_count_test.tscn @60 | exit 0, 7 ok | exit 0, 7 ok |
| low_ammo_test.gd @30 / 60 / 144 | exit 0, 35 PASS each | exit 0, 35 PASS each |
| test_materials.gd @60 | exit 0, 74 PASS | exit 0, 74 PASS |
| calibrate_normal_map_check.gd @60 | exit 0, PASS | exit 0, PASS |

No log contains SHADER ERROR or SCRIPT ERROR. `git diff --stat godot/shaders/` printed nothing after every phase. The only file added there is `particles_generated.gdshader`.

## Price

Both effects are `GPUParticles3D`: their simulation is a particle process shader on the GPU.

**Headless CPU** (`bash scripts/run-test.sh cost_effects.gd 60 300`; wall time between consecutive frames, 600 frames per case after 60 warm-up frames; final run):

| Case | Mean (ms) | sd | median | p95 |
|---|---|---|---|---|
| empty scene (control) | 0.0384 | 0.0173 | 0.038 | 0.045 |
| game, both effects off (measured first) | 0.5438 | 0.4281 | 0.386 | 1.679 |
| Effect A worst (12 bursts alive, 288 particles) | 0.6416 | 0.8585 | 0.396 | 1.957 |
| Effect B at ratio 1.0 (40 particles) | 0.8818 | 0.7084 | 0.551 | 2.305 |
| game, both effects off (measured last) | 1.5274 | 1.2133 | 1.046 | 4.156 |

The two identical "off" cases differ by 0.98 ms in this run (0.35 ms in the run before), and A and B fall between them (−0.39 / −0.15 ms against their mean). **A GPU effect's headless price is near zero by construction:** the dummy renderer runs no particle process shader, so what is left is the effect nodes' CPU bookkeeping, which this measurement cannot separate from frame-to-frame drift. It is reported, not compared with a budget. The script is not just measuring itself: the control is ~14× below the game in the final run (~90× in the run before), and the script checks this and prints PASS. `Performance.TIME_PROCESS` was tried and dropped: headless it read 720 ms with sd 0.

**GPU** (script reading the RenderingServer GPU counter, run by Claude Code: `godot/tools/gpu_price.gd`, windowed 1280 × 720, vsync disabled by the script; 600 frames per case after 120 warm-up frames; log `docs/evidence/a6/gpu_price.log`):

| | Peak particles | Predicted headless CPU | Measured headless CPU | Predicted GPU | **Measured GPU** (over the mean of two "off" runs) | Budget | Within budget? |
|---|---|---|---|---|---|---|---|
| Effect A | 288 (12 bursts) | < 0.05 ms | not separable from drift (±0.4 ms) | 0.05–0.15 ms | **+0.018 ms** (1.1704 vs 1.1599 / 1.1446) | 0.30 ms | yes |
| Effect B | 40 (ratio 1.0) | < 0.05 ms | not separable from drift | 0.03–0.10 ms | **+0.023 ms** (1.1752) | 0.20 ms | yes |

FPS was 323–439 against a 144 Hz display, so the measurement is not capped by vsync. The two "off" runs differ by 0.015 ms GPU, about the size of the effects themselves: both effects are at the noise floor of this counter, below the brief's predictions and far inside the budgets. The student's own Visual Profiler read is **pending: not yet performed by the student**.

## The process shader

`godot/shaders/particles_generated.gdshader` was generated by Godot 4.7.2 from a unique duplicate (`duplicate(true)`) of the Puff emitter's `ParticleProcessMaterial`. It was saved by `godot/tools/dump_particles_shader.gd` (RID scan with `RenderingServer.shader_get_code`); nothing uses it. Line numbers were verified by re-reading the file (`sed -n <n>p`) after it was written.

| What | Line(s) |
|---|---|
| `shader_type particles;` | 3 |
| `void start()` | 221 |
| `void process()` | 271 |
| initial velocity from its minimum and maximum | uniforms at 10–11; `params.initial_velocity_multiplier = mix(initial_linear_velocity_min, initial_linear_velocity_max, rand_from_seed(alt_seed));` at **140**; applied to the spread direction at **260** |
| gravity changes velocity | `force = gravity;` at **304**, then `USERDATA1.xyz += force * DELTA;` at **317** (USERDATA1 holds the velocity; position moves by it at 336) |
| colour over life sampled | `parameters.color *= texture(color_ramp, vec2(lifetime));` at **162** (alpha curve at 163), called from `process()` at 338 and written to `COLOR` at 343 |
| scale over life applied | `parameters.scale *= texture(scale_curve, vec2(lifetime)).rgb;` at **161**; written into the particle's `TRANSFORM` basis at **358–360** |
| a line tied to a brief setting | **132**: `params.damping = mix(damping_min, damping_max, rand_from_seed(alt_seed));` = Puff damping min / max **2.5 / 4.0** (applied as `v -= physics_params.damping * DELTA;` at 323) |

**Which settings live here and which in the draw step: written by Claude.**
In this process shader: direction and spread (`get_random_direction_from_spread`, 260), initial velocity (140), gravity (304/317), damping (132/323), scale min/max (150) and the scale curve (161), the colour ramp (162) and alpha curve (163), lifetime randomness (155). Two emission settings also live here: emission shape (`calculate_initial_position`, 254), and **`amount_ratio`**, read in `start()` at **233** (`if (rand_from_seed(alt_seed) > AMOUNT_RATIO) ACTIVE = false;`). That is why changing the ratio never reallocates the buffer: it only deactivates particles at birth. Turbulence would be here too; the Puff has none, so this file has no turbulence code.
On the node, not in either shader: amount, lifetime, one_shot, explosiveness, preprocess, local_coords, visibility_aabb (they set how many particles, how often and in which space the process shader runs).
In the draw step (the `StandardMaterial3D` and its QuadMesh): mesh size, texture, unshaded, transparency, blend mode, `billboard_mode`, `vertex_color_use_as_albedo` (which lets the `COLOR` written at 343 reach the screen), and `billboard_keep_scale`. The process shader writes the scale into `TRANSFORM` (358–360), but the billboard draw step throws that scale away unless `billboard_keep_scale` is true. That is the Effect A finding in TUNING.md.

## Limits: what no headless run here can show

- Anything visual: the dummy renderer draws nothing and runs no particle process shader. Positions, sizes, colours, fades and whether particles freeze on pause come only from windowed captures (fixture strips) and the student's eyes.
- The impact burst's lifetime in the state test is node bookkeeping (each emitter's `finished` signal and ImpactFx's own clock), not observed particles.
- A one-shot `GPUParticles3D` reports `emitting = false` once its emission ends (2 frames for an explosive burst), not when its particles die; tests that used `emitting` as "alive" were wrong and were changed.
- A shot that hits nothing at all cannot happen in the closed level; the wall shot stands in for a miss. Barrel blasts never go through `fire()`, so they fire no burst.
- The pool-exhausted rule is tested with synthetic emits, because continuous fire peaks at 3–5 bursts.
- Strips are fixtures: player parked, no zombie, HUD hidden, fixed seed, glow and lamp flicker as in the game. The wound smoke is shown stationary (the worst case for its trail).
- The headless CPU price cannot resolve the effects from frame-to-frame drift; the GPU price is at the counter's noise floor.
