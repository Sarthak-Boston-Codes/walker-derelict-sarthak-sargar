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

#### r1 result (strips `r1-dark-strip.png`, `r1-light-strip.png`; read by Claude)

- Log: identical clip times and poses to r0 on every frame; `rig on screen at (1130, 530)` (r0: (1130, 610)).
- Frames 24–26: the whole magazine is on screen; at 26 its base plate is about 50 px above the bottom edge (both backgrounds). **As predicted.**
- Every listed frame: the controls hint row is below the rig, nothing crosses the grip. **As predicted.**
- Background: light = the lit floor plus the edge of a rust floor patch south-east of the player; dark = unlit floor, near black.
- Gap 3 (slide rack small, 14 px) remains, as predicted.

**Decision: keep r1** (both conditions of the prediction met). Student's verdict on r1: **pending: not yet performed by the student.**

### r2: one change, the slide's rack depth (prediction committed before the edit)

Change (one key's value): `Body/Slide:position:x` key at f21 (0.875 s) from −14 to −24 px, in `pistol_reload.tres`. This is a phase-table key value, so a dated brief revision comes first and `test_pistol_reload_readback.gd`'s expected value changes in the same commit as the clip.

Prediction, per frame (log values from the same easing, 2.0 ease-in from f18 = 0 to f21, then linear back to 0 at f24): the slide position scales by 24/14.
- 39 (clip 0.9333 s): slide x −10.95 → **−18.77** px; the rack reads clearly (about 13 % of the slide's length, the ejection port moves past the frame's rear edge).
- 40 (0.9667 s): −6.47 → **−11.09** px. 41 (1.0 s): 0, as before.
- Every other listed frame: identical to r1 (the slide is at 0 outside 0.75–1.0 s).
- At frame 37 (0.875 s, not on the read list), the slide reaches −24 px; the slide's rear end then sits about 24 px behind the frame, which should still look like one gun (the slide polygon is a separate part, so no gap appears inside the rig).
Keep if frame 39 shows the rack clearly and no part separates visibly; otherwise revert.

#### r2 result (strips `r2-dark-strip.png`, `r2-light-strip.png`, close-up `r2-light-rack.png`; read by Claude)

- Log: slide x at frame 39 **−18.77**, frame 40 **−11.09**, frame 41 0; frame 37 (0.8667 s) −22.40. Exactly the predicted values. Correction to the prediction's wording: the 2.0 ease-in is on the f21 key, so it shapes the snap forward (f21 → f24), and the rack back (f18 → f21) is linear, as the brief's table says ("f24 0 (snap forward, ease-in)"). The predicted numbers were computed from the clip and were not affected.
- Frame 39: the slide sits clearly back. The dark front of the frame shows ahead of the slide's muzzle end, which r1's frame 39 barely shows. The rack now reads. **As predicted.**
- No part separates: the slide stays over the frame in every frame, 36–41. **As predicted.**
- Every other listed frame matches r1 (startup, magazine, recovery, rest).
- (The r1 strips were re-cropped at y = 572 so the slide is inside the crop. The first r1 crop at y = 600 cut the slide off; the frames are the same.)

**Decision: keep r2.** Student's verdict on r2: **pending: not yet performed by the student.**

---

## Keycard spin

### r0: as built from the cycle spec (`fc337ce` clip; strips `captures/keycard_spin/r0-light-strip.png`, `r0-dark-strip.png`)

Capture: the player is placed on the keycard on frame 10. The pickup's overlap check (every 0.2 s) picks it up, and the label (so `SPINNING`) shows on frame 14. The player is then put back on the background spot. The icon sits at canvas (154, 146), inside the HUD's top-left panel, to the right of "◆ KEYCARD", at half size (32 × 32 px on screen, card 26 px wide). Its background is therefore the HUD panel, not the level, in both captures; the dark/light difference is only the level visible around the panel.

Cell shown per drawn frame (log, identical in both captures): 13 hidden · 14–17 cell 0 (clip position 0 on 14 and 15, then advancing; the same one-frame start as the reload) · 18–19 cell 1 · 20–22 cell 2 · 23–24 cell 3 · 25–27 cell 4 · 28–29 cell 5 · 30–32 cell 6 · 33–35 cell 7 · **36–37 cell 0** · 38 cell 1. At 30 fps a 12 fps cell lasts 2 or 3 frames (2.5 on average), so the 2/3 alternation is the capture rate, not the clip.

Reading (read by Claude):
- **Eight distinct cells, in order**: front flat (100 %) → front leaning (about 73 %) → edge (a 2 px line) → back leaning (about 69 %) → back flat (100 %, orange) → back leaning → edge → front leaning the other way → front flat again. As the brief expects (with the face assignment from the 2026-11-20 sheet revision).
- **Seam**: cell 7 on 33–35, then cell 0 on 36 and cell 1 on 38. No cell repeats across the wrap, and the wrap gap is one key interval like every other step. No visible stall in the strip.
- **Registration**: the bounding-box centre of the drawn card, measured on the clean frames (light 18, 20, 23, 25, 28, 30, 33, 36; dark 28, 30, 33, 36), is (31.0–31.5, 30.5) in a 64 px crop: within 0.5 px across all cells. Frame 14 in both captures, and dark frames 18–25, include level pixels in the crop while the camera snaps back, so their numbers are not card measurements.
- Contrast: the cyan front and the orange back both read on the dark panel; the edge-on cells are a thin grey line, visible.
- Possible gap, not tuned: the icon is small (a 26 px card at 1280 × 720). The strip reads at 4×, but whether it catches the eye in peripheral vision is the student's check in the running game.

No keycard tuning revision: the runbook asks for one more revision "if a gap is visible"; reload r2 was that revision, and the strip shows no seam, order or registration gap. Student's verdict on keycard r0: **pending: not yet performed by the student.**
