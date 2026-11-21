# TEST-REPORT.md: DERELICT, Assignment 7 (two animations)

Authorship: the sheet generator, clips, rig, `HudAnim`, tests, pins, previews, captures, strip readings and this report were written by Claude Code. The brief, its predictions, the phase table, the cycle spec and the approvals were written by Claude. Every result below was run by Claude Code; strip readings are labelled "read by Claude". Nothing here is a check the student performed. Those rows say **pending: not yet performed by the student**, and the student's checks live in `HUMAN-CHECK-NOTES.md`. The A6 report is archived at `docs/archive/TEST-REPORT-a6.md`.

- **Source revision:** game, clip and rig source as of `0d8710e` (tuning r2; later commits change tests, captures and documents, plus one `.uid` file). Final test run at `a48c684`. Logs: `docs/evidence/a7/final/`.
- **Godot:** 4.7.2.stable.official.ed1daf0bf, Windows 11 Home.
- **Renderer:** Forward+ (`project.godot:15`; no `rendering_method` line), D3D12, NVIDIA GeForce RTX 4050 Laptop GPU for windowed captures. Headless runs use the dummy renderer: clips advance and structure can be read, but nothing is drawn.
- **Runner:** every test through `scripts/run-test.sh <test> <fps|realtime> [timeout]`, which fails on SHADER ERROR, SCRIPT ERROR or Failed loading resource. No A7 test awaits audio, so all run at a pinned frame rate.
- **Counts:** "PASS lines" = `grep -c '^PASS'` on the log. This includes the final `PASS: 0 failure(s)` line, the same way the A6 counts were taken.

## Use It: results table

| Rule / check | Checked by | Result |
|---|---|---|
| Every track resolves to a real node and property (branched on track type) | `test_keycard_spin_readback.gd` @60, `test_pistol_reload_readback.gd` @60 | PASS: `track_problems` empty for `KeycardIcon:frame`, `Body:rotation`, `Body/Slide:position:x`, `Body/Mag:position:y` and RESET's three tracks |
| Spin: 8 keys at k/12, values 0–7, discrete, `LOOP_LINEAR`, step 1/12, length 8/12, keys inside the sheet, no duplicate across the wrap, last-key-to-length gap = key interval, sheet 8 cells of 64 × 64 | keycard read-back @60 | exit 0, **32 PASS lines**, 0 FAIL. Largest key-time error 2.0e-8 s; played headless the sprite shows 0…7, then 0 after the wrap |
| Reload: key times and values against the brief's table (within 1/48 s), easing per key, step 1/24, `LOOP_NONE`, length = `RELOAD_TIME` read from `player.gd` (1.25 s), RESET covers every keyed property | reload read-back @60 | exit 0, **57 PASS lines**, 0 FAIL. Key-time error 0; f21 expects −24 px since tuning r2 |
| States, transitions, clip per state, one authority, autoplay empty, PAUSABLE, PROCESS_IDLE, `current_animation` | `test_hud_anim_structure.gd` @60 | exit 0, **51 PASS lines**. Tables equal the brief's; exactly 2 AnimationPlayers in the HUD; source scan: only `hud_anim.gd` touches the rigs (game.gd only attaches it), and it writes no animated property and uses no tween; paused tree → neither player can process |
| HudAnim plays the right clip on the right state, through real input | `test_hud_anim_state.gd` @60: R / Escape key events and fire button events through `Input.parse_input_event`; death by a real shambler swipe; keycard by placing the player on it | exit 0, **34 PASS lines**. R → RELOAD, `current_animation` "reload"; the clip runs to 1.2167 s, then HOLD at the RESET pose; Escape mid-reload freezes the clip at 0.3333 s and `_reload_left` at 0.9000 s for 60 frames, and unpausing continues; death mid-reload → DEAD, clip stopped, pose (0, 0, 0) on the `died` signal; keycard → SPINNING, all 8 cells within 1.5 s |
| Pins: state order, FIRE_INTERVAL, RELOAD_TIME as the gap between the two signals, MAG_SIZE, refill at `reload_changed(false)`, fire locked | `test_pins_player.gd` @60, before wiring and after | exit 0, **19 PASS lines** both times, identical. Order READY, FIRE, RELOAD, READY, FIRE; shots 9 frames apart (0.15 s); reload 75 frames = 1.2500 s; refill 10 → 15 on the `reload_changed(false)` frame. **No pin changed**, as the brief predicted |
| Interrupts at each phase boundary (ticks 29–31, 59–61, 74–76): fire, second reload, death | `test_pistol_reload_edges.gd` @60 | exit 0, **98 PASS lines**. Fire ignored until the refill on tick 75 (a press on 75 fires on 75, after the refill); a second R never restarts the clip (position = (tick − 1)/60 exactly); death stops the clip and resets the pose on the same tick; tick 75 HOLD, and fire on tick 76 fires |
| The two clocks | `test_two_clocks.gd` @60 and @30, 5 reloads each | exit 0 both. The game ends the reload on tick 75 / 38, and an unstopped clip finishes on tick 76 / 39: **largest disagreement 0.0167 s at 60 fps, 0.0333 s at 30 fps, exactly one frame** on every reload. The brief predicted "under one frame": not met (brief revision 2026-11-20) |
| Mutation 1: a rig track's property renamed in the clip | reload read-back | **exit 1** (`Node2D has no property 'positon'`) |
| Mutation 2: spin `loop_mode` → LOOP_NONE | keycard read-back | **exit 1** |
| Mutation 3: one frame key → 8 | keycard read-back | **exit 1** (key outside the sheet; Godot prints `Index p_frame = 8 is out of bounds`) |
| Mutation 4: delete `godot/.godot`, reimport, re-run read-backs | both read-backs | **exit 0 / 0**, not a failure: the clips are `.tres` text and RESET lives in the scene, so a reimport rebuilds only the sheet's `.ctex`. Recorded in `docs/evidence/a7/mutations/README.md` |
| Phases read as distinct; the rig's look over dark and light floor | reload strips r0, r1, r2 (fixture captures, read by Claude) | Rest at 10, magazine out and gun tilted at 26, seated with the slide racked at 39–41, level at 48. r1 moved the rig up 80 px (the magazine had been clipped by the window); r2 deepened the rack (−14 → −24 px). Every listed frame matched its prediction; both kept. TUNING.md |
| The cycle has no visible seam; registration | keycard strips r0 light and dark (read by Claude) | 8 distinct cells in order; cell 7 → cell 0 with no repeat; bounding-box centre within 0.5 px across cells. TUNING.md |
| Every tuning revision: the student's verdict in the running game | the student | **pending: not yet performed by the student** (reload r0, r1, r2; keycard r0) |
| Claude's strip readings against the student's own view | the student | **pending: not yet performed by the student** |
| HUMAN CHECK: cycle seam over five wraps, the reload in play with an interrupt in each phase, keycard registration, both backgrounds | the student | **pending: not yet performed by the student** (`HUMAN-CHECK-NOTES.md`) |

## Earlier suites (baseline at a6d11e3 before any A7 change; final at a48c684)

| Suite | Baseline | Final |
|---|---|---|
| game3d_smoke_test.tscn @60 | exit 0, 27 ok | exit 0, 27 ok |
| game3d_soak_test.tscn @60 | exit 0, PASS | exit 0, PASS |
| showcase_3d_test.tscn @60 | exit 0, 3 rows ok | exit 0, 3 rows ok |
| trigger_count_test.tscn @60 | exit 0, 5 rows ok | exit 0, 5 rows ok |
| low_ammo_test.gd @30 / 60 / 144 | exit 0, 36 PASS lines each | exit 0, 36 each |
| test_materials.gd @60 | 75 | 75 |
| calibrate_normal_map_check.gd @60 | 1 | 1 |
| test_impact_burst_config.gd @60 | 109 | 109 |
| test_impact_burst_state.gd @60 | 35 (the first run after the fresh import failed its two-hit section and was re-run 3×: see Limits) | 35 |
| test_wound_smoke_config.gd @60 | 40 | 40 |
| test_wound_smoke_state.gd @60 | 22 | 22 |

No final log contains SHADER ERROR, SCRIPT ERROR or Failed loading resource. `git diff --stat godot/shaders/` printed nothing after every phase. The only edit to an existing game file is 4 added lines in `game.gd`; `hud.gd` and `player.gd` are unchanged.

## What no headless run can show

What either clip looks like, whether the reload's three phases feel distinct in play, whether the keycard catches the eye in peripheral vision, whether the cycle's seam is invisible over many wraps, and how the rig reads over the real level while moving. The strips are fixture evidence read by Claude, not the student's verdict.

## Limits

- Every human check and tuning verdict is pending: not yet performed by the student.
- The clip trails the game's reload timer by one frame (it holds position 0 on the tick after `play()`); HudAnim's RESET on `reload_changed(false)` replaces the clip's last frame. Gameplay timing is unaffected.
- The keycard icon is small (a 26 px card at 1280 × 720); whether it is noticeable is the student's check.
- Fixtures: the keycard pickup places the player on the card rather than walking there, and the edge test's deaths call the game's own `take_damage()` so they land on an exact tick. The state test's death is real zombie contact.
- `test_impact_burst_state.gd` (A6) failed once on the first run after a fresh import (one hit instead of two), then passed 3/3 and in every later run.
- The brief's sheet section put the back face on cells 4–7; the generator follows a turning card (back on 3–5) instead (brief revision 2026-11-20, sheet).
