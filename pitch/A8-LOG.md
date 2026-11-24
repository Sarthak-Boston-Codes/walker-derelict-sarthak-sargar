NEEDS ME: upload C:\Users\sarth\Game Development\walker-a8\pitch\exports\derelict-a8-pitch.mp4 to OneDrive and send the link.

# A8-LOG.md — Assignment 8 (final project pitch film), work log

Written by Claude Code while executing `A8-RUNBOOK.md`. The runbook was written by Claude; the kit was extracted to `C:\Users\sarth\a8-kit` (2 files: `A8-RUNBOOK.md`, `PROJECT-BRIEF.md`). No game code is changed. Nothing here is a student check.

## Phase 0 — worktree and brief (2026-11-23)

- Worktree `C:\Users\sarth\Game Development\walker-a8`, branch `a8-pitch`, clean at `bafe6eb` (top of `refs/heads/a7-animation`).
- `pitch/PROJECT-BRIEF.md` committed alone and unedited (`96ddf54`).
- Every claim was verified against the tags; results and corrections are a dated revision in `pitch/PROJECT-BRIEF.md`. Main findings:
  - `a3` predates `a2-redo`.
  - "Every layer … mutations" holds only from `a5` on.
  - A-r1 was reverted, so the pending fix is A-r2.
  - The student's A5 playtest exists (verbatim, 2026-10-29); every A6 and A7 human check is pending.
- **Fresh test run stopped for low memory.** An import plus eight suites ran in the background. Claude Code stopped the job because the machine was critically low on memory; that says nothing about the tests.
  - Decision: do not restart it.
  - The test-run card uses real lines from the committed final A7 logs, `docs/evidence/a7/final/*.log` (committed at `887266f`, 2026-11-20).
  - Afterwards: 6.4 GB free, no Godot or ffmpeg process running.

## Phase 1 — the toolkit

- **No `show-tell` skill** exists under `C:\Users\sarth\brutalist.art\skills\` (it holds `make/`, `SILENT-MODE.md` and `TIERS.md`).
  - Route taken: the A7 film's pipeline. That is `brutalist.art/runtime/scripts/compile.py` through the A7 launcher `run_compile_win.py`, Kokoro `am_onyx`, and the `final_frame_check.py` gate.
  - The show-tell idea (one drawn picture per beat, little on-screen text, the narration explains) is followed by hand.
- **No Remotion, no walker opening, no outro (ground rule 3).**
  - Why: the `ClaudeComposerAsk` cold open carries `@NikBearBrown`, and `OUTRO-LOCK.md` locks the instructor's handle onto every `claude-liam-*` slug.
  - So the slug is `derelict-a8-pitch`, not `claude-liam-*`, and the palette is not `claude`, so `lint_skin`'s outro rule does not apply.
  - Every beat is a PIL card or a framed capture made by `pitch/film/make_pitch.py`. The last beat is a plain end card.
- **`verify_gamedev.py` is not run.** It is the godot-gamedev source-coverage checker and checks displayed code excerpts against the source. This film shows no code.
  - The gates that apply are compile.py's own render-integrity checks (`verify_output`: decodable streams, exact duration, audible audio) and Gate V (`final_frame_check.py`). Both run on the review cut and on the master.
- **No new game captures.** Memory is short (one background job was already stopped), and real scripted-play clips from the A6 and A7 films exist on disk (labels below). They are reused and never retimed; held frames are labelled HOLD.

## Phase 2 — beat sheet (2026-11-23)

- `pitch/` is the reel folder, so `pitch/beat_sheet.json` is the sheet the toolkit reads and stamps.
- 13 beats, one idea each, in the runbook's order. Beat 6 is split into B06 (the five skill areas) and B07 (the test-run card).
- Slug `derelict-a8-pitch`, `kind: pitch`, palette `derelict-page`.
- `.gitignore` now also covers `pitch/**/*.wav`, `pitch/clips/`, `pitch/captures/` and `pitch/_qc/frames/`.

## Phase 3 — captures and cards

- Clips copied into `pitch/captures/` (not committed; SHA-256 in `BUILD-PROMPT.md`):

| Clip | Source | Label on screen |
|---|---|---|
| `burstplay_raw.mp4` (8.0 s) | A6 film, game `f4af1c4`, from `walker-derelict-sarthak-sargar/youtube/claude-liam-derelict-a6-gamedev/captures/` | SCRIPTED CAPTURE: real fire input; the zombies are placed by the capture script |
| `smokeplay_raw.mp4` (11.1 s) | A6 film, game `f4af1c4`, same folder | SCRIPTED CAPTURE: real swipes, walk, pause and medkit |
| `reloadplay_raw.mp4` (10.3 s) | A7 film, game `0d8710e`, from `walker-a7/youtube/claude-liam-derelict-a7-gamedev/captures/` | SCRIPTED CAPTURE: real R, fire and Esc |

- Fixture strips: `captures/impact_burst/r0-light/strip.png` (`fe6044a`) and `r1-light/strip.png` (`0788794`), both in tag `a6`.
- `make_pitch.py` draws the cards in the A5–A7 card style (title-safe margins, 4K), on a dark page with no instructor footer.
  - B07's lines are copied verbatim by line number from `docs/evidence/a7/final/test_pistol_reload_edges_60fps.log`. The 98 PASS / 0 FAIL counts are computed from that file at build time.
- Card review (Claude Code, on a contact sheet):
  - B05 first showed per-step times (10 s, 20 s). These were invented targets, so they were removed; only "within 60 s (target)" stays, under a WILL stamp.
  - The box cards' text was enlarged.

## Phase 4 — narration

- Kokoro `am_onyx`, 13 beats, first person.
- QC (`narration_qc.py`, adapted from the A7 film without its outro line): no clipping (every peak at −1.3 dB or lower).
  - B03 (3.98 words/s) and B10 (3.66) were over 3.6. B03 was trimmed and regenerated at `--speed 0.82`, B10 at `--speed 0.9`.
  - All beats then fall between 2.59 and 3.56 words/s. Narrated total 197.0 s (3:17).
- **Ground-rule re-read**, by Claude Code against rules 1–3. Two sentences stated untimed things as fact and were reworded:
  - B03, "a small game where you can check how I work in a few minutes" → "built so that you can check …"
  - B04, "small enough to open in a minute" → "meant to be small enough …"
  - Both were regenerated. A first attempt at the edit was overwritten by the review build's stamp of `beat_sheet.json`, and was reapplied afterwards.
- One row per sentence is in `HONESTY-CHECK.md`.

## Phase 5 — render and gates

- **Review cut, 1080p:** `run_compile_win.py pitch --review --fps 30 --height 1080` → `pitch/derelict-a8-pitch-slate.mp4`, 197.2 s, 13/13 slots filled. compile.py's render-integrity checks passed: decodable audio and video, duration equal to the timeline, audible.
  - compile.py's skin lint printed "NO RENDERABLE BEATS". That rule assumes Remotion or Manim scenes; here every slot is filled from `media/`, so it does not apply.
- **Gate V on the first review cut: FAILED, 4 BLOCKER, 4 MAJOR.**
  - Edge-bleed on B01 (the drawn flashlight cone) and on B05 (the last caption crossed the right title-safe edge).
  - Low contrast on B02 and B03 (0.26–0.27 < 0.30): dark game footage on a dark page.
  - Fixes: a shorter cone, tighter step spacing, and, for B02 and B03, `qc.contrast_regions` on the title and label text, with a written `contrast_reason`. That is the gate's own mechanism; its empty-frame, fill and safe-area checks stay active.
  - Re-rendered: **0 BLOCKER, 0 MAJOR** (`pitch/gates/review/REPORT.md`, contact sheet beside it). Claude Code read the contact sheet as the gate asks.
- **4K master:** started with 6.6 GB free, alone on the machine (the student closed Chrome and Discord first). Settings from the start: `--low-mem-tight --preset-medium` (decoder and encoder at 2 threads, rc-lookahead 10, `-preset medium`, CRF 16), under a watchdog that stops ffmpeg below 2 GB free.
  - **Attempt 1 (22:35–22:59): stopped by the watchdog** at frame 4383 of about 5917 (74%), with 1,968 MB free. Free memory sat near 2.2 GB for most of the run. All 13 beat clips had encoded and are cached; no master was written (`master_build_run1.log`, not committed).
  - The A7 ladder ended at these settings, so the student was asked how to continue. The student chose a single encoder thread. A8's own copy of the launcher, `pitch/run_compile_win.py`, adds `--threads-1`: decoder and encoder at `-threads 1`, with CRF 16, `-preset medium` and rc-lookahead 10 unchanged. Quality is identical; only speed and memory change. The A7 launcher is untouched.
  - **Attempt 2 (23:37–23:52): completed.** `--low-mem-tight --preset-medium --threads-1`, under the same 2 GB watchdog; the lowest free memory was 2,122 MB.
- **Master:** `pitch/exports/derelict-a8-pitch.mp4`, 3840 × 2160, 30 fps, h264 + aac, 197.233 s, 28,068,664 bytes, SHA-256 `1696c3bd0e3e24e44126bd0f1aaab74b7dbc91b544ddc831df6f848504f74a57`.
  - compile.py's final preflight passed: paperwork (GATE F), `beat_lint.py`, `gate_shape.py`.
  - Render integrity passed: `verify_output` checks decodable streams, the exact duration and audible audio, plus an ffmpeg `-xerror` full decode.
  - **Gate V on the master: 0 BLOCKER, 0 MAJOR.**
  - The sheet and every input were re-hashed unchanged after the encode, and `derelict-a8-pitch.verified.json` was written (status `ready`).
  - Reports are in `pitch/gates/master/`.

## Phase 6 — documents

- Written by Claude Code: `README.md` (film fields filled; the link is pending), `BUILD-PROMPT.md`, `SOURCES.md` and `FRICTIONAL.md`.
- `FRICTIONAL.md` takes its dated entries from the commits and this log, labels the authors, and ends with an empty "Student's own notes".
- `PROJECT-BRIEF.md` now ends with the two final lists, as a dated entry.
- Committed in the order the work happened: the brief (`96ddf54`), the verification (`4dfc8ea`), the beats and the review cut (`5f124ff`), then the master and the documents.
