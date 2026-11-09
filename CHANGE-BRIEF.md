# CHANGE-BRIEF.md — Assignment 6: two particle effects for DERELICT

Game: DERELICT, a top-down 3D zombie shooter (Godot 4.7.2, Forward+). This file replaces the Assignment 5 brief, which stays in history at tag `a5`. Written by Claude; the student accepted the two effects below by running this kit. It is committed before the first Claude Code build prompt. Dated revisions go at the bottom; the text above them stays as committed. References marked (verify) are checked by Claude Code in Phase 1 and corrected by a dated revision, never by editing this text.

## Effect A — Impact burst (one-shot, repeating event)

### The job
Tells the player that a bullet landed, where, and on what. The player fires several shots a second into a dark room; without a visible hit, a miss and a hit feel the same.
Event: a bullet hit. Victims implement `hit(damage, point, dir, normal)` (`godot/game3d/player.gd:5-6`); the bullet's hit is resolved in player.gd's fire path (line: verify). Fire interval is 0.14 s (`FIRE_INTERVAL`, A5 capture log), so a second hit regularly lands while the first burst is alive.

### Intent block
- **Timing phases:** 0–0.07 s a strong white-yellow flash on the first frame; 0.07–0.35 s sparks fly outward fast; 0.2–0.6 s a dark puff expands slowly and fades. Gone before 1.3 s. A held trigger must read as a stream of separate bursts, never one smeared cloud.
- **Contrast:** value, not hue. Sparks are additive and bright, so they read over the darkest stretch (Assembly Hall corners lit only by the flashlight); the puff is dark and alpha-blended, so it reads over the lightest stretch (floor under a lamp or the red emergency light, wet or dry). Neither is judged over the editor's grey.
- **Scale against the character:** the player is about 1.7 m tall. The flash is about 0.3 m across (an adult's head), sparks 4–6 cm, the puff 0.3–0.5 m. Judged in the running game at the project window size (verify in `project.godot`).
- **Change over life:** flash shrinks to 30 % and fades; sparks go orange to red and fade; puff grows to about 3× and fades from 60 % alpha.
- **Variation:** random velocity, scale and lifetime on every emitter; the sparks' lifetime varies by 30 %.
- **Emitters (one root, three jobs):** `Flash` (the instant of impact), `Sparks` (direction and energy), `Puff` (lingering mass and darkness).

### The settings (the configuration test reads every one back)
Node: three `GPUParticles3D` under one `Node3D` root, `godot/effects/impact_burst.tscn`. GPU, because the effect needs per-particle curves and gravity at no CPU cost; 3D, because the game is 3D. Process material: `ParticleProcessMaterial`. Godot 4 names only.

| | Flash | Sparks | Puff |
|---|---|---|---|
| amount | 2 | 14 | 8 |
| one_shot | true | true | true |
| explosiveness | 1.0 | 1.0 | 0.9 |
| lifetime (s) | 0.08 | 0.45, lifetime_randomness 0.3 | 0.6 |
| emission_shape | point | point | point |
| direction / spread | (0,1,0) / 180 | (0,1,0) / 55 | (0,1,0) / 70 |
| initial_velocity min / max (m/s) | 0 / 0 | 3.0 / 6.0 | 0.6 / 1.4 |
| gravity (m/s²) | (0,0,0) | (0,-9.8,0) | (0,0.4,0) |
| damping min / max | 0 / 0 | 0.5 / 1.5 | 2.5 / 4.0 |
| scale min / max | 0.8 / 1.2 | 0.03 / 0.06 (on a 1.0 m quad base: draw mesh size below) | 0.15 / 0.3 |
| scale curve | 1.0 → 0.3 | none | 0.5 → 1.6 (a 3.2× growth) |
| colour ramp | (1.0,0.95,0.8) | (1.0,0.7,0.2) → (1.0,0.25,0.06) | (0.23,0.06,0.04) |
| alpha curve | 1 → 0 | 1 → 0 | 0.6 → 0 |
| draw mesh | QuadMesh 0.3 m | QuadMesh 0.1 m | QuadMesh 0.5 m |
| draw material | StandardMaterial3D, unshaded, transparency alpha, blend add, billboard_mode particles, vertex_color_use_as_albedo true | same | same but blend mix |
| texture | radial soft-dot `GradientTexture2D` written in the scene (no external texture) | same | same |

All three: `local_coords` false (the burst stays where the bullet landed even if the victim moves or is freed); `preprocess` 0 (nothing should be running at load); `visibility_aabb` set, not generated, to position (-2,-1,-2) size (4,3,4) and checked by the configuration test.

### Observable rules
- **A1:** the effect fires once per hit the retrigger rule allows, never otherwise (including on scene load, and including shots that miss everything), at the hit `point`.
- **A2 retrigger = overlap:** each hit instances its own burst from a pool of 12 (`godot/game3d/impact_fx.gd`), so two hits 0.14 s apart give two live bursts. At most 5 are alive from continuous fire (ceil(0.6 / 0.14)); a barrel blast that hits several victims in one frame can use more, up to the pool's 12. If the pool is exhausted, the oldest burst is `restart()`ed (stated, tested).
- **A3 freed parent:** bursts are children of the level root, not of the victim, so a zombie freed on the killing hit does not cut its burst off.
- **A4:** the burst is oriented so its local +Y is the hit `normal`.
- Only permitted touch of gameplay code: one signal declaration and one `emit` line in player.gd at the point where a bullet hit is resolved. No behaviour changes; every earlier suite gives its baseline counts.

## Effect B — Wound smoke (feedback loop driven by a game value)

### The job
Feedback loop: the player's smouldering wounds. Tells the player how hurt they are without reading the health bar while watching the dark. Value: `player.hp`, range 0–`MAX_HP` = 100 (`player.gd:36`, `:23`), reported by `signal health_changed(hp, max_hp)` (`player.gd:8`).
Uses features Effect A doesn't: **turbulence** (process) and a **value-driven `amount_ratio`** (emission), with `local_coords` false so the smoke trails behind a moving player like a trail.

### Intent block
- **Timing phases:** when hp first drops to 60 or below, a few wisps appear within about 0.5 s and the cloud reaches its steady state within about 2 s (one lifetime). As hp falls the cloud thickens. When the condition ends (a medkit lifts hp above 60, or the player dies) the emitter stops and the existing smoke thins out over one lifetime (1.8 s).
- **Contrast:** dark grey smoke reads over lit floor and the flashlight cone; over the darkest corners it is meant to disappear (it is a close-range cue, and the health bar is still the exact number).
- **Scale against the character:** wisps start at about 0.2 m and grow to about 0.5 m, rising about a body height over their life; the cloud sits at the chest.
- **Change over life:** scale grows to about 3×, alpha 0.5 → 0, a slight grey-blue tint.
- **Variation:** random velocity and scale; turbulence stops the wisps rising in straight lines.
- **Emitter:** one `GPUParticles3D`, `godot/effects/wound_smoke.tscn`, child of the player at chest height.

### The settings
| | value |
|---|---|
| node | `GPUParticles3D` (GPU: turbulence exists only there) |
| amount | 40 (never changed at run time) |
| amount_ratio | driven, see mapping |
| one_shot / explosiveness | false / 0.0 |
| lifetime | 1.8 s |
| preprocess | 0.0. Nothing is running at scene load (full health); the 2 s ramp-up is the intended read |
| emission_shape | sphere, radius 0.15 |
| direction / spread | (0,1,0) / 25 |
| initial_velocity min / max | 0.4 / 0.8 m/s |
| gravity | (0,0.3,0): slight buoyancy |
| damping min / max | 0.3 / 0.6 |
| turbulence | enabled, noise strength 0.6 (exact property names: verify against the 4.7.2 class reference) |
| scale min / max, scale curve | 0.2 / 0.35, growth 0.6 → 1.8 |
| colour ramp, alpha | (0.18,0.18,0.20); alpha curve 0.5 → 0 |
| draw | QuadMesh 0.5 m, StandardMaterial3D unshaded, transparency alpha, blend mix, billboard_mode particles, vertex_color_use_as_albedo true, radial soft-dot texture |
| local_coords | false |
| visibility_aabb | set (-3,-1,-3) size (6,5,6), checked |

Mapping: condition is `hp <= 60` and the player alive. Then `emitting = true` and `amount_ratio = clamp((60 - hp) / 50, 0.2, 1.0)`: 0.2 at hp 60, 1.0 at hp 10 or below. Otherwise `emitting = false`. `amount` is never written (changing it reallocates the buffer and the smoke would vanish and re-emit).

### Observable rules
- **B1:** starts when hp falls to 60 or below, stops (`emitting` false) when hp rises above 60 or the player dies.
- **B2:** the driver writes `amount_ratio` (at least two different hp values give two different ratios) and never `amount`.
- **B3 paused:** particles freeze in place and resume on unpause (the node is pausable).
- **B4 hidden:** while `visible` is false nothing is drawn; `emitting` and the mapping are unchanged (predicted; the test records what the node actually reports).
- **B5:** nothing is on screen on the first frames after the scene loads (full health), with preprocess 0.

## Boundaries
Collision, movement, input, the state machine and its timings, existing test expectations, the A5 shaders in `godot/shaders/`, and every other object stay unchanged, apart from the one signal in A's rules. Presentation code may read game state; it never writes it.

## Evidence split
| Rule | Checked by |
|---|---|
| every setting in both tables | headless configuration tests (`test_impact_burst_config.gd`, `test_wound_smoke_config.gd`) |
| A1, A2, A3, A4 | headless state test through real fire input; the retrigger with two hits inside one lifetime |
| B1, B2, B3, B4, B5 | headless state test through real health changes (damage via enemy contact, medkit) |
| the look of both effects (timing phases, contrast, scale, change over life) | frame strips from a windowed Movie Maker run (fixture) read by Claude; **the student's own verdict in the running game** |
| edge of screen, scene load, dark and light backgrounds | the student's eyes in the running game |
| price | cost script (headless CPU), GPU time (see Price) |

## The frame strip
Preview scenes `godot/previews/impact_burst_preview.tscn` and `wound_smoke_preview.tscn` hold the effect at in-game camera scale over a real stretch of the level (the darkest and the lightest are both captured).
- **Effect A** at 30 fps, trigger at frame 10; read frames 10, 12, 15, 20, 30, 50: flash on the trigger frame; at +2 flash fading and sparks leaving; +5 sparks mid-flight; +10 sparks dying, puff at its widest; +20 puff almost gone; +40 nothing.
- **Effect B**: condition begins at frame 10, ends at frame 130; read frames 10 (nothing), 40 (first wisps), 100 (steady), 130 (stopped), 160 (thinning), 190 (gone).
Seeds: if the node has `use_fixed_seed`, use it on the preview instance only, never in the effect scene.

## Predicted failures, each with its check
1. **Godot 3 property names** (`ParticlesMaterial`, `initial_velocity`, `scale`) load silently and leave defaults. Check: the configuration test reads back every setting; the Godot 3 name mutation must exit 1.
2. **Colour ramp has no effect** because the draw material lacks `vertex_color_use_as_albedo`, or the alpha fade has no transparency. Check: configuration test reads both flags; the strip shows colour and fade.
3. **Quads don't face the camera** (billboard mode missing). Check: configuration test; the strip.
4. **Dropped retrigger:** a single one-shot node ignores the second hit. Check: state test fires two hits inside one lifetime and counts two live bursts.
5. **Burst dies with a freed victim.** Check: state test kills a zombie on the hit and asserts the burst is still emitting.
6. **Visibility box too small:** the effect pops out at the screen edge. Check: configuration test reads the AABB; the student's edge-of-screen check.
7. **Popping feedback loop:** the driver changes `amount`. Check: state test asserts `amount` is unchanged and `amount_ratio` moves.
8. **The cost script measures itself.** Check: the empty-scene control, and cases that should differ must differ.

## Price predictions and budgets
| | peak particles | predicted headless CPU (above the empty-scene control) | predicted GPU time | budget | compared on |
|---|---|---|---|---|---|
| Effect A | typical 5 bursts × 24 = 120; worst 12 × 24 = 288 | under 0.05 ms | 0.05–0.15 ms | 0.30 ms at 288 particles | GPU time |
| Effect B | 40 at amount_ratio 1.0 | under 0.05 ms | 0.03–0.10 ms | 0.20 ms | GPU time |
Both are GPU nodes, so their headless CPU price is near zero by construction and is reported, not compared. Measured on the student's GPU (named in TEST-REPORT.md).

## Brief answers
1. **Node type and what it lacks:** both `GPUParticles3D`. Effect A has no turbulence and nothing value-driven; Effect B has no burst or one-shot behaviour. (Property availability checked against the 4.7.2 class reference.)
2. **A's `local_coords` is false:** if A's parent moves after the event, the burst stays where the bullet hit; if it is freed, nothing changes.
3. **Overlap, peak:** 5 bursts alive from continuous fire, so 120 particles; up to 12 bursts and 288 particles in the worst blast case.
4. **Headless GPU price:** about the same as the empty-scene control, because the dummy renderer runs no GPU particle process. With vsync on, FPS reads the display's refresh rate with the effect off and on, until a frame misses, so FPS hides the cost.
5. **B on load and when paused or hidden:** nothing at full health either way (preprocess would only matter if it were emitting at load). Paused: frozen, resumes in place. Hidden: not drawn, `emitting` unchanged.
6. **Emission:** amount, amount_ratio, one_shot, explosiveness, lifetime, emission_shape. **Process:** direction, spread, velocity, gravity, damping, turbulence, scale and alpha curves, colour ramp. **Draw:** mesh, texture, material, blend mode, billboard mode, vertex colour, transparency.

## Revisions
(Dated entries below. The text above stays as committed.)

### 2026-11-08 — reference check (Claude Code, Phase 1)

Checked against b23093e (= tag `a5` content for every game file) and against the Godot 4.7.2 binary (`ClassDB.class_get_property_list`, probe run headless, "4.7.2-stable (official)"):

- Correct as written: `player.gd:5-6` is the doc comment `hit(damage: float, point: Vector3, dir: Vector3, normal: Vector3)`; `:8` is `signal health_changed(hp: float, max_hp: float)`; `:23` is `const MAX_HP := 100.0`; `:36` is `var hp := MAX_HP`; `FIRE_INTERVAL := 0.14` is `player.gd:27`.
- **(verify) where the hit is resolved:** `fire()` (`player.gd:241`) casts the shot ray at `:257` (`intersect_ray`, mask `Phys.SHOT_MASK` = WORLD | ZOMBIE | PROP). If it hits a collider with `hit()` (zombie, barrel, crate), `:264` calls `target_node.hit(DAMAGE, end, dir, hit.normal)` with `end = hit.position` (`:259`). Any other collider (walls, floor) gets the existing `Fx.sparks(end, hit.normal)` at `:266`. A ray that hits nothing does nothing. The signal is emitted in the `has_method("hit")` branch, so **"a bullet hit" means a bullet hitting a victim** (zombie, barrel or crate). Wall hits keep their existing A5 sparks and fire no burst (they are not victims). Decision logged in A6-LOG.md.
- **(verify) window size:** `project.godot:25-28`: 1280 × 720, stretch mode `canvas_items`, aspect `expand`.
- **(verify) class names:** `GPUParticles3D` has `amount_ratio`, `use_fixed_seed` (+ `seed`), `visibility_aabb`, `local_coords`, `preprocess`, `one_shot`, `explosiveness`, `restart(keep_seed)`. `ParticleProcessMaterial` has `lifetime_randomness`, `emission_shape`, `emission_sphere_radius`, `direction`, `spread`, `initial_velocity_min/max`, `gravity`, `damping_min/max`, `scale_min/max`, `scale_curve`, `color_ramp`, `alpha_curve`, and turbulence as `turbulence_enabled` and `turbulence_noise_strength` (also `turbulence_noise_scale`, `turbulence_noise_speed`, `turbulence_influence_min/max`, left at defaults). `StandardMaterial3D` has `shading_mode`, `transparency`, `blend_mode`, `billboard_mode`, `vertex_color_use_as_albedo`; `GradientTexture2D` has `fill`, `fill_from`, `fill_to`.
- **Correction, A2 (barrel blast):** a barrel blast hits its victims from `barrel.gd:104` / `:106`, not through player.gd's fire path, and each shot hits at most one victim. With the one-signal rule, the blast fires no impact bursts. In play the pool can only fill from continuous fire (at most 5 alive), so the pool-exhausted rule is reachable only by emitting `bullet_hit` more often than fire allows. The state test does that, and says so.
- **Correction, predicted failure 1:** in 4.7.2 `initial_velocity` and `scale` are **not** missing Godot 3 names. They exist on `ParticleProcessMaterial` as `Vector2` (min, max) range properties (type 5). The rename mutation (Phase 3) records what a float written to `initial_velocity` actually does. `ParticlesMaterial` (the Godot 3 class) does not exist in 4.7.2.
- `FIRE_INTERVAL` is a constant in `player.gd:27`, not only in the A5 capture log.

### 2026-11-08: particle scale is ignored by billboard particles (Claude Code, Phase 3)

Observed with `godot/tools/probe_particle_scale.gd` (windowed, Godot 4.7.2, RTX 4050; log `docs/evidence/a6/probe_particle_scale.log`): with `billboard_mode = particles` and `billboard_keep_scale = false` (the default), a particle draws at its QuadMesh size and the `ParticleProcessMaterial` scale (`scale_min/max`, `scale_curve`) has **no visible effect**. With `billboard_keep_scale = true` the scale applies. The table above does not name `billboard_keep_scale`. So the scene built exactly to the table passes its configuration test, yet its scale rows do nothing on screen: the flash does not shrink, the puff does not grow, and sparks draw at 0.1 m. The r0 strip shows exactly this (TUNING.md). This is a ninth predicted-failure-style case: a setting that loads and reads back correctly but is silently ineffective. Changes to the draw materials go through the tuning loop, one setting per revision.

Also from the r0 strip: the first particles are drawn one frame after `restart()` (trigger frame 10, first visible frame 11), so the strip's "flash on the trigger frame" reads as "flash on trigger + 1".

### 2026-11-08: tuning A-r1 (approved by Claude, pre-authorised in A6-RUNBOOK.md; applied by Claude Code)

Effect A settings table, Puff column, draw material: add **`billboard_keep_scale` true**, so the scale row (0.15 / 0.3) and the scale curve (0.5 → 1.6) take effect (see the revision above). Flash and Sparks keep the default (false). The configuration test now reads `billboard_keep_scale` on all three. Prediction, strips and comparison: TUNING.md, A-r1.

### 2026-11-08: tuning A-r1 reverted (Claude Code)

The r1 strips (TUNING.md) show the puff growing but at most ~0.07 m wide, specks over the light floor, further from the intent than r0. The Puff draw material is back to `billboard_keep_scale` false (the default), so the table above stands as committed. The configuration test keeps reading the flag (expected false on all three). A combined change (keep_scale true **and** Puff scale 0.5 / 0.9) is recorded in TUNING.md as a proposal awaiting approval.

### 2026-11-08: tuning B-r1 (approved by Claude, pre-authorised in A6-RUNBOOK.md; applied by Claude Code)

Effect B settings table, direction / spread: spread **25 → 70**. Reason: in the r0 strip the smoke rises toward the near-vertical camera and never leaves the player's silhouette, so it does not read over the lit floor. Prediction, strips and comparison: TUNING.md, B-r1.
