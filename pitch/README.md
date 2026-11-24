# DERELICT — final project pitch (CSYE 7270, Assignment 8)

- **Student:** Sarthak Sargar
- **Working title:** DERELICT, a small top-down 3D zombie shooter (Godot 4.7.2, Forward+)
- **Target roles:** gameplay programmer; tools programmer
- **Runtime:** 3:17 (197.2 s), 13 beats
- **Film:** `derelict-a8-pitch.mp4`, 3840 × 2160, 30 fps, h264 + aac, 28,068,664 bytes
  - SHA-256 `1696c3bd0e3e24e44126bd0f1aaab74b7dbc91b544ddc831df6f848504f74a57`
  - **Link:** pending, to be uploaded by the student

The film answers the seven pitch questions in order. Every claim is either something that exists at a tag (`HONESTY-CHECK.md`) or is said as "will". Every visual is labelled on screen: scripted capture, fixture, or constructed on screen. No instructor name, handle or credit line appears.

## What is here

| File | What it is |
|---|---|
| `PROJECT-BRIEF.md` | The brief, written by Claude from the student's three answers. Its dated revisions were written by Claude Code after checking the tags. It ends with the Exists today and Will exist lists. |
| `beat_sheet.json` | The 13 beats: narration, shots, labels, measured durations |
| `HONESTY-CHECK.md` | Every narration sentence, with its evidence or "will" |
| `BUILD-PROMPT.md` | The prompt and the commands that rebuild the film |
| `SOURCES.md` | What was used, what was made, who made it, licences |
| `FRICTIONAL.md` | Dated friction entries from the commits and the log; ends with the student's own (empty) notes |
| `A8-LOG.md` | Claude Code's work log, phase by phase |
| `gates/` | `review/` and `master/` Gate V reports and contact sheets; the master's `.verified.json`; the narration QC table |
| `FACTCHECK.md`, `SHOTLIST.md`, `PROMPTS.md` | The toolkit's required paperwork |
| `make_pitch.py`, `narration_qc.py`, `run_compile_win.py` | The builder and launchers; `media/*.png` are the cards they made |

## Rebuild the film

See `BUILD-PROMPT.md`. In short, from the repository root:
1. Copy the three capture clips into `pitch/captures/`.
2. Generate the narration with Kokoro (`am_onyx`).
3. Run `python pitch/make_pitch.py`.
4. Make the review cut and run the frame gate.
5. Make the 4K master with `python pitch/run_compile_win.py pitch --height 2160 --fps 30 --out pitch/exports --low-mem-tight --preset-medium --threads-1`, alone on the machine, under a 2 GB free-memory watchdog.

No mp4, mp3 or wav is committed.

## Authorship

The game's shaders, effects and animation were written by Claude under the student's direction. The film's script, cards, documents and captures were written by Claude Code. The narration speaks as the student. The student's human checks of the A6 effects and the A7 animation are still pending.
