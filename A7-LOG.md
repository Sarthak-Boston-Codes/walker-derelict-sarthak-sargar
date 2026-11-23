Film uploaded by the student (Phase 12); link in README.md and SUBMISSION.md.

# A7-LOG.md — Assignment 7 (two animations), work log

Written by Claude Code while executing `A7-RUNBOOK.md` (written by Claude; kit extracted to `C:\Users\sarth\a7-kit`). Every approval below is Claude's, pre-authorised in A7-RUNBOOK.md. Nothing here is a student check; the student's checks live in `HUMAN-CHECK-NOTES.md` and read "pending" until the student gives them.

## Phase 0 — worktree, wrapper, baseline (2026-11-20)

- Worktree `C:\Users\sarth\Game Development\walker-a7`, branch `a7-animation`, clean at `020fc24` (top of `a6-effects`).
- Kit extracted from `C:\Users\sarth\Downloads\a7-kit.zip` to `C:\Users\sarth\a7-kit` (4 files: `A7-RUNBOOK.md`, `CHANGE-BRIEF.md`, `scripts/run-test.sh`).
- `scripts/run-test.sh` replaced with the kit's version (`f7b004f`). The only behavioural difference: a log line `Failed loading resource` now also fails the run.
- A6 `TEST-REPORT.md`, `SUBMISSION.md`, `HUMAN-CHECK-NOTES.md`, `TUNING.md`, `A6-LOG.md` moved to `docs/archive/*-a6.md` (`95a6326`).
- Import: `"$GODOT" --headless --path godot --import`, exit 0, 27 s.
- Baseline, every existing test through the wrapper in its pinned mode (logs copied to `docs/evidence/a7/baseline/`):

| test | mode | exit | count |
|---|---|---|---|
| game3d_smoke_test.tscn | 60 | 0 | `PASS: 0 failure(s)`, 27 `ok` lines |
| game3d_soak_test.tscn | 60 | 0 | PASS |
| showcase_3d_test.tscn | 60 | 0 | `PASS: 0 failure(s)`, 3 rows ok |
| trigger_count_test.tscn | 60 | 0 | `PASS: 0 failure(s)`, 5 rows ok |
| low_ammo_test.gd | 30 / 60 / 144 | 0 / 0 / 0 | 36 / 36 / 36 PASS, 0 FAIL |
| test_materials.gd | 60 | 0 | 75 PASS |
| calibrate_normal_map_check.gd | 60 | 0 | 1 PASS |
| test_impact_burst_config.gd | 60 | 0 | 109 PASS |
| test_impact_burst_state.gd | 60 | 0 (see finding) | 35 PASS |
| test_wound_smoke_config.gd | 60 | 0 | 40 PASS |
| test_wound_smoke_state.gd | 60 | 0 | 22 PASS |

These equal the A6 final counts in `docs/evidence/a6/final/`. **Count convention for this whole log:** "PASS" counts are `grep -c '^PASS'` on the log, which includes the final `PASS: 0 failure(s)` line, the same way the A6 final counts were taken.

**Finding (flaky A6 test):** the first run of `test_impact_burst_state.gd` after the fresh import exited 1 with 4 FAIL lines: "two hits from two real shots (1)", "the second hit came -1 frames". The next three runs passed 35/35. The A2 two-hit section depends on the second real shot hitting a moving zombie; on the first run only one shot registered a hit. Not caused by A7 (no game file changed yet). Recorded as a known flaky check; the baseline is the passing count. If it recurs later, it is re-run once and both results are logged.

## Phase 1 — the brief (2026-11-20)

- Kit brief committed alone (`b0f7569`), then the reference check as a dated revision (`f7cf2f0`). Findings: every `player.gd` reference below line 14 is +2 (A6 added `:13-14`); `hud.gd` process mode is `:52`, keycard element `:102-104`, setter `set_keycard()` `:327`, called from `game.gd:135`; a death mid-reload zeroes `_reload_left` and emits only `died` (no `reload_changed(false)`, no refill).
- **Decision:** `HudAnim` reads the keycard state through `_key_label.visibility_changed` + `_key_label.visible`, so `set_keycard()` is not edited (the brief allows edits only for instancing).

## Phase 2 — CLAUDE.md (2026-11-20)

- No `AGENTS.md` exists, so no `@AGENTS.md` line. Draft committed unedited (`Phase 2: CLAUDE.md draft`), 76 lines. Review: every file/line reference checked against the tree (`project.godot:14/15/25-28/91`, `run-test.sh:23`, `game.gd:57-59/82-87/135`, `hud.gd:52/102-104/327`, `player.gd` lines). One correction committed separately: files not yet built are marked as plan.

## Phase 3 — pins (2026-11-20)

- `godot/tests/test_pins_player.gd`, 60 fps: **19 PASS lines (18 checks + the summary line), 0 FAIL** (the Phase 3 commit message says "20 PASS"; that was a miscount, corrected here) (log `docs/evidence/a7/pins/test_pins_player_60fps.log`).
  - State order READY, FIRE, RELOAD, READY, FIRE.
  - FIRE_INTERVAL: shots 9 frames apart (0.150 s: 0.14 s rounded up to whole 60 fps frames, because `_cooldown` is checked once per process frame).
  - RELOAD_TIME: `reload_changed(true)` frame 44 → `(false)` frame 119 = 75 frames = 1.2500 s.
  - Refill (mag 10 → 15, reserve 60 → 55) reported on the frame of `reload_changed(false)`; fire held 20 frames mid-reload fires nothing; a second R press does not re-emit `reload_changed(true)`.
- First run found a test-side fact: a parsed key event is seen by `is_action_just_pressed` on the **next** process frame (R parsed after frame 43, reload starts on frame 44). The test now waits for the signal; no pin changed.
- **Watched run** (windowed, Movie Maker, `--fixed-fps 60`, same script; `--debug-collisions` does not apply, the pins are HUD/ammo facts, not collisions): exit 0, 0 failures, 138 frames. Seven frames kept in `docs/evidence/a7/pins/watched/` with the run log. Reading (read by Claude): movie frame = log frame + 11. Movie frame 14 shows AMMO 15 / 60, frame 15 shows 14 / 60 (log: first shot at frame 4); frame 54 no reload bar, frame 55 the reload bar appears empty (log: `reload_changed(true)` frame 44); frame 129 shows 10 / 60 with the bar full, frame 130 shows 15 / 55 (log: refill at frame 119); frame 132 shows 14 / 55 (log: first shot after the reload, frame 121). The log lines and the drawn HUD agree frame for frame.

## Phase 4 — the sprite clip (2026-11-20)

- `tools/make_keycard_sheet.py` → `godot/art/keycard_sheet.png` (512 × 64, SHA-256 `df945a6c…`), committed unedited with its `.import`. First draft used Lanczos resampling, which rang into the transparent margin (bounding boxes 58 px wide for a 52 px card); switched to box filtering before the first commit, so the committed PNG is the script's only committed output.
- **Finding (brief):** "cells 4 to 7 show the back face" cannot be a turning card (cell 7 = 315° shows the front) and would pop twice per loop, once on the seam. Generator draws the back on cells 3–5; dated brief revision 2026-11-20 (sheet).
- `ATTRIBUTION.md` A7 section. `keycard_icon.tscn` (root `KeycardIconRig` Node2D, children `KeycardIcon` Sprite2D and `AnimationPlayer`, so the track path is literally `KeycardIcon:frame`). `keycard_spin.tres` as resource text.
- `test_keycard_spin_readback.gd` at 60: **32 PASS lines, 0 FAIL**.

## Phase 5 — the rig clip (2026-11-20)

- `pistol_rig.tscn`: `PistolRig` → `Body` (pivot at the top of the grip) → `Mag`, `Slide`, with Polygon2D parts. **Decision:** `Slide` and `Mag` are children of `Body` so the tilt carries them; the brief's track names become paths from the root: `Body:rotation`, `Body/Slide:position:x`, `Body/Mag:position:y`.
- `pistol_reload.tres` from the key table (frame → time listed in the file header and printed by the test: f6 0.25, f12 0.5, f18 0.75, f21 0.875, f24 1.0, f30 1.25). Easing as key transitions on the key that starts the segment: 2.0 ease-in, 0.5 ease-out, −2.0 in-out.
- `test_pistol_reload_readback.gd` at 60: **57 PASS lines, 0 FAIL** (first run 2 FAIL from exact float compares of seeked pose values in the test; changed to a 1e-3 tolerance, no clip change).

## Phase 6 — wiring plan (2026-11-20, before editing)

Approved by Claude, pre-authorised in A7-RUNBOOK.md (respects the brief's boundaries and the one-authority rule).

1. New `godot/game3d/hud_anim.gd` (`HudAnim`, a `Node`), with a static `attach(hud, player)` like A6's drivers. It instances `keycard_icon.tscn` as a child of the HUD's `_key_label` (to the right of the text, half size) and `pistol_rig.tscn` inside a new bottom-right-anchored `Control` under the HUD's root control. It owns two state tables as constants (`RIG_TABLE`: HOLD/RELOAD/DEAD; `KEY_TABLE`: HIDDEN/SPINNING) and moves between states only through them.
2. Inputs it reads: `player.reload_changed`, `player.died`, `hud._key_label.visibility_changed` (+ `.visible`). It writes only: `play()`/`stop()`/`seek()` on the two `AnimationPlayer`s (RESET pose applied by playing `RESET`, seeking 0 with update, stopping) and `KeycardIcon.visible`. It never writes game state.
3. Existing files: `game.gd` only, three lines (a `preload` const, a `var hud_anim`, one `HudAnim.attach(hud, player)` after the A6 attach lines). `hud.gd` is **not** edited (smaller than the brief allows).
4. A `reload_changed(true)` while already in RELOAD is ignored (the game never sends one; the edge test proves the clip is not restarted).
5. Tests: `test_hud_anim_structure.gd` (tables against resources and the brief, one writer by source scan, autoplay/process mode/callback mode, `current_animation`), `test_hud_anim_state.gd` (real R / Escape key events and real fire button, real zombie contact for death, real walk onto the keycard).

## Phase 6 — wiring, implemented (2026-11-20)

- Agent build `25dd3bd`: `hud_anim.gd` + 3 lines in `game.gd`; `hud.gd` not edited. Tests `58858ab`.
- `test_hud_anim_structure.gd` at 60: **51 PASS lines, 0 FAIL** (the Phase 6 test commit message says "structure 50"; 51 is the log count). `test_hud_anim_state.gd` at 60: **34 PASS lines, 0 FAIL**.
- State test facts: R → RELOAD, `current_animation` "reload"; 30 frames in, Mag y 55.8 px, Body −0.210 rad; the last clip position seen before `reload_changed(false)` was 1.2167 s (the clip runs one frame behind the game's timer; measured in Phase 9); HOLD then RESET pose. Escape mid-reload: clip position 0.3333 s held for 60 paused frames, `_reload_left` held at 0.9000 s; unpaused it continues (0.3333 → 0.3833 s) and the clip's total play time is still 1.2500 s. Keycard: SPINNING, all 8 cells seen in 1.5 s, still looping. Death by a real shambler swipe on the second reload attempt: on the `died` signal the rig is already DEAD, clip stopped, pose (0, 0, 0); no `reload_changed(false)` follows.
- What these cannot prove headless: what the rig and icon look like, legibility, registration, the feel in play (strips and the student's checks).
- Every earlier suite and the pins after wiring (`bash` run of all, 60 fps unless stated): smoke PASS (27 ok), soak PASS, showcase PASS, trigger_count PASS, low_ammo 36/36/36, materials 75, calibrate 1, impact config 109, impact state 35, wound config 40, wound state 22: **all at baseline**. Pins 19 (unchanged). `git diff --stat godot/shaders/` empty.

## Phase 7 — edges, re-pins, mutations (2026-11-20)

- `test_pistol_reload_edges.gd` at 60: **98 PASS lines, 0 FAIL**. Fire at 29–31, 59–61 and 74 is ignored, and the magazine stays put until the refill on tick 75; fire on 75 fires on tick 75 after the refill; fire on 76 fires. A second R at any of the 9 ticks starts no reload and the clip is not restarted (position = (tick − 1)/60 on every tick 1–74, error 0). Death (`take_damage(999)`, the game's own damage path, used because enemy contact cannot be timed to a tick) on any of the 9 ticks: DEAD, clip stopped and pose reset on the same tick; no refill unless the death came after tick 75. Then: tick 74 RELOAD, tick 75 HOLD at rest with the magazine refilled, and fire seen on tick 76 fires on 76.
- First edge runs failed on two test bugs: a lambda assigning an outer local (GDScript captures by value: changed to `merge`), and a "strictly rising" check that the clip's position-0 hold on tick 1 broke. That hold is the two-clocks fact, measured in Phase 9; the check is now the exact position per tick.
- Pins re-run after wiring: identical to the pre-wiring log (19 PASS lines). No pin changed.
- Mutations (`docs/evidence/a7/mutations/README.md`): 1 track property renamed → exit 1; 2 LOOP_NONE → exit 1; 3 frame key 8 → exit 1; 4 delete `.godot` + reimport → both read-backs pass (the clips are `.tres` text, nothing to reimport). The fifth (AnimatedSprite2D) does not apply.

## Phase 8 — tuning and strips (2026-11-20)

- Previews: `hud_anim_preview.gd` + 4 scenes (reload dark/light, spin light/dark). The first r0 capture used the A6 spots and put the rig over black out-of-level void. Re-scouted 6 spots with `-- --player=x,z`: dark (27, 3), light (−7, 5). The void frames were deleted, not committed.
- The capture log now records each line on `RenderingServer.frame_pre_draw`, so `drawn N` is what movie frame N shows (the first version sampled at the start of the frame, one frame behind).
- Reload r0 → r1 (`RIG_OFFSET` y −110 → −190: the magazine was clipped by the window bottom and the rig covered the controls hint) **kept**; r1 → r2 (Slide f21 −14 → −24 px, brief revision first, read-back in the same commit) **kept**. Keycard r0: 8 cells in order, no repeat across the wrap, registration within 0.5 px; no tuning. Details and per-frame predictions: TUNING.md. A windowed capture once took over 10 minutes for two 60-frame runs (normally about 1 minute each) and the shell call went to the background; it completed with exit 0 and the frames were complete. No cause found.
- All captures ran one at a time (runbook ground rule 8).

## Phase 9 — the two clocks (2026-11-20)

- `test_two_clocks.gd`: the game ends the reload on tick 75 (60 fps) / 38 (30 fps); the clip would finish on tick 76 / 39. **Largest disagreement 0.0167 s at 60 fps, 0.0333 s at 30 fps: exactly one frame**, the same on all 5 reloads. The brief predicted "under one frame". Recorded in the brief revision of 2026-11-20 (two clocks); no code change.

## Phase 10 — tests, docs (2026-11-20)

- Final run of every suite at `a48c684` (logs `docs/evidence/a7/final/`): all exit 0, earlier suites at baseline, no SHADER ERROR / SCRIPT ERROR / Failed loading resource. TEST-REPORT.md, HUMAN-CHECK-NOTES.md (empty), SOURCES.md and FRICTIONAL.md A7 sections, README.md, SUBMISSION.md (film URL and SHA-256 pending until Phase 12) and CLAUDE.md updated.

## Phase 11 — film (2026-11-20 to 2026-11-22)

- Folder `youtube/claude-liam-derelict-a7-gamedev/`, the A6 pipeline and Windows launchers (PYTHONUTF8=1, node on PATH). 21 beats, walker mode, Liam (Kokoro `am_onyx`, local, no paid call). Sources and docs committed earlier (`BUILD-PROMPT.md`, `FACTCHECK.md`, `SOURCES.md`, `COMPONENTS.md`, `SHOTLIST.md`, `RIFF.md`, `PROMPTS.md`); no mp4/mp3/wav is committed.
- Captures (windowed, one at a time, 3840×2160 SubViewport, `film_capture.gd`): **keyplay** (the player placed 3 m south of the keycard before filming, disclosed on screen; a real W key walks onto it; pickup on frame 27; the spin loops), **reloadplay** (four real reloads: fire during startup ignored, a second R during active doesn't restart, fire held through recovery fires on the end frame 186, Escape pause holds the clip at 0.3333 s). keyplay was recaptured longer (102 → 372 frames) so B09 is not a 9 s held frame.
- Gamedev evidence checker: **PASS** (23 files, 5 exact excerpts, 5 code→result pairs, contract code-then-result-v1). Pilot code scene B04 first overflowed the code panel (16 lines + a wrap); B04 and B10 were trimmed to fit (11-23, 99-112), and a stale cue pointing outside the excerpt was fixed.
- **Memory events (runbook rule 8):** (1) Claude Code's harness stopped the background Remotion queue at about 650 MB free after B18; the orphaned B19 render (ffmpeg 3.3 GB) was killed and the queue resumed only when the student asked. (2) Every later heavy job ran under a watchdog that stopped it below 2 GB free. B19's first retry hit a headless-Chrome connect timeout (memory fine) and its second was stopped at 1,608 MB; after the student closed browser tabs, B19 and B20 rendered (lowest 2,704 MB free). (3) The 1080p review cut built cleanly (lowest 4,371 MB free); its gate: 42 frames, 0 BLOCKER, 0 MAJOR. (4) The 4K final: uncapped, stopped at 387 MB free during the final whole-film encode; with the student's approval, launcher-only caps in `run_compile_win.py` (compile.py unmodified): `--low-mem` (encoder 4 threads, lookahead 20) stopped at 2,026 MB; `--low-mem-tight` (decoder 2 threads, encoder 2 threads, lookahead 10, `-preset slow`) stopped at 1,064 MB; the one allowed fallback `--preset-medium` (same caps, `-preset medium`, CRF 16) **completed**, lowest 3,807 MB free. So the master is encoded at `-preset medium`, CRF 16, not the toolkit's `-preset slow`. Recorded in BUILD-PROMPT.md.
- **Master:** `youtube/claude-liam-derelict-a7-gamedev/exports/landscape/claude-liam-derelict-a7-gamedev.mp4`, 3840×2160, 30 fps, H.264 + AAC, 319.2 s, 32,778,948 bytes, **SHA-256 `84a5f5fb5e855b509f257802ad78ad648dc2a03b9fddb7f1744858078951f0d4`** (sha256sum and compile.py's `build-state.json` agree). compile.py's 4K gate: 42 frames, 0 BLOCKER, 0 MAJOR. Game-source revision shown: `0d8710e`.
- Limit: the locked outro (B20) is silent. `ClaudeTitleOutro.tsx` in this toolkit renders no audio, and the stock jingle folder (`svg/claude/mp3/`) is not present locally; no audio was invented.
- Viewing of the master by Claude Code: contact sheet and sampled frames (code panels readable, SCRIPTED PLAY and ZOOM labels, HOLD labels, outro). The student has not watched it.

## Phase 12 — after the film link (2026-11-22)

- The student uploaded the master to OneDrive and sent the link. Link and SHA-256 (`84a5f5fb5e855b509f257802ad78ad648dc2a03b9fddb7f1744858078951f0d4`) added to README.md and SUBMISSION.md, committed as `660342c`.
- Tag `a7` made on `660342c5bbb8930123ccb8a125f7caf27a09abf0`. Pushed with `refs/heads/a7-animation:refs/heads/a7-animation` and `refs/tags/a7:refs/tags/a7`. The first push failed mid-transfer (TLS "bad record mac", remote unchanged); the retry with `http.postBuffer=524288000` succeeded. On GitHub both refs point to `660342c`; the existing tags are unchanged (`a2-redo` 48eec7e, `a3` b91201c, `a5` c076952, `a6` 9064ae8).
- Fresh clone of the `a7` tag from GitHub into `C:\Users\sarth\Game Development\derelict-a7-verify`: `--import` exit 0; every suite through `scripts/run-test.sh` in its stated mode, all 21 runs exit 0, counts equal TEST-REPORT.md (smoke 27 ok, soak PASS, showcase 3 ok, trigger_count 5 rows ok, low_ammo 36 ×3, materials 75, calibrate 1, impact config 109, impact state 35, wound config 40, wound state 22, pins 19, keycard read-back 32, reload read-back 57, structure 51, state 34, edges 98, two clocks 3 @60 and 3 @30). No log contains SHADER ERROR, SCRIPT ERROR or Failed loading resource.
- `git archive -o ..\derelict-a7.zip refs/tags/a7`: 176.6 MB, 1,149 files, SHA-256 `c730f96ee68b1ae2b48f00b12d5ae24b075d7756a023836469e689fe54dfa2c5`. Its only audio files are the game's own `godot/audio/*.wav`; no film media.
- This entry is committed after the tag, so `a7-animation` is one commit ahead of `a7`; the tag was not moved.
- Still the student's: every check in HUMAN-CHECK-NOTES.md, the verdict on each tuning revision, the "Student's own notes" in FRICTIONAL.md.
