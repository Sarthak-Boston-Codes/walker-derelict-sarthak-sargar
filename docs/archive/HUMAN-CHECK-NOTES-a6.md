# HUMAN-CHECK-NOTES.md: the student's own observations (A6)

This file is for **Sarthak's own eyes only**. Claude Code wrote this empty template; it has filled in no observation and no verdict. A row changes from "pending: not yet performed by the student" only when the student does the check and gives their own words. Claude's readings of the fixture strips are in TUNING.md and TEST-REPORT.md, labelled "read by Claude", and do not count here. The A5 notes are archived at `docs/archive/HUMAN-CHECK-NOTES-a5.md`.

How to look: run the game (`godot --path godot`, then Play) at the project window size (1280 × 720). The fixture strips are in `captures/impact_burst/` and `captures/wound_smoke/` (each `r*/strip.png`); regenerate them with the commands in TUNING.md.

## Checks

| # | Check | What to look at | Status | What I saw (student's words) | Date |
|---|---|---|---|---|---|
| H1 | Effect A in play, rapid repeats | Hold fire into a zombie: a stream of separate bursts, not one smeared cloud | pending: not yet performed by the student | | |
| H2 | Effect A size at 1280 × 720 | Flash about head-sized, sparks small, puff 0.3–0.5 m next to the 1.7 m player | pending: not yet performed by the student | | |
| H3 | Effect A on dark and light backgrounds | Sparks readable in an Assembly Hall corner with only the flashlight; puff readable on lit floor under a lamp or the red emergency light | pending: not yet performed by the student | | |
| H4 | Effect A at the screen edge | Bursts near the edge of the window do not pop out early | pending: not yet performed by the student | | |
| H5 | Effect B starting and stopping | Smoke appears when health drops to 60 or below; stops after a medkit lifts it above 60, and on death | pending: not yet performed by the student | | |
| H6 | Effect B paused | Esc to pause: the smoke freezes in place; it resumes on unpause | pending: not yet performed by the student | | |
| H7 | Effect B hidden | (Only with a debug tool or the editor; nothing in the game hides it.) Nothing drawn while hidden | pending: not yet performed by the student | | |
| H8 | Effect B in motion | Moving while hurt leaves a trail of smoke behind the player (the fixture strips are stationary) | pending: not yet performed by the student | | |
| H9 | Effect B on dark and light backgrounds | Reads over lit floor and the flashlight cone; disappears in the darkest corners (intended) | pending: not yet performed by the student | | |
| H10 | Scene load | Nothing of either effect on screen in the first frames after starting a game | pending: not yet performed by the student | | |
| H11 | Visual Profiler read | Debugger → Visual Profiler, GPU time with both effects active vs off; compare with TEST-REPORT.md Price | pending: not yet performed by the student | | |
| H12 | Claude's strip readings against my own view | Do the r0/r1/r2 strips look the way TUNING.md says? | pending: not yet performed by the student | | |

## Tuning verdicts (running game)

| Revision | Change | Claude Code's decision | My verdict | Date |
|---|---|---|---|---|
| A-r1 | Puff `billboard_keep_scale` false → true | reverted | pending: not yet performed by the student | |
| B-r1 | wound smoke `spread` 25 → 70 | kept | pending: not yet performed by the student | |
| B-r2 | wound smoke `turbulence_influence_min/max` 0.1 → 0.03 | kept | pending: not yet performed by the student | |
| A-r2 (proposal only, not applied) | Puff keep_scale true **and** scale 0.5 / 0.9 | needs approval | pending: not yet performed by the student | |
