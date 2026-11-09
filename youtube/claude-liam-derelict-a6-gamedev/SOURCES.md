# SOURCES: A6 film

- **Game:** `walker-derelict-sarthak-sargar`, game source at commit f4af1c4 (branch `a6-effects`).
- **Engine captures:** Godot 4.7.2.stable.official.ed1daf0bf, Forward+ on D3D12 (NVIDIA GeForce RTX 4050 Laptop GPU).
  - `captures/routes/film_capture.gd` (burstplay, smokeplay): 3840×2160 SubViewport, 30 fps, SCRIPTED PLAY with real input. Logs in `logs/`. Raw clips `captures/{burstplay,smokeplay}_raw.mp4` (burstplay frames 0–239 of 420; smokeplay all 332).
  - Fixture strips from the repo: `captures/impact_burst/r{0,1}{,-light}/strip.png`, `captures/wound_smoke/r{0,2}-dark/strip.png` (Movie Maker 1280×720, 30 fps, preview seed 12345, HUD hidden).
  - Diff images and probe/price logs from `docs/evidence/a6/`.
- **Textures:** none external. The soft dots are `GradientTexture2D` resources inside the effect scenes.
- **Narration:** Kokoro-82M (kokoro-onnx), voice `am_onyx`, local, $0.
- **Scenes and compile:** brutalist.art runtime (`C:\Users\sarth\brutalist.art`): Remotion components GodotDevWorkbench, ClaudeComposerAsk, BrutalistHesitantWriter, ClaudeVerdictArtifact, ClaudeTitleOutro; `compile.py` via `run_compile_win.py`.
- **Authorship of this film:** Claude Code (Claude Opus 5.5) wrote every script, card and line of narration in this folder. `run_compile_win.py`, `run_remotion_win.py`, `narration_qc.py`, `inspect_*.py` and `captures/routes/cards.py` were copied from the A5 film; `build_sheet.py`, `conform_clips.py` and `make_cards.py` were adapted from it.
