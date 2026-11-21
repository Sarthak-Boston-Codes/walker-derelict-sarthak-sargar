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

---

## Effect B: wound smoke

### First reading: r0 (scene as built from the brief's table, commit 27085b6). Read by Claude.

Strips: `captures/wound_smoke/r0/strip.png` (light: Loading Bay floor under the lamp, 60.2 px/m) and `captures/wound_smoke/r0-dark/strip.png` (dark: Assembly Hall corner, 60.0 px/m). The emitter is a child of the parked player at chest height (1.25 m). `amount_ratio` is 0.6 (the mapping at hp 30) from frame 10, and `emitting` goes false at frame 130. Frame 25 (+0.5 s) is kept beside the brief's six frames for the "wisps within 0.5 s" claim. The smoke is faint, so each strip was also diffed against a **control run** of the same preview that never starts the smoke (`-- --control`; same seed and camera; lamp flicker and dust differ). Diff images: `docs/evidence/a6/wound_smoke_r0_{light,dark}_diff_vs_control.png` (grey = unchanged, white = brighter with smoke); changed-pixel counts are in the window ±130 px around the player.

| Frame | Brief's intent | Strip (light / dark) | Changed px vs control (light / dark) |
|---|---|---|---|
| 10 | nothing | nothing | – |
| 25 (+0.5 s) | first wisps within ~0.5 s | nothing visible | – |
| 40 (+1 s) | first wisps | nothing visible by eye; a few changed pixels on the player's head | 116 / 108 (noise level) |
| 100 (+3 s) | steady cloud | light: nothing by eye; dark: a pale crescent (~0.3 m) on the player's shoulder | 127 / 471 |
| 130 (stop) | stopped | light: a faint pale patch on the head; dark: a pale grey puff ~0.4 m over the head and shoulder | 277 / 1501 |
| 160 (+1 s after stop) | thinning | same patch, softer | 583 / 1385 |
| 190 (+2 s after stop) | gone | nothing | – |

**Reading.** Timing is right: nothing before the condition, a cloud while it holds, gone within one lifetime of the stop. But the cloud **barely reads**:
1. **It never leaves the player's silhouette.** The camera looks almost straight down (offset (0, 14.5, 6.5)), so smoke rising "a body height" rises toward the lens and stays over the player's head and shoulders on screen. With spread 25° and damping, the sideways drift is small. Over the lit floor, where the brief says it should read, there is **no** visible smoke at all. (In play a moving player leaves a trail, because `local_coords` is false. This strip is stationary, so it shows the worst case; motion is for the student's check.)
2. **Where it does show, it reads lighter, not darker.** Over the player's dark clothes and the dark corner, the unshaded (0.18, 0.18, 0.20) grey at alpha ≤ 0.5 is lighter than what is behind it. On the dark background it is more visible than on the light one: the opposite of the intent ("over the darkest corners it is meant to disappear").
3. **The size does not grow** (same billboard/keep_scale cause as Effect A): every wisp draws at 0.5 m and fades.
4. No visible ramp-up between 0.5 s and 2 s: the cloud only becomes measurable after ~3 s.

**Gaps, largest first:** (1) the cloud is barely visible at all, especially over the lit floor (its job); (2) it stays inside the silhouette from this camera; (3) inverted value on dark; (4) no growth.

My verdict (running game), r0: pending: not yet performed by the student.

### Revision B-r1: `spread` 25° → 70°

- **Biggest gap (from the r0 reading):** the smoke barely reads, and over the lit floor not at all, because from this near-vertical camera every wisp rises toward the lens and stays inside the player's silhouette.
- **The one setting:** `ParticleProcessMaterial.spread`: **25 → 70** (degrees around +Y). Nothing else changes.
- **Approved by:** Claude, pre-authorised in A6-RUNBOOK.md.
- **Prediction (before editing, committed before the change).** At 70° a wisp's sideways speed is up to 0.8 × sin 70° ≈ 0.75 m/s (r0: at most 0.34 m/s), damped by 0.3–0.6 m/s² and pushed around by turbulence. Over the 1.8 s life the widest wisps drift ~0.5–1 m sideways (30–60 px at 60 px/m), and the rise falls for those wisps (cos 70° = 0.34 of the speed).

| Frame | Predicted (light / dark) |
|---|---|
| 10 | nothing |
| 25 | nothing, or one faint wisp at the silhouette edge |
| 40 | a few faint grey wisps just outside the silhouette, 0.3–0.6 m from the centre; over the lit floor they read slightly **darker** |
| 100 | a loose cloud around the player, about 1–2 m across; changed pixels vs the control **several thousand** (r0: 127 light / 471 dark); light: dark-grey smudges on the floor around the player; dark: pale smudges, still lighter than the corner (the value inversion is not addressed) |
| 130 | the same, emitter just stopped |
| 160 | thinning, wisps further out and fainter |
| 190 | gone |

  Risk: it may read as a halo around the player rather than smoke rising from wounds. Growth is still absent (keep_scale).

- **Strips:** `captures/wound_smoke/r0/strip.png` → `r1/strip.png` (light), `r0-dark/strip.png` → `r1-dark/strip.png` (dark); diffs against fresh control runs: `docs/evidence/a6/wound_smoke_r1_{light,dark}_diff_vs_control.png`.
- **Claude's comparison (read by Claude):** the prediction **failed on its main claim**. Changed pixels against the control (±130 px window):

| Frame | r0 light / dark | Predicted r1 | r1 light / dark |
|---|---|---|---|
| 40 | 116 / 108 | a few wisps outside the silhouette | 198 / 232 |
| 100 | 127 / 471 | several thousand, a 1–2 m cloud | **150 / 796** |
| 130 | 277 / 1501 | same | 374 / 1552 |
| 160 | 583 / 1385 | thinning, further out | 651 / 1523 |
| 190 | – | gone | 41 / 234 (noise level: gone) |

  By eye, r1 is nearly the same as r0: a pale patch ~0.4 m over the head and shoulder, slightly larger on the dark background, still nothing on the lit floor. The prediction assumed the wisps keep their launch direction. They do not.
- **Why (diagnostic, run by Claude Code, not a tuning revision):** the same dark preview with `turbulence_enabled` switched off in a throwaway copy of the scene (restored at once, never committed): changed pixels 780 / 2200 / 3082 at frames 40 / 100 / 130, a cloud ~2.2 × 2.6 m, wisps visible by frame 40 (`docs/evidence/a6/diag_wound_smoke_spread70_turbulence_off.png`). Turbulence at the 4.7.2 defaults the brief leaves untouched (`turbulence_influence_min/max` = 0.1, noise scale 9.0; read from the engine) turns the wisps' velocity toward the noise field, so they wander in place instead of drifting out. With turbulence on, spread has little to act on.
- **Decision: kept.** The change moves the right way (dark +70 % at frame 100, light +20 %, no new problem), and the diagnostic shows it becomes effective once turbulence lets the wisps travel. The size of the improvement on its own is far short of the prediction; that is stated, not hidden.
- **My verdict (running game):** pending: not yet performed by the student.

### Revision B-r2: `turbulence_influence_min/max` 0.1 / 0.1 → 0.03 / 0.03

- **Biggest gap now:** the smoke still barely reads; turbulence pins the wisps in place (B-r1 diagnostic).
- **The one setting:** the turbulence influence range (min and max are one row, as `initial_velocity` min/max is): **0.1 / 0.1 → 0.03 / 0.03**. Turbulence stays on, with noise strength 0.6 as the brief says.
- **Approved by:** Claude, pre-authorised in A6-RUNBOOK.md.
- **Prediction (before editing, committed before the change).** A third of the pull toward the noise field, so the wisps keep most of their launch direction for most of a second and then bend. Between r1 and the turbulence-off diagnostic:

| Frame | Predicted changed px, light / dark (r1 → r2) | By eye |
|---|---|---|
| 40 | 198 / 232 → 300–600 / 400–700 | first wisps visible at the silhouette edge (the brief: first wisps by +1 s) |
| 100 | 150 / 796 → 400–1000 / 1500–2200 | a cloud ~1.5–2 m across around the player; on the lit floor, dark-grey smudges beside the player; on the dark background still lighter than the corner |
| 130 | 374 / 1552 → 600–1500 / 2000–3000 | the same, just stopped |
| 160 | 651 / 1523 → falling | thinning and drifting outward |
| 190 | gone | gone |

  Wisps should curve rather than run straight (turbulence still visible). Value inversion on dark and no growth: unchanged.

- **Strips:** `captures/wound_smoke/r1/strip.png` → `r2/strip.png` (light), `r1-dark` → `r2-dark` (dark); diffs `docs/evidence/a6/wound_smoke_r2_{light,dark}_diff_vs_control.png`.
- **Claude's comparison (read by Claude):**

| Frame | Predicted light / dark | r2 light / dark | Held? |
|---|---|---|---|
| 25 | – | 249 / 309 (r1: 67 / 234) | wisps now show by +0.5 s, as the brief's intent asks |
| 40 | 300–600 / 400–700 | 512 / 522 | yes |
| 100 | 400–1000 / 1500–2200 | 558 / **1050** | light yes; dark **below** the range |
| 130 | 600–1500 / 2000–3000 | 1008 / 2166 | yes |
| 160 | falling | 868 / 1856 | yes |
| 190 | gone | 29 / 160 (noise level) | yes |

  By eye: on the light strip a blue-grey haze now sits on the player's back and shoulders from frame 25 to 160, clearly more than r1. It curves (no straight columns), as predicted. **Not as predicted:** it is still mostly inside the silhouette and spreads only ~0.5 m beyond it, not a 1.5–2 m cloud. Almost every changed pixel is *brighter* than the control (light 534 brighter vs 24 darker at frame 100), so over the lit floor the smoke still adds no dark smudge. The value inversion (lighter than what is behind it) holds on both backgrounds.
- **Decision: kept.** It closes the "barely visible / too late" gap (wisps by +0.5 s, about 2–4× r1's pixels, inside the predicted range for most frames).
- **Still open after B-r2 (for the student's judgement, no further revision taken):** (1) over the lit floor it does not read darker. Its grey is lighter than the player's clothes and it rarely leaves the silhouette in this **stationary** fixture; in play the player moves and the trail (`local_coords` false) is laid over the floor, which only the student's in-play check can judge. (2) No growth over life (billboard keep_scale, as in Effect A). (3) Lighter than the dark corner instead of disappearing.
- **My verdict (running game):** pending: not yet performed by the student.

---

## Summary

| Revision | One setting | Prediction held? | Decision | Student's verdict |
|---|---|---|---|---|
| A-r1 | Puff draw `billboard_keep_scale` false → true | direction yes, spread too generous | **reverted** (puff too small to do its job) | pending: not yet performed by the student |
| A-r2 | (proposal: keep_scale true + Puff scale 0.5 / 0.9, two settings) | not run | needs a fresh approval | pending: not yet performed by the student |
| B-r1 | `spread` 25 → 70 | **no** (no 1–2 m cloud; turbulence pins the wisps) | kept (small gain, no harm) | pending: not yet performed by the student |
| B-r2 | `turbulence_influence_min/max` 0.1 → 0.03 | mostly (dark frame 100 below range; still inside the silhouette) | kept | pending: not yet performed by the student |

**Regenerate a strip** (windowed, from the repo root; replace `<abs>` with the absolute repo path):
```
godot --path godot res://previews/impact_burst_preview.tscn --write-movie <abs>/captures/impact_burst/rN/frame.png --fixed-fps 30 --quit-after 60
godot --path godot res://previews/impact_burst_preview_light.tscn --write-movie <abs>/captures/impact_burst/rN-light/frame.png --fixed-fps 30 --quit-after 60
godot --path godot res://previews/wound_smoke_preview.tscn --write-movie <abs>/captures/wound_smoke/rN/frame.png --fixed-fps 30 --quit-after 200
godot --path godot res://previews/wound_smoke_preview_dark.tscn --write-movie <abs>/captures/wound_smoke/rN-dark/frame.png --fixed-fps 30 --quit-after 200
python tools/strip_sheet.py <frames dir> <out.png> <cx> <cy> <half> <frame list> "<label>"   # STRIP_SCALE=2|3
```
Add `-- --control` to a wound smoke preview for the no-smoke plate the diffs use; `-- --repeat=4` to the impact burst preview for a held-trigger stream. Delete the `frame.wav` Movie Maker writes; it is never committed.
