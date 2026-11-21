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

These equal the A6 final counts in `docs/evidence/a6/final/`.

**Finding (flaky A6 test):** the first run of `test_impact_burst_state.gd` after the fresh import exited 1 with 4 FAIL lines: "two hits from two real shots (1)", "the second hit came -1 frames". The next three runs passed 35/35. The A2 two-hit section depends on the second real shot hitting a moving zombie; on the first run only one shot registered a hit. Not caused by A7 (no game file changed yet). Recorded as a known flaky check; the baseline is the passing count. If it recurs later, it is re-run once and both results are logged.

## Phase 1 — the brief (2026-11-20)

- Kit brief committed alone (`b0f7569`), then the reference check as a dated revision (`f7cf2f0`). Findings: every `player.gd` reference below line 14 is +2 (A6 added `:13-14`); `hud.gd` process mode is `:52`, keycard element `:102-104`, setter `set_keycard()` `:327`, called from `game.gd:135`; a death mid-reload zeroes `_reload_left` and emits only `died` (no `reload_changed(false)`, no refill).
- **Decision:** `HudAnim` reads the keycard state through `_key_label.visibility_changed` + `_key_label.visible`, so `set_keycard()` is not edited (the brief allows edits only for instancing).

## Phase 2 — CLAUDE.md (2026-11-20)

- No `AGENTS.md` exists, so no `@AGENTS.md` line. Draft committed unedited (`Phase 2: CLAUDE.md draft`), 76 lines. Review: every file/line reference checked against the tree (`project.godot:14/15/25-28/91`, `run-test.sh:23`, `game.gd:57-59/82-87/135`, `hud.gd:52/102-104/327`, `player.gd` lines). One correction committed separately: files not yet built are marked as plan.

## Phase 3 — pins (2026-11-20)

- `godot/tests/test_pins_player.gd`, 60 fps: **20 PASS, 0 FAIL** (log `docs/evidence/a7/pins/test_pins_player_60fps.log`).
  - State order READY, FIRE, RELOAD, READY, FIRE.
  - FIRE_INTERVAL: shots 9 frames apart (0.150 s: 0.14 s rounded up to whole 60 fps frames, because `_cooldown` is checked once per process frame).
  - RELOAD_TIME: `reload_changed(true)` frame 44 → `(false)` frame 119 = 75 frames = 1.2500 s.
  - Refill (mag 10 → 15, reserve 60 → 55) reported on the frame of `reload_changed(false)`; fire held 20 frames mid-reload fires nothing; a second R press does not re-emit `reload_changed(true)`.
- First run found a test-side fact: a parsed key event is seen by `is_action_just_pressed` on the **next** process frame (R parsed after frame 43, reload starts on frame 44). The test now waits for the signal; no pin changed.
- **Watched run** (windowed, Movie Maker, `--fixed-fps 60`, same script; `--debug-collisions` does not apply, the pins are HUD/ammo facts, not collisions): exit 0, 0 failures, 138 frames. Seven frames kept in `docs/evidence/a7/pins/watched/` with the run log. Reading (read by Claude): movie frame = log frame + 11. Movie frame 14 shows AMMO 15 / 60, frame 15 shows 14 / 60 (log: first shot at frame 4); frame 54 no reload bar, frame 55 the reload bar appears empty (log: `reload_changed(true)` frame 44); frame 129 shows 10 / 60 with the bar full, frame 130 shows 15 / 55 (log: refill at frame 119); frame 132 shows 14 / 55 (log: first shot after the reload, frame 121). The log lines and the drawn HUD agree frame for frame.
