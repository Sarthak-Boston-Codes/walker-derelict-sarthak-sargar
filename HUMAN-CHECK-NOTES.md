# HUMAN-CHECK-NOTES.md: the student's own observations (A7)

This file is for **Sarthak's own eyes only**. Claude Code wrote this empty template; it has filled in no observation and no verdict. A row changes from "pending: not yet performed by the student" only when the student does the check and gives their own words. Claude's readings of the fixture strips are in TUNING.md and TEST-REPORT.md, labelled "read by Claude", and do not count here. The A6 notes are archived at `docs/archive/HUMAN-CHECK-NOTES-a6.md`.

How to look: run the game (`godot --path godot`, then Play) at the project window size (1280 × 720). The pistol rig is bottom-right; the keycard icon appears beside "◆ KEYCARD" (top-left) once the keycard is picked up in the Boiler Room. Strips: `captures/pistol_reload/r*-strip.png`, `captures/keycard_spin/r0-*-strip.png`.

## Checks

| # | Check | What to look at | Status | What I saw (student's words) | Date |
|---|---|---|---|---|---|
| H1 | Cycle seam over five wraps | Watch the keycard spin for at least five turns (about 3.3 s): no stall, no jump, cell 7 → cell 0 as smooth as every other step | pending: not yet performed by the student | | |
| H2 | The reload in play, interrupt in startup | Press R, then fire and R again within the first half second: no shot, no restart, the rig carries on | pending: not yet performed by the student | | |
| H3 | The reload in play, interrupt in active | Same between 0.5 s and 1.0 s (magazine going back in, slide racking) | pending: not yet performed by the student | | |
| H4 | The reload in play, interrupt in recovery | Same between 1.0 s and 1.25 s; and fire right as the gun levels: the first shot comes when the rig settles | pending: not yet performed by the student | | |
| H5 | Pause and death during a reload | Esc mid-reload: the rig freezes and continues on unpause. Dying mid-reload: the rig snaps to rest | pending: not yet performed by the student | | |
| H6 | Keycard registration | The card stays centred while it turns; no wobble between cells | pending: not yet performed by the student | | |
| H7 | Dark background | The rig over a dark stretch (Assembly Hall corner): still readable | pending: not yet performed by the student | | |
| H8 | Light background | The rig over a lit floor (Loading Bay): still readable | pending: not yet performed by the student | | |
| H9 | Do the phases read as distinct? | Startup (tilt, magazine out), active (magazine seated, slide racked), recovery (gun levels) | pending: not yet performed by the student | | |
| H10 | Claude's strip readings against my own view | Do the strips look the way TUNING.md says? | pending: not yet performed by the student | | |

## Tuning verdicts (running game)

| Revision | Change | Claude Code's decision | My verdict | Date |
|---|---|---|---|---|
| reload r0 | as built from the brief | baseline | pending: not yet performed by the student | |
| reload r1 | `HudAnim.RIG_OFFSET` y −110 → −190 (rig 80 px higher) | kept | pending: not yet performed by the student | |
| reload r2 | Slide f21 rack −14 → −24 px | kept | pending: not yet performed by the student | |
| keycard r0 | as built from the cycle spec | no change | pending: not yet performed by the student | |
