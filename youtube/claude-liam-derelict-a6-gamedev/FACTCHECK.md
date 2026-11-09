# FACTCHECK: every claim in the narration, and where it comes from

Written by Claude Code. "Read by Claude" means Claude Code looked at a capture or strip; it is not the student's check.

| Beat | Claim | Source |
|---|---|---|
| B00 | Prompt in the composer | **Reconstruction**: no such prompt was typed. The student asked Claude Code to extract the A6 kit and execute `A6-RUNBOOK.md`; the composer shows a suggested Walker prompt. |
| B00 | top-down 3D zombie shooter, Godot | README.md |
| B01 | "Claude wrote the brief, and Claude Code wrote everything else, including this film" | SOURCES.md A6 section (the brief, predictions, budgets, approvals and process-shader notes: Claude; everything else: Claude Code) |
| B01 | "that person hasn't looked yet" | HUMAN-CHECK-NOTES.md: every row pending |
| B02 | `bullet_hit` emitted where fire resolves a hit on a zombie, barrel or crate | `godot/game3d/player.gd:14`, `:266`; CHANGE-BRIEF revision 2026-11-08 |
| B02 | sixty health or less; thickens as health falls | `wound_smoke_driver.gd:41`, `:45`; CHANGE-BRIEF mapping |
| B03 | emission / process / draw lines | `impact_burst.tscn:173-177`, `:98`, `:102`; `particles_generated.gdshader:304` |
| B03 | headless price near zero by construction | TEST-REPORT.md Price; `cost_effects.gd` output (effects not separable from drift) |
| B04 | 14 sparks, 55°, 3–6 m/s, gravity, damping, orange → red | `impact_burst.tscn:81-94`, `:173`; CHANGE-BRIEF table |
| B05 | flash one frame late; puff full size and never grows | `captures/impact_burst/r0*/strip.png`, read by Claude (TUNING.md); `logs/capture_impact_burst_r0.log` "burst fired (Engine frames drawn 10)" |
| B06 | emit before the victim's `hit()` | `player.gd:266-267` |
| B07 | real fire input; 16 hits → 16 bursts; up to four alive at once | `logs/film_capture_burstplay.log` (last line `shots 26 victim_hits 16 bursts_fired 16`; peak `bursts_alive 4` at frame 45); SCRIPTED PLAY (labelled) |
| B07 | puffs on top of the existing blood and hit flash | read by Claude on burstplay frames 36–52 of the first two-zombie take and the final take's B02 frame |
| B08 | pool of 12, oldest restarted, +Y = normal, restart ×3 | `impact_fx.gd:56-69`; `:16` POOL_SIZE |
| B09 | one hit one burst; nine frames apart two live; freed victim; thirteen fake signals | `docs/evidence/a6/final/test_impact_burst_state_60fps.log` |
| B10 | keep scale; predicted small dots; grew to ~7 cm; reverted; verdict pending | TUNING.md A-r1; commits 3f2e7d6, 446dad4, f6eeac4 |
| B11 | sphere 0.15, gravity +0.3, turbulence 0.6, influence 0.03 (tuning) | `wound_smoke.tscn:43`, `:46-59`; CHANGE-BRIEF revisions |
| B12 | 127 → 558 changed px (light, frame 100); wisps by +0.5 s; lighter than background | TUNING.md B-r1/B-r2 tables; diff images in `docs/evidence/a6/` |
| B13 | 0.2 at 60, 1 at 10; never writes amount | `wound_smoke_driver.gd:41-54`; state test source scan + `amount` 40 every frame |
| B14 | swipe to 46, smoke starts; trail; pause freezes; medkit to 86, stops | `logs/film_capture_smokeplay.log` (`FRAME 51 hp 46 emitting true ratio 0.28`, paused frames, `hp 86 emitting false`); "freezes" read by Claude on the paused frames |
| B15 | B-r1 failed; turbulence-off diagnostic; B-r2 mostly held | TUNING.md B-r1/B-r2 |
| B16 | lines 161, 162 are the scale curve and colour ramp | `particles_generated.gdshader:159-163` |
| B17 | 72 px vs 36 px | `docs/evidence/a6/probe_particle_scale.log` |
| B18 | every setting read back; Godot 3 rename → 0.0, still fires, only the test fails; ~0.02 ms GPU | config test logs; A6-LOG Phase 3 mutation (a); `docs/evidence/a6/gpu_price.log` (+0.0181 / +0.0229 ms) |
| B19 | emitting-as-alive mistake; ×20 mouse stretch; miscounted commit message | A6-LOG.md Phases 4 and 6 |
| B20 | who wrote what; no external textures | SOURCES.md A6 section |
| B21 | limits | README.md Known limitations |
| B22 | "twelve to twenty-three centimetres at birth, growing past forty" | 0.5 m quad × 0.5–0.9 × curve 0.5 = 0.125–0.225 m; × 1.6 at end = 0.4–0.72 m (TUNING.md A-r2 proposal). A prediction, not a result. |
