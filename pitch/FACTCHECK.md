# FACTCHECK — DERELICT pitch film (A8)

Written by Claude Code. Every sentence of the narration, one row each, with its evidence or the word "will", is in **`HONESTY-CHECK.md`**. This file records the on-screen numbers.

| On screen | Value | Source |
|---|---|---|
| B06 low_ammo_test | 35 PASS at 30 / 60 / 144 fps | `TEST-REPORT.md` at `a5` |
| B06 test_materials | 74 PASS | `TEST-REPORT.md` at `a5` |
| B06 effect configs | 108 / 39 PASS | `TEST-REPORT.md` at `a6` |
| B06 animation | read-backs 32 + 57, structure 51, state 34, edges 98 PASS lines | `TEST-REPORT.md` at `a7` |
| B06 GPU | +0.018 / +0.023 ms against budgets 0.30 / 0.20 ms, NVIDIA GeForce RTX 4050 Laptop GPU | `TEST-REPORT.md` at `a6`; `docs/evidence/a6/gpu_price.log` |
| B06 mutations | 3 (a5), 4 (a6), 3 (a7), each exit 1; A7's mutation 4 exits 0 by design and is not counted | `TEST-REPORT.md` at each tag |
| B06 pins | 19 PASS lines, identical before and after wiring | `TEST-REPORT.md` at `a7` |
| B07 | 98 PASS, 0 FAIL; nine lines copied verbatim | `docs/evidence/a7/final/test_pistol_reload_edges_60fps.log` (`887266f`), counted by `make_pitch.py` at build time |
| B10 | r0: the puff is full size and never grows; r1 (keep_scale): it shrinks to a dot, reverted | `TUNING.md` at `a6` (A-r1 reverted); `docs/evidence/a6/probe_particle_scale.log` |
| B04 quote | "I have played GTA (all of them till gta 4) and also Call of Duty!" | the student's answer, quoted in `PROJECT-BRIEF.md` |
