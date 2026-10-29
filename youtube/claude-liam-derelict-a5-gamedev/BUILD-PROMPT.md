# BUILD-PROMPT — how this film is (re)built

Folder: `youtube/claude-liam-derelict-a5-gamedev/`. Same pipeline and Windows launchers as the A3 film. Use `PYTHONUTF8=1` throughout, and put `C:\Users\sarth\nodejs` on PATH for Remotion.

1. **Captures** (windowed, from the repo root):
   - `MODE=ammo|hint|sweep|twomat OUT=<dir> godot --path godot --fixed-fps 60 --script res://tools/a5_capture.gd` → `captures/frames/<mode>/` (the post-fix ammo run → `ammo_fixed/`).
   - `MODE=playclip|floor OUT=<dir> godot --path godot --fixed-fps 30 --script <abs path>/captures/routes/film_capture.gd` → `captures/frames/{playclip,floor}/`.
   - `ffmpeg -framerate 30 -i captures/frames/playclip/f%05d.jpg -c:v libx264 -pix_fmt yuv420p -crf 16 captures/playclip_raw.mp4`.
2. **Cards:** `python captures/routes/make_cards.py` → `media/Bxx.png`.
3. **Sheet + evidence:** `python build_sheet.py`, then `python <brutalist>/skills/make/godot-gamedev/scripts/verify_gamedev.py . --game ../../godot`.
4. **Narration:** `python <brutalist>/runtime/scripts/generate_audio_kokoro.py .`, then `python narration_qc.py` (bakes B01's 0.8 s lead). B08 and B18 peaked at 0 dBFS and were limited to −1 dB (`alimiter=limit=0.89`).
5. **Conform:** `python conform_clips.py` (B07: labelled HOLD, never slowed), then `python build_sheet.py` again.
6. **Scenes:** `python run_remotion_win.py . --only <beat>` for each Remotion beat (pilot: B04). The headless browser sometimes times out on first launch; a retry has worked.
7. **Review cut:** `python run_compile_win.py . --review --fps 30 --height 1080`.
8. **Final:** `python <brutalist>/runtime/qc/final_frame_check.py . --mp4 <cut>`, then `python run_compile_win.py . --height 2160 --fps 30 --out exports/landscape`. Record the master's SHA-256. No mp4/mp3/wav is committed.
