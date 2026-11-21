# TUNING.md — A7 clips: frame strips, readings, tuning loop

Captures are **fixture captures run by Claude Code**: windowed Godot 4.7.2 (Forward+, d3d12, RTX 4050 laptop), Movie Maker `--write-movie … --fixed-fps 30`, preview scenes in `godot/previews/` that load the real game and drive the clips through the real signals (a real R key event, a real fire button event; the keycard by placing the player on it). Readings are **read by Claude** from the kept frames and the per-frame log (`capture.log`, one `drawn N` line per movie frame, written just before that frame is drawn). Tuning approvals are Claude's, pre-authorised in A7-RUNBOOK.md. **The student's verdict on every revision is pending: not yet performed by the student** (HUMAN-CHECK-NOTES.md).

Strips: `captures/<clip>/r<N>-<dark|light>-strip.png` (crops of the kept frames), frames in `captures/<clip>/r<N>-<dark|light>/`.
Backgrounds: dark = unlit Assembly Hall floor (player at (27, 3)), light = lit Loading Bay floor (player at (−7, 5)); the rig sits bottom-right of the HUD, so the background under it is the floor south-east of the player.

**Timing fact read from every reload log (applies to all strips):** the R press is seen on frame 10 and `reload_changed(true)` fires on frame 10, but the clip shows position 0 on frames 10 and 11 and starts advancing on frame 12. So every clip boundary is one capture frame later than the brief's list: 0.5 s is drawn on frame 26 (not 25), 1.0 s on frame 41 (not 40). The game's reload ends on frame 48 (38 frames of 1/30 s ≥ 1.25 s), when the clip is at 1.2000 s; HudAnim then applies the RESET pose, which equals the clip's 1.25 s pose. Measured at 60 and 30 fps in Phase 9 (`test_two_clocks.gd`).

---

## Pistol reload

### r0: as built from the brief's key table (`ddb88a0`)

Fixture note: a first r0 capture placed the player at the A6 preview spots; the bottom-right corner was black out-of-level void in both, so it was not "a real stretch of the level". The positions were re-scouted (6 candidates, mean luminance under the rig 28–76/255) and r0 recaptured; the void frames were deleted, not committed.

Per-frame log (drawn frames, r0 dark; light identical):

| frame | clip t (s) | Mag y | Slide x | Body rot |
|---|---|---|---|---|
| 10 | 0.0000 | 0 | 0 | 0 |
| 24 | 0.4333 | 34.42 | 0 | −0.2100 |
| 25 | 0.4667 | 48.07 | 0 | −0.2100 |
| 26 | 0.5000 | 64.00 | 0 | −0.2100 |
| 39 | 0.9333 | 0 | −10.95 | −0.2100 |
| 40 | 0.9667 | 0 | −6.47 | −0.2100 |
| 41 | 1.0000 | 0 | 0 | −0.2100 |
| 47 | 1.2000 | 0 | 0 | −0.0168 |
| 48 | HOLD (RESET) | 0 | 0 | 0 |
| 50 | HOLD | 0 | 0 | 0 |

Reading (read by Claude, against the brief's expectations):
- Frame 10: rest pose, as expected. Frame 25/26: gun tilted; the magazine is out and still falling at 25 (48 px), fully out at 26. Frame 40: magazine seated, gun still tilted, slide returning (at 39 it is racked back −10.95 px). Frame 48: gun level again. **The three phases read as distinct**: tilt + drop (startup), seat + rack (active), level (recovery).
- **Gap 1, visible in both backgrounds:** at frames 24–26 the dropped magazine runs off the bottom of the window: the rig's origin is 110 px above the bottom edge and the magazine's base reaches 75 + 64 = 139 px below it, so up to about 30 px of the magazine is cut off exactly when "magazine fully out" should read.
- **Gap 2:** the rig is drawn on top of the HUD's controls hint ("… N sfx · Esc pause", bottom row); the hint text runs through the grip at every frame.
- Gap 3 (smaller): the slide rack is 14 px on a 148 px slide; it reads at frame 39 but only just.
- Contrast: over the lit floor the light-grey slide and the brass magazine read clearly; over the dark floor everything reads (the background is near black). The dark grip panel and the frame are the weakest parts over the dark floor.

Student's verdict on r0: **pending: not yet performed by the student.**

### r1: one change, the rig's place on screen (prediction committed before the edit)

Change (one setting): `HudAnim.RIG_OFFSET` from (−150, −110) to (−150, −190), i.e. the rig moves 80 px up from the bottom-right corner. No clip, key or phase changes, so no brief revision (the brief only says "bottom-right of the HUD", which still holds) and no read-back expectation changes.

Prediction, per frame (both backgrounds):
- 10, 47, 48, 50: identical poses to r0, drawn 80 px higher; the hint row is entirely below the magazine's base plate (base at 190 − 75 = 115 px above the bottom edge, hint text at about 20 px).
- 24, 25, 26: the whole magazine is on screen; at 26 its base plate is 190 − 139 = 51 px above the bottom edge, so "magazine fully out" reads at its full 64 px drop.
- 39–41: unchanged apart from position (the slide rack still small: gap 3 remains for r2).
- Background under the rig: a slightly different patch of the same floor (80 px higher on screen ≈ 1 m further north in the world).
Keep if every listed frame shows the whole rig with no clipping and no hint text crossing it; otherwise revert.
