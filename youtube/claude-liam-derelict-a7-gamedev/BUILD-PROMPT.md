# BUILD-PROMPT: how this film is (re)built

Folder: `youtube/claude-liam-derelict-a7-gamedev/`. Same pipeline and Windows launchers as the A6 film. Use `PYTHONUTF8=1` throughout, and put `C:\Users\sarth\nodejs` on PATH for Remotion. Written by Claude Code.

1. **Captures** (windowed, one at a time, from `godot/`): `MODE=keyplay|reloadplay OUT=<abs>/captures/frames/<mode> godot --path . --fixed-fps 30 --script <abs>/youtube/claude-liam-derelict-a7-gamedev/captures/routes/film_capture.gd` → `logs/film_capture_<mode>.log`. Then `ffmpeg -framerate 30 -i captures/frames/<mode>/f%05d.jpg -c:v libx264 -pix_fmt yuv420p -crf 16 captures/<mode>_raw.mp4`.
2. **Cards:** `python captures/routes/make_cards.py` → `media/B02,B05,B07,B13,B14,B15,B16,B17.png` (the fixture strips come from the repo's `captures/`).
3. **Sheet + evidence:** `python build_sheet.py`, then `python <brutalist>/skills/make/godot-gamedev/scripts/verify_gamedev.py . --game ../../godot`.
4. **Narration:** `python <brutalist>/runtime/scripts/generate_audio_kokoro.py .`, then `python narration_qc.py` (bakes B01's 0.8 s lead).
5. **Conform:** `python conform_clips.py` (labelled HOLD, never slowed; B09 gets a labelled ×4 zoom of the HUD keycard row), then `python build_sheet.py` again and the checker.
6. **Scenes:** `python run_remotion_win.py . --only <beat>` for each Remotion beat, one at a time (pilot: B04).
7. **Review cut:** `python run_compile_win.py . --review --fps 30 --height 1080`.
8. **Final:** `python <brutalist>/runtime/qc/final_frame_check.py . --mp4 <cut>`, then `python run_compile_win.py . --height 2160 --fps 30 --out exports/landscape`, alone on the machine (the A6 4K compile was once killed for low memory). Record the master's SHA-256. No mp4/mp3/wav is committed.
