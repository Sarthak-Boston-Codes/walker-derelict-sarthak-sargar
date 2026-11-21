# A7-LOG.md — Assignment 7 (two animations), work log

Written by Claude Code while executing `A7-RUNBOOK.md` (written by Claude; kit extracted to `C:\Users\sarth\a7-kit`). Every approval below is Claude's, pre-authorised in A7-RUNBOOK.md. Nothing here is a student check; the student's checks live in `HUMAN-CHECK-NOTES.md` and read "pending" until the student gives them.

## Phase 0 — worktree, wrapper, baseline (2026-11-20)

- Worktree `C:\Users\sarth\Game Development\walker-a7`, branch `a7-animation`, clean at `020fc24` (top of `a6-effects`).
- Kit extracted from `C:\Users\sarth\Downloads\a7-kit.zip` to `C:\Users\sarth\a7-kit` (4 files: `A7-RUNBOOK.md`, `CHANGE-BRIEF.md`, `scripts/run-test.sh`).
- `scripts/run-test.sh` replaced with the kit's version (`f7b004f`). The only behavioural difference: a log line `Failed loading resource` now also fails the run.
- A6 `TEST-REPORT.md`, `SUBMISSION.md`, `HUMAN-CHECK-NOTES.md`, `TUNING.md`, `A6-LOG.md` moved to `docs/archive/*-a6.md` (`95a6326`).
- Import: `"$GODOT" --headless --path godot --import`, exit 0, 27 s.
- Baseline, every existing test through the wrapper in its pinned mode (logs copied to `docs/evidence/a7/baseline/`):

| test | mode | exit | count |
|---|---|---|---|
| game3d_smoke_test.tscn | 60 | 0 | `PASS: 0 failure(s)`, 27 `ok` lines |
| game3d_soak_test.tscn | 60 | 0 | PASS |
| showcase_3d_test.tscn | 60 | 0 | `PASS: 0 failure(s)`, 3 rows ok |
| trigger_count_test.tscn | 60 | 0 | `PASS: 0 failure(s)`, 5 rows ok |
| low_ammo_test.gd | 30 / 60 / 144 | 0 / 0 / 0 | 36 / 36 / 36 PASS, 0 FAIL |
| test_materials.gd | 60 | 0 | 75 PASS |
| calibrate_normal_map_check.gd | 60 | 0 | 1 PASS |
| test_impact_burst_config.gd | 60 | 0 | 109 PASS |
| test_impact_burst_state.gd | 60 | 0 (see finding) | 35 PASS |
| test_wound_smoke_config.gd | 60 | 0 | 40 PASS |
| test_wound_smoke_state.gd | 60 | 0 | 22 PASS |

These equal the A6 final counts in `docs/evidence/a6/final/`. **Count convention for this whole log:** "PASS" counts are `grep -c '^PASS'` on the log, which includes the final `PASS: 0 failure(s)` line, the same way the A6 final counts were taken.

**Finding (flaky A6 test):** the first run of `test_impact_burst_state.gd` after the fresh import exited 1 with 4 FAIL lines: "two hits from two real shots (1)", "the second hit came -1 frames". The next three runs passed 35/35. The A2 two-hit section depends on the second real shot hitting a moving zombie; on the first run only one shot registered a hit. Not caused by A7 (no game file changed yet). Recorded as a known flaky check; the baseline is the passing count. If it recurs later, it is re-run once and both results are logged.

## Phase 1 — the brief (2026-11-20)

- Kit brief committed alone (`b0f7569`), then the reference check as a dated revision (`f7cf2f0`). Findings: every `player.gd` reference below line 14 is +2 (A6 added `:13-14`); `hud.gd` process mode is `:52`, keycard element `:102-104`, setter `set_keycard()` `:327`, called from `game.gd:135`; a death mid-reload zeroes `_reload_left` and emits only `died` (no `reload_changed(false)`, no refill).
- **Decision:** `HudAnim` reads the keycard state through `_key_label.visibility_changed` + `_key_label.visible`, so `set_keycard()` is not edited (the brief allows edits only for instancing).

## Phase 2 — CLAUDE.md (2026-11-20)

- No `AGENTS.md` exists, so no `@AGENTS.md` line. Draft committed unedited (`Phase 2: CLAUDE.md draft`), 76 lines. Review: every file/line reference checked against the tree (`project.godot:14/15/25-28/91`, `run-test.sh:23`, `game.gd:57-59/82-87/135`, `hud.gd:52/102-104/327`, `player.gd` lines). One correction committed separately: files not yet built are marked as plan.

## Phase 3 — pins (2026-11-20)

- `godot/tests/test_pins_player.gd`, 60 fps: **19 PASS lines (18 checks + the summary line), 0 FAIL** (the Phase 3 commit message says "20 PASS"; that was a miscount, corrected here) (log `docs/evidence/a7/pins/test_pins_player_60fps.log`).
  - State order READY, FIRE, RELOAD, READY, FIRE.
  - FIRE_INTERVAL: shots 9 frames apart (0.150 s: 0.14 s rounded up to whole 60 fps frames, because `_cooldown` is checked once per process frame).
  - RELOAD_TIME: `reload_changed(true)` frame 44 → `(false)` frame 119 = 75 frames = 1.2500 s.
  - Refill (mag 10 → 15, reserve 60 → 55) reported on the frame of `reload_changed(false)`; fire held 20 frames mid-reload fires nothing; a second R press does not re-emit `reload_changed(true)`.
- First run found a test-side fact: a parsed key event is seen by `is_action_just_pressed` on the **next** process frame (R parsed after frame 43, reload starts on frame 44). The test now waits for the signal; no pin changed.
- **Watched run** (windowed, Movie Maker, `--fixed-fps 60`, same script; `--debug-collisions` does not apply, the pins are HUD/ammo facts, not collisions): exit 0, 0 failures, 138 frames. Seven frames kept in `docs/evidence/a7/pins/watched/` with the run log. Reading (read by Claude): movie frame = log frame + 11. Movie frame 14 shows AMMO 15 / 60, frame 15 shows 14 / 60 (log: first shot at frame 4); frame 54 no reload bar, frame 55 the reload bar appears empty (log: `reload_changed(true)` frame 44); frame 129 shows 10 / 60 with the bar full, frame 130 shows 15 / 55 (log: refill at frame 119); frame 132 shows 14 / 55 (log: first shot after the reload, frame 121). The log lines and the drawn HUD agree frame for frame.

## Phase 4 — the sprite clip (2026-11-20)

- `tools/make_keycard_sheet.py` → `godot/art/keycard_sheet.png` (512 × 64, SHA-256 `df945a6c…`), committed unedited with its `.import`. First draft used Lanczos resampling, which rang into the transparent margin (bounding boxes 58 px wide for a 52 px card); switched to box filtering before the first commit, so the committed PNG is the script's only committed output.
- **Finding (brief):** "cells 4 to 7 show the back face" cannot be a turning card (cell 7 = 315° shows the front) and would pop twice per loop, once on the seam. Generator draws the back on cells 3–5; dated brief revision 2026-11-20 (sheet).
- `ATTRIBUTION.md` A7 section. `keycard_icon.tscn` (root `KeycardIconRig` Node2D, children `KeycardIcon` Sprite2D and `AnimationPlayer`, so the track path is literally `KeycardIcon:frame`). `keycard_spin.tres` as resource text.
- `test_keycard_spin_readback.gd` at 60: **32 PASS lines, 0 FAIL**.

## Phase 5 — the rig clip (2026-11-20)

- `pistol_rig.tscn`: `PistolRig` → `Body` (pivot at the top of the grip) → `Mag`, `Slide`, with Polygon2D parts. **Decision:** `Slide` and `Mag` are children of `Body` so the tilt carries them; the brief's track names become paths from the root: `Body:rotation`, `Body/Slide:position:x`, `Body/Mag:position:y`.
- `pistol_reload.tres` from the key table (frame → time listed in the file header and printed by the test: f6 0.25, f12 0.5, f18 0.75, f21 0.875, f24 1.0, f30 1.25). Easing as key transitions on the key that starts the segment: 2.0 ease-in, 0.5 ease-out, −2.0 in-out.
- `test_pistol_reload_readback.gd` at 60: **57 PASS lines, 0 FAIL** (first run 2 FAIL from exact float compares of seeked pose values in the test; changed to a 1e-3 tolerance, no clip change).

## Phase 6 — wiring plan (2026-11-20, before editing)

Approved by Claude, pre-authorised in A7-RUNBOOK.md (respects the brief's boundaries and the one-authority rule).

1. New `godot/game3d/hud_anim.gd` (`HudAnim`, a `Node`), with a static `attach(hud, player)` like A6's drivers. It instances `keycard_icon.tscn` as a child of the HUD's `_key_label` (to the right of the text, half size) and `pistol_rig.tscn` inside a new bottom-right-anchored `Control` under the HUD's root control. It owns two state tables as constants (`RIG_TABLE`: HOLD/RELOAD/DEAD; `KEY_TABLE`: HIDDEN/SPINNING) and moves between states only through them.
2. Inputs it reads: `player.reload_changed`, `player.died`, `hud._key_label.visibility_changed` (+ `.visible`). It writes only: `play()`/`stop()`/`seek()` on the two `AnimationPlayer`s (RESET pose applied by playing `RESET`, seeking 0 with update, stopping) and `KeycardIcon.visible`. It never writes game state.
3. Existing files: `game.gd` only, three lines (a `preload` const, a `var hud_anim`, one `HudAnim.attach(hud, player)` after the A6 attach lines). `hud.gd` is **not** edited (smaller than the brief allows).
4. A `reload_changed(true)` while already in RELOAD is ignored (the game never sends one; the edge test proves the clip is not restarted).
5. Tests: `test_hud_anim_structure.gd` (tables against resources and the brief, one writer by source scan, autoplay/process mode/callback mode, `current_animation`), `test_hud_anim_state.gd` (real R / Escape key events and real fire button, real zombie contact for death, real walk onto the keycard).

## Phase 6 — wiring, implemented (2026-11-20)

- Agent build `25dd3bd`: `hud_anim.gd` + 3 lines in `game.gd`; `hud.gd` not edited. Tests `58858ab`.
- `test_hud_anim_structure.gd` at 60: **51 PASS lines, 0 FAIL** (the Phase 6 test commit message says "structure 50"; 51 is the log count). `test_hud_anim_state.gd` at 60: **34 PASS lines, 0 FAIL**.
- State test facts: R → RELOAD, `current_animation` "reload"; 30 frames in, Mag y 55.8 px, Body −0.210 rad; the last clip position seen before `reload_changed(false)` was 1.2167 s (the clip runs one frame behind the game's timer; measured in Phase 9); HOLD then RESET pose. Escape mid-reload: clip position 0.3333 s held for 60 paused frames, `_reload_left` held at 0.9000 s; unpaused it continues (0.3333 → 0.3833 s) and the clip's total play time is still 1.2500 s. Keycard: SPINNING, all 8 cells seen in 1.5 s, still looping. Death by a real shambler swipe on the second reload attempt: on the `died` signal the rig is already DEAD, clip stopped, pose (0, 0, 0); no `reload_changed(false)` follows.
- What these cannot prove headless: what the rig and icon look like, legibility, registration, the feel in play (strips and the student's checks).
- Every earlier suite and the pins after wiring (`bash` run of all, 60 fps unless stated): smoke PASS (27 ok), soak PASS, showcase PASS, trigger_count PASS, low_ammo 36/36/36, materials 75, calibrate 1, impact config 109, impact state 35, wound config 40, wound state 22: **all at baseline**. Pins 19 (unchanged). `git diff --stat godot/shaders/` empty.
