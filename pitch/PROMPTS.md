# PROMPTS — DERELICT pitch film (A8)

Written by Claude Code.

- **No image, video or music generation was used.** Every card is drawn by `make_pitch.py`. Every play clip is a real scripted capture of the game, from the A6 and A7 films.
- **Narration:** local Kokoro-82M (kokoro-onnx), voice `am_onyx`, through `brutalist.art/runtime/scripts/generate_audio_kokoro.py`. The text is each beat's `narration_text` in `beat_sheet.json`. B03 was regenerated at `--speed 0.82` and B10 at `--speed 0.9`, because their first takes were faster than 3.6 words/s (`narration_qc.py`).
- **The prompt that produced this film:** the student asked Claude Code to "Extract C:\Users\sarth\Downloads\a8-kit.zip to C:\Users\sarth\a8-kit, read A8-RUNBOOK.md in it, and execute it fully and autonomously." `A8-RUNBOOK.md` and `PROJECT-BRIEF.md` were written by Claude.
- No Claude response is shown in the film.
