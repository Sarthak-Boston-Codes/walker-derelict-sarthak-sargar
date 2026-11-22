# BUILD-PROMPT: how this film is (re)built

Folder: `youtube/claude-liam-derelict-a7-gamedev/`. Same pipeline and Windows launchers as the A6 film. Use `PYTHONUTF8=1` throughout, and put `C:\Users\sarth\nodejs` on PATH for Remotion. Written by Claude Code.

1. **Captures** (windowed, one at a time, from `godot/`): `MODE=keyplay|reloadplay OUT=<abs>/captures/frames/<mode> godot --path . --fixed-fps 30 --script <abs>/youtube/claude-liam-derelict-a7-gamedev/captures/routes/film_capture.gd` → `logs/film_capture_<mode>.log`. Then `ffmpeg -framerate 30 -i captures/frames/<mode>/f%05d.jpg -c:v libx264 -pix_fmt yuv420p -crf 16 captures/<mode>_raw.mp4`.
2. **Cards:** `python captures/routes/make_cards.py` → `media/B02,B05,B07,B13,B14,B15,B16,B17.png` (the fixture strips come from the repo's `captures/`).
3. **Sheet + evidence:** `python build_sheet.py`, then `python <brutalist>/skills/make/godot-gamedev/scripts/verify_gamedev.py . --game ../../godot`.
4. **Narration:** `python <brutalist>/runtime/scripts/generate_audio_kokoro.py .`, then `python narration_qc.py` (bakes B01's 0.8 s lead).
5. **Conform:** `python conform_clips.py` (labelled HOLD, never slowed; B09 gets a labelled ×4 zoom of the HUD keycard row), then `python build_sheet.py` again and the checker.
6. **Scenes:** `python run_remotion_win.py . --only <beat>` for each Remotion beat, one at a time (pilot: B04).
7. **Review cut:** `python run_compile_win.py . --review --fps 30 --height 1080`.
8. **Final:** `python <brutalist>/runtime/qc/final_frame_check.py . --mp4 <cut>`, then `python run_compile_win.py . --height 2160 --fps 30 --out exports/landscape --low-mem-tight`, alone on the machine, under a watchdog that stops the job below 2 GB free (the A6 4K compile was once killed for low memory). Record the master's SHA-256. No mp4/mp3/wav is committed.

## Memory caps on the final 4K encode (A7, Claude Code; approved by the student)

The final step re-encodes the whole film at 3840×2160 with libx264 `-preset slow -crf 16`. On this 16 GB machine:
1. Uncapped: free memory fell to 387 MB; stopped by the watchdog (all 21 beat clips had encoded and are cached).
2. `--low-mem` (encoder `-threads 4 -x264-params rc-lookahead=20`): fell to 2,026 MB; stopped.
3. `--low-mem-tight` (decoder `-threads 2`, encoder `-threads 2 -x264-params rc-lookahead=10`, `-preset slow`, CRF 16): run next.
4. If 3 is stopped below 2 GB: `--preset-medium` (the same caps plus `-preset medium`, CRF 16), once; no further caps.
All four are launcher-only (`run_compile_win.py` wraps `compile.sh` for that one command); brutalist.art's `compile.py` is unmodified. A7-LOG.md Phase 11 records which attempt produced the master.
