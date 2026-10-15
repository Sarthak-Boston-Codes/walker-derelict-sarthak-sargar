# BUILD-PROMPT — how this film is (re)built

Folder: `youtube/claude-liam-derelict-a3-gamedev/` (repo root, outside `godot/`). Slug: `claude-liam-derelict-a3-gamedev`. Same pipeline and Windows launchers as `youtube/claude-liam-derelict-gamedev/` (see its BUILD-PROMPT.md for the toolkit notes).

## Step 1: media
1. **Hand-edit GLB** (once, Blender MCP): Medkit scale 1.95508, export to `captures/medkit_handedit_scale_1.95508.glb`, scale back to 1, don't save.
2. **Captures and logs:** `python captures/routes/make_media.py <scratch>` (isolated copies of HEAD, b74d239 and the hand-edit copy; 4K SubViewport via `showcase_capture.gd`; writes `captures/MEDIA-LEDGER.json`).
3. **GLB log:** run `captures/routes/inspect_glb.py` on `godot/assets/3d/*.glb` into `logs/glb_inspect.log`.
4. **Cards:** `python captures/routes/make_cards.py` (B04–B09, B13, B14, B16, B18, B20).

## Step 2: sheet and evidence
```
python build_sheet.py
python <brutalist>/skills/make/godot-gamedev/scripts/verify_gamedev.py --game godot youtube/claude-liam-derelict-a3-gamedev
```

## Step 3: narration
`python <brutalist>/runtime/scripts/generate_audio_kokoro.py .` then `python narration_qc.py` (bakes B01's 0.8 s lead).

## Step 4: conform and scenes
- `python conform_clips.py` (scales each capture into `media/frames/Bxx_frame.png`, built by make_cards.py; B11 narration padded to the 8 s capture; B19 + labelled 0.3 s HOLD), then `python build_sheet.py` and the checker again.
- Scenes: `python run_remotion_win.py .` with `C:\Users\sarth\nodejs` on PATH (`--only` takes one beat id). Pilot was B10.
- `python inspect_scenes.py <outdir>` for durations and frame sheets.

## Step 5: review cut
`python run_compile_win.py . --review --fps 30 --height 1080`; human watches and listens (pronunciation of "Hej", "sRGB", "MCP" in particular).

## Step 6: final (after the human review)
```
set PYTHONUTF8=1
python <brutalist>/runtime/qc/final_frame_check.py . --mp4 <review cut>
python run_compile_win.py . --height 2160 --fps 30 --out exports/landscape
```
Rerun the checker at handoff. No game change, paid call, Git push or publication.
