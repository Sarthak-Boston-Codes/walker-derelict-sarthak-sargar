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
