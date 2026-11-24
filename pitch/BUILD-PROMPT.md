# BUILD-PROMPT — how the pitch film is rebuilt

Written by Claude Code. The folder `pitch/` is the reel folder. Run from the repository root in Git Bash, with `PYTHONUTF8=1`. Needs Python with Pillow, numpy and kokoro-onnx, ffmpeg on PATH, and brutalist.art at `C:\Users\sarth\brutalist.art`.

**The prompt.** The film was made by Claude Code from this one instruction by the student: "Extract C:\Users\sarth\Downloads\a8-kit.zip to C:\Users\sarth\a8-kit, read A8-RUNBOOK.md in it, and execute it fully and autonomously." `A8-RUNBOOK.md` and `PROJECT-BRIEF.md` were written by Claude.

## Commands

1. **Captures** (not committed: mp4). Copy the three clips into `pitch/captures/`:
   - `burstplay_raw.mp4` and `smokeplay_raw.mp4`: from the A6 film. To regenerate, follow `youtube/claude-liam-derelict-a6-gamedev/BUILD-PROMPT.md`, step 1.
   - `reloadplay_raw.mp4`: from the A7 film. To regenerate, follow `youtube/claude-liam-derelict-a7-gamedev/BUILD-PROMPT.md`, step 1.

   SHA-256 of the copies used:
   - `burstplay_raw.mp4` `4b5ac38c175f480802e8d6bb9916554b84ab463931c3b976c3ffc94cb12f53dd`
   - `smokeplay_raw.mp4` `4f598569be5b9126740612fa1a6df572fb757d628bcd7ee416d84c59fb1cecd4`
   - `reloadplay_raw.mp4` `d22376852656001a8a148c4edbfcf7baa45986d7099cd3c351b8c258f71d06cb`
2. **Narration:**

   ```
   python /c/Users/sarth/brutalist.art/runtime/scripts/generate_audio_kokoro.py pitch
   ```

   Then regenerate B03 and B10 more slowly:

   ```
   python …/generate_audio_kokoro.py pitch --only B03 --speed 0.82
   python …/generate_audio_kokoro.py pitch --only B10 --speed 0.9
   ```

   Then `python pitch/narration_qc.py` (pace and clipping table).
3. **Cards and framed clips:** `python pitch/make_pitch.py` writes `pitch/media/B01..B13`. It reads each beat's narration length, so run it after step 2.
4. **Review cut:**

   ```
   python youtube/claude-liam-derelict-a7-gamedev/run_compile_win.py pitch --review --fps 30 --height 1080
   ```

   This writes `pitch/derelict-a8-pitch-slate.mp4` and the contact sheet `pitch/_qc/`.
5. **Frame gate:**

   ```
   python /c/Users/sarth/brutalist.art/runtime/qc/final_frame_check.py pitch --mp4 pitch/derelict-a8-pitch-slate.mp4
   ```
6. **4K master.** Run it alone on the machine. First check free memory (at least 4 GB), and keep a watchdog that stops the job below 2 GB free (`powershell -File pitch/watchdog.ps1`, started alongside; it logs to `pitch/watchdog.log`):

   ```
   python pitch/run_compile_win.py pitch --height 2160 --fps 30 --out pitch/exports --low-mem-tight --preset-medium --threads-1
   ```

   compile.py runs its own final gates on the candidate (beat_lint, gate_shape, render-integrity `verify_output`, `final_frame_check.py`) before it writes `pitch/exports/derelict-a8-pitch.mp4` and `.verified.json`.
   `--threads-1` comes from A8's own copy of the A7 launcher. The first master attempt, without it, was stopped by the watchdog at 74% (A8-LOG Phase 5).
7. Copy `pitch/_qc/REPORT.md` and the contact sheet into `pitch/gates/`, and record the master's SHA-256 in `README.md`.

Never commit mp4, mp3 or wav; `.gitignore` covers `pitch/captures/`, `pitch/clips/` and `*.mp3`/`*.mp4`.
