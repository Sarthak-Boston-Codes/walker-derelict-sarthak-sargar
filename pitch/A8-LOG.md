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
