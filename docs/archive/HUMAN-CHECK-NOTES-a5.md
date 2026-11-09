# HUMAN-CHECK-NOTES.md — the student's own observations (A5)

This file is for **Sarthak's own eyes only**. Claude Code wrote the template. The "What I saw" text below is the student's own words, as the student gave them to Claude Code on 2026-10-29, copied verbatim. A row is marked done only where those words cover it; every other row stays "pending: not yet performed by the student". Claude's inspection of the same captures is in TEST-REPORT.md, labelled "inspected by Claude", and does not count here.

How to look: run the game (`godot --path godot`, then Play), or open the captures in `docs/evidence/captures/` (regenerate full size with `godot --path godot --fixed-fps 60 --script res://tools/a5_capture.gd`, env `MODE=ammo|hint|sweep|twomat|play`, `OUT=<folder>`).

## Student's observations, 2026-10-29 (verbatim)

> "I played the game myself. Shooting, magazine reload, zombie kills and all their sounds work. The magazine runs out of ammo after a while, reloads, and the health pack and ammo pickups after killing a zombie work."

> "I also saw the ammo counter turn red at 5 rounds or fewer and fade back after a reload."

## Checks

| # | Check (HUMAN CHECK) | What to look at | Status | What I saw (student's words) | Date |
|---|---|---|---|---|---|
| H1 | Only the ammo counter changes colour in play (R8) | Play; fire until 5 rounds or fewer; watch every other HUD element | partly done: the counter turning red and fading back was observed; whether every other HUD element stayed unchanged is pending: not yet performed by the student | "I also saw the ammo counter turn red at 5 rounds or fewer and fade back after a reload." | 2026-10-29 |
| H2 | The look at low_ammo 0.0 / 0.5 / 1.0 / 2.0 vs my predictions | `ammo_*_label_fixed.png` | pending: not yet performed by the student | | |
| H3 | Shadow / outline is not tinted (failure case 5) | `ammo_1.0_label.png` (before fix) vs `ammo_1.0_label_fixed.png` | pending: not yet performed by the student | | |
| H4 | The warning is readable and noticeable in peripheral vision | Normal play in a dark room | pending: not yet performed by the student | | |
| H5 | Hint experiment: the source_color quad looks like the file, the other looks brighter | `hint_experiment.png` | pending: not yet performed by the student | | |
| H6 | Interface sweep: which settings break the look | `sweep_sheet.png` | pending: not yet performed by the student | | |
| H7 | Dry vs wet floor read as different places under the flashlight | Play; walk from the Assembly Hall into the Boiler Room | pending: not yet performed by the student | | |
| H8 | Normal play: the effect in context, nothing else broken | Play one full run | done: general playtest | "I played the game myself. Shooting, magazine reload, zombie kills and all their sounds work. The magazine runs out of ammo after a while, reloads, and the health pack and ammo pickups after killing a zombie work." | 2026-10-29 |

## Student's own notes

(empty)
