# HUMAN-CHECK-NOTES.md — the student's own observations (A5)

This file is for **Sarthak's own eyes only**. Claude Code created the empty template and has filled in nothing below. Each row stays "pending: not yet performed by the student" until the student does the check and writes, in their own words, what they saw. Claude's inspection of the same captures is in TEST-REPORT.md and is labelled "inspected by Claude"; it does not count here.

How to look: run the game (`godot --path godot`, then Play), or open the captures in `docs/evidence/captures/` (regenerate full size with `godot --path godot --fixed-fps 60 --script res://tools/a5_capture.gd`, env `MODE=ammo|hint|sweep|twomat|play`, `OUT=<folder>`).

| # | Check (HUMAN CHECK) | What to look at | Status | What I saw (student's words) | Date |
|---|---|---|---|---|---|
| H1 | Only the ammo counter changes colour in play (R8) | Play; fire until 5 rounds or fewer; watch every other HUD element | pending: not yet performed by the student | | |
| H2 | The look at low_ammo 0.0 / 0.5 / 1.0 / 2.0 vs my predictions | `ammo_*_label_fixed.png` | pending: not yet performed by the student | | |
| H3 | Shadow / outline is not tinted (failure case 5) | `ammo_1.0_label.png` (before fix) vs `ammo_1.0_label_fixed.png` | pending: not yet performed by the student | | |
| H4 | The warning is readable and noticeable in peripheral vision | Normal play in a dark room | pending: not yet performed by the student | | |
| H5 | Hint experiment: the source_color quad looks like the file, the other looks brighter | `hint_experiment.png` | pending: not yet performed by the student | | |
| H6 | Interface sweep: which settings break the look | `sweep_sheet.png` | pending: not yet performed by the student | | |
| H7 | Dry vs wet floor read as different places under the flashlight | Play; walk from the Assembly Hall into the Boiler Room | pending: not yet performed by the student | | |
| H8 | Normal play: the effect in context, nothing else broken | Play one full run | pending: not yet performed by the student | | |

## Student's own notes

(empty)
