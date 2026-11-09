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
