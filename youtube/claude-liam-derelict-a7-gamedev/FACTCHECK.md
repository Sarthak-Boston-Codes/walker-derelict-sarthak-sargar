# FACTCHECK: every claim in the narration, and where it comes from

Written by Claude Code. "Read by Claude" means Claude Code looked at a capture or strip; it is not the student's check.

| Beat | Claim | Source |
|---|---|---|
| B00 | Prompt in the composer | **Reconstruction**: no such prompt was typed. The student asked Claude Code to extract the A7 kit and execute `A7-RUNBOOK.md`; the composer shows a suggested Walker prompt (PROMPTS.md). |
| B00 | top-down 3D zombie shooter, Godot; two HUD animations | README.md; `godot/game3d/hud_anim.gd` |
| B01 | read back key by key, played through real input, drawn frame by frame | `test_keycard_spin_readback.gd`, `test_pistol_reload_readback.gd`, `test_hud_anim_state.gd` (Input.parse_input_event), TUNING.md strips |
| B01 | "they haven't yet"; "Claude wrote the brief, and Claude Code wrote everything else, including this film" | HUMAN-CHECK-NOTES.md (every row pending); SOURCES.md A7 section |
| B02 | 8 cells @12 fps, looping while carried; rig @24 fps, once per reload, 1.25 s = reload time | `keycard_spin.tres:10-12`, `pistol_reload.tres:19-21`, `player.gd:30`; `hud_anim.gd:19-28` |
| B03 | clip = length, loop mode, tracks; track = node + property; key = time, value, transition; player on the process tick | `keycard_spin.tres:10-23`; `keycard_icon.tscn` (`callback_mode_process = 1`); Godot 4.7.2 Animation / AnimationPlayer |
| B04 | 8 keys 1/12 s apart, values 0–7, frame property, discrete, LOOP_LINEAR, length 8/12 | `keycard_spin.tres:10-23`; read-back log (32 PASS lines) |
| B05 | sheet from a script; 8 cells of 64 px; 45° steps; hframes 8; in order then 0 with no repeat; centred to 0.5 px | `tools/make_keycard_sheet.py`, `godot/art/keycard_sheet.png`, `keycard_icon.tscn`; `captures/keycard_spin/r0-*-strip.png` and TUNING.md keycard r0 (read by Claude) |
| B06 | phase table frames; 1/24 s per frame; frame 12 = 0.5 s, magazine fully out | CHANGE-BRIEF.md phase table; `pistol_reload.tres:19-32` (key 0.5 s = 64.0) |
| B07 | tilt and drop in startup; fully out at 0.5 s; seated and slide racks in active; levels in recovery; boundaries one capture frame late | `captures/pistol_reload/r2-*-strip.png`, `capture.log` (`drawn 26 … 0.5000 mag_y 64.00`), TUNING.md (read by Claude) |
| B08 | one authority; two tables; HOLD/RELOAD/DEAD; HIDDEN/SPINNING; every brief transition and nothing else | `hud_anim.gd:18-28`; `test_hud_anim_structure.gd` (51 PASS lines) |
| B09 | real key press walks onto the keycard; pickup; label appears; HudAnim starts the spin; nothing else touches the sprite | `logs/film_capture_keyplay.log` (`keycard picked up true after 15 frames of W`, `icon SPINNING`); player placed 3 m away before filming (disclosed on screen); structure test source scan |
| B10 | unlisted events ignored; second reload can't restart; entering a state plays from the start or snaps to rest | `hud_anim.gd:99-118`; `test_pistol_reload_edges.gd` (position = (tick − 1)/60 after every second R) |
| B11 | startup fire: nothing; active R: carries on; recovery fire: shot when the reload ends; pause freezes rig with the timer | `logs/film_capture_reloadplay.log`: shots stay 2 at frame 32; one `reload_changed(true)` for the active reload; `FRAME 186 … HOLD … shots 5` (shot on the end frame); frames 233–250 `paused true` at clip 0.3333 |
| B12 | game clock in the process function; clip on the same tick; brief predicted < 1 frame | `player.gd:165-168`, `:193-198`; CHANGE-BRIEF "The two clocks" |
| B13 | tick 75 vs 76; exactly one frame at 60 and 30; the clip doesn't advance on the tick after it starts | `docs/evidence/a7/two_clocks/*.log`; `test_pistol_reload_edges.gd` (position 0 on ticks 0 and 1); the mechanism is not established (brief revision 2026-11-20) |
| B14 | r1 magazine off the window → +80 px up, kept; r2 rack 14 → 24 px, kept; verdicts pending | TUNING.md reload r1/r2; commits 0455570, 0d8710e |
| B15 | tracks resolve; key times, step, loop mode pinned; timings unchanged; three mutations fail, the import-cache one changes nothing | `docs/evidence/a7/final/`, `docs/evidence/a7/mutations/README.md`, pins identical before/after |
| B16 | brief's back-face cells; void strips; Claude Code's test bugs; two miscounted commit messages | CHANGE-BRIEF revision (sheet); TUNING.md fixture note; A7-LOG.md phases 3, 6, 7 |
| B17 | who wrote what; the sheet has no licence | SOURCES.md A7 section; ATTRIBUTION.md |
| B18 | verdict lines | TEST-REPORT.md |
| B19 | the Your Turn prompt and "zero ticks" prediction | PROMPTS.md; the prediction is Liam's guess, not a result |
