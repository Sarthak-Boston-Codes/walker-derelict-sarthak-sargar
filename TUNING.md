# TUNING.md: A6 particle effects

Authorship: the tuning approvals were written by Claude (pre-authorised in `A6-RUNBOOK.md`: exactly one setting per revision, aimed at the biggest gap between the strip and the brief's intent, with a prediction made before editing). The strips, the readings and the comparisons were made by Claude Code and are labelled "read by Claude". The student's verdict in the running game is the student's alone. It reads "pending: not yet performed by the student" until the student gives it (recorded in `HUMAN-CHECK-NOTES.md`).

All strips are **fixture captures**: windowed Movie Maker runs of `godot/previews/*_preview*.tscn` at 30 fps over the real level, with the in-game camera rig and flashlight, waves off, no zombies, the player parked, the HUD layer hidden, and `use_fixed_seed` on the preview instance only (seed 12345). Crops are scaled 3×. The pixels-per-metre figure at the effect is printed by the preview (`logs/capture_*.log`).

---

## Effect A: impact burst

### First reading: r0 (scene as built from the brief's table, commit 1435dd5). Read by Claude.

Strips: `captures/impact_burst/r0/strip.png` (dark: Assembly Hall corner, flashlight pool, 59.6 px/m) and `captures/impact_burst/r0-light/strip.png` (light: Loading Bay floor under the lamp, 55.6 px/m). The trigger fires on frame 10. Frame 11 is kept beside the brief's six frames because it is the first frame that shows anything.

| Frame (after trigger) | Brief's intent | What the strip shows (dark / light) |
|---|---|---|
| 10 (+0) | flash on the trigger frame | **Nothing**, on both backgrounds. `restart()` was called on frame 10 (`Engine.get_frames_drawn()` = 10, logged); the first particles are drawn on frame 11. A one-frame (33 ms) delay. |
| 11 (+1) | (not in the brief's list) | White flash about 17 px across (~0.29 m), with a dark-red ring around it about 0.4–0.5 m across: the puff, already at full size. 1–3 sparks at the flash's edge. |
| 12 (+2) | flash fading, sparks leaving | Flash **gone** (lifetime 0.08 s = 2.4 frames). Sparks in a tight cluster just leaving the centre: pale yellow dots 3–4 px (~6 cm), larger than the brief's 4–6 cm in intent but in range. Puff: a red-brown disc about 0.5 m, at its strongest. |
| 15 (+5) | sparks mid-flight | Sparks spread 0.3–0.6 m from the centre. On the dark pool they read pale orange; on the light floor they read cream and are hard to see (additive on a bright floor). Puff the same size (~0.5 m), slightly weaker. |
| 20 (+10) | sparks dying, puff at its widest | Sparks gone. The puff is a faint pinkish disc, still ~0.5 m: it **never grew**. |
| 30 (+20) | puff almost gone | Nothing. |
| 50 (+40) | nothing | Nothing. |

**Why sizes do not change (diagnosed, not guessed).** The flash does not shrink, the puff does not grow, and every particle draws at its QuadMesh size (sparks ~10 cm, not 3–6 mm; puff 0.5 m from the first frame). A probe (`godot/tools/probe_particle_scale.gd`, log `docs/evidence/a6/probe_particle_scale.log`, run by Claude Code on the RTX 4050) shows that in Godot 4.7.2 a `StandardMaterial3D` with `billboard_mode = particles` **ignores** the `ParticleProcessMaterial` scale (scale_min/max and scale_curve) unless `billboard_keep_scale = true`. A 1.0 m quad at scale 0.5 draws 72 px (unscaled) with keep_scale false and 36 px with it true. The brief's table does not name `billboard_keep_scale`, so the scene matches the table and the configuration test passes, but the table's scale rows have no visible effect. Recorded as a dated revision in CHANGE-BRIEF.md.

**Gaps against the intent, largest first:**
1. **Puff: no expansion and the wrong timing.** Intent: "0.2–0.6 s a dark puff expands slowly", widest at +10, growing ~3×. Strip: full size (0.5 m) at +1, never grows, fades from the first frame. It is also red-brown, not dark (intent: value, not hue).
2. **No scale change anywhere:** the flash does not shrink to 30 % (it lives only one drawn frame, so this is hard to see either way).
3. **Sparks over the light floor** wash out (additive on a bright floor). The brief expects this: sparks are for the dark, the puff for the light.
4. **One-frame delay** before the first particles: not a setting in the table. Recorded, not tuned.

My verdict (running game), r0: pending: not yet performed by the student.

### Revision A-r1: Puff draw material `billboard_keep_scale` false → true

- **Biggest gap (from the r0 reading):** the puff does not expand. It is full size (0.5 m, its QuadMesh) on the first drawn frame and never grows, because billboard particles ignore the process scale and scale curve (diagnosed above).
- **The one setting:** `Puff` draw material (`StandardMaterial3D`), `billboard_keep_scale`: **false → true**. Nothing else changes; Flash and Sparks have their own materials and are untouched.
- **Approved by:** Claude, pre-authorised in A6-RUNBOOK.md.
- **Prediction (made before editing, committed before the change).** The puff size becomes quad 0.5 m × scale 0.15–0.3 × the scale curve, which runs 0.5 → 1.6 linearly over the 0.6 s life. At ~57 px/m:

| Frame | Age | Curve | Predicted puff |
|---|---|---|---|
| 10 | – | – | nothing (the one-frame delay is unchanged) |
| 11 | ~0.03 s | 0.55 | 8 blobs of 0.04–0.08 m (2–5 px), hidden under the flash; no 0.5 m ring any more |
| 12 | ~0.07 s | 0.62 | 0.05–0.09 m blobs (3–5 px), starting to spread (0.6–1.4 m/s, damped) |
| 15 | ~0.17 s | 0.81 | 0.06–0.12 m blobs (3–7 px), alpha ~0.43, the cluster ~0.2–0.4 m across |
| 20 | ~0.33 s | 1.11 | 0.08–0.17 m blobs (5–9 px), alpha ~0.27, faint: the widest point of each blob |
| 30, 50 | | | nothing |

  Net: the puff will now visibly **grow** (about 2× in the frames read, 3.2× over its life). It will read as a small cluster of separate dark-red dots, much less mass than the r0 disc, and is likely **too weak over the light floor**, which is the puff's job. Flash and sparks: identical to r0 (same seed).

- **Strips:** `captures/impact_burst/r0/strip.png` (before) and `captures/impact_burst/r1/strip.png` (after), dark; `r0-light/strip.png` and `r1-light/strip.png`, light. Same seed, same camera, same crop.
- **Claude's comparison (read by Claude, frame by frame):**

| Frame | Predicted | r1 shows | Held? |
|---|---|---|---|
| 10 | nothing | nothing | yes |
| 11 | 2–5 px blobs under the flash; no 0.5 m ring | the dark-red ring around the flash is **gone**; only the flash shows | yes |
| 12 | 3–5 px blobs starting to spread | one or two dark-red specks ~2 px beside the sparks; in the dark strip a faint grey disc where the flash was | partly: the specks are at the small end and barely spread |
| 15 | 3–7 px blobs, a cluster 0.2–0.4 m across, alpha ~0.43 | 2–3 specks of 2–4 px within ~0.1 m | size at the low end; **the cluster is much tighter than predicted** (damping 2.5–4 stops them within ~0.1 m) |
| 20 | 5–9 px blobs, faint, widest | one faint blob of ~4 px (~0.07 m) | growth visible but smaller than predicted |
| 30, 50 | nothing | nothing | yes |

  Flash and sparks are pixel-for-pixel as in r0 apart from where the r0 puff disc overlapped them: yes, as predicted.
  **Against the intent:** the mechanism now works (the puff grows over its life, ~2× in the frames read), but the puff no longer does its job. At its widest it is ~0.07 m, not 0.3–0.5 m, and over the light floor, where it is meant to read, it is a few specks you have to look for. r0's static 0.5 m disc was closer to the intent on size and contrast, which matter more for "a hit landed here" than growth does. The prediction's direction held ("too weak over the light floor"); its numbers for spread were too generous.
- **Decision: reverted.** The comparison does not support keeping this change on its own. The puff's table scale (0.15–0.3) only makes sense together with keep_scale if the scale values are raised about 3×. That is a **second setting**, outside this revision's one-setting approval.
- **Next step (needs a fresh approval, not taken):** A-r2 = keep_scale true **and** Puff `scale_min/max` 0.15/0.3 → 0.5/0.9. Predicted: blobs 0.12–0.23 m at birth growing to 0.4–0.7 m. Recorded for Claude/the student to approve or reject.
- **My verdict (running game):** pending: not yet performed by the student.
