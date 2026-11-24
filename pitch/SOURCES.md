# SOURCES — DERELICT pitch film (A8)

## Who wrote what

- **`PROJECT-BRIEF.md`** was written by Claude from the student's three answers (quoted verbatim in it) and the repository's records. Its dated revision (2026-11-23) was written by Claude Code after checking every claim against the tags.
- **`A8-RUNBOOK.md`** (in the kit, not committed) was written by Claude.
- **Written by Claude Code:**
  - the film's script (narration), the beat sheet and the cards
  - the card and media builder `make_pitch.py`, and `narration_qc.py` (adapted from the A7 film)
  - every document in `pitch/`
- **Captures:** the play clips are scripted captures made by Claude Code for the A6 and A7 films. The fixture strips were made by Claude Code in A6.
- **The game's shaders, effects and animation** were written by Claude under the student's direction (see `CLAUDE.md`, Authorship, and each assignment's `TEST-REPORT.md`). The film says "I directed Claude Code to build them", never "I wrote".
- **The student's own contributions:**
  - the three answers in `PROJECT-BRIEF.md`
  - the A2 author playtest
  - the A5 playtest notes (`docs/archive/HUMAN-CHECK-NOTES-a5.md`, verbatim)
  - the earlier films' upload links
  - The student's A6 and A7 human checks are still **pending: not yet performed by the student**.

## What was used

| Item | Origin | Licence |
|---|---|---|
| Scripted play clips `burstplay_raw.mp4`, `smokeplay_raw.mp4` | A6 film captures (`youtube/claude-liam-derelict-a6-gamedev/captures/routes/film_capture.gd`, game revision `f4af1c4`), real game, scripted input | the project's own |
| Scripted play clip `reloadplay_raw.mp4` | A7 film capture (`youtube/claude-liam-derelict-a7-gamedev/captures/routes/film_capture.gd`, game revision `0d8710e`) | the project's own |
| Fixture strips `captures/impact_burst/r0-light/strip.png`, `r1-light/strip.png` | A6, committed at `fe6044a` and `0788794` (tag `a6`) | the project's own |
| Log lines on B07 | `docs/evidence/a7/final/test_pistol_reload_edges_60fps.log` (`887266f`) | the project's own |
| The game in the clips: art, models, sounds | credited in the repository's root `SOURCES.md` and `ATTRIBUTION.md` | as listed there |
| Narration voice | Kokoro-82M, voice `am_onyx`, run locally (kokoro-onnx) | Apache-2.0 (model weights) |
| Fonts | EB Garamond (brutalist.art `runtime/fonts`, SIL OFL 1.1); Segoe UI and Consolas (Windows system fonts, used to render the cards) | as listed |
| Pipeline | brutalist.art `compile.py`, `generate_audio_kokoro.py`, `final_frame_check.py` (unmodified); the A7 Windows launcher `run_compile_win.py` | the course toolkit |

No third-party footage, images, music or stock assets. No paid API, no upload by Claude Code, no credentials.
