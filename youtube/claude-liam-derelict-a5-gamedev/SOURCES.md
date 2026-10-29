# SOURCES — A5 film

- **Game:** `walker-derelict-sarthak-sargar`, game source at commit a8f1bc2 (branch `a5`).
- **Engine captures:** Godot 4.7.2.stable.official.ed1daf0bf, Forward+ on D3D12 (NVIDIA GeForce RTX 4050 Laptop GPU), 3840×2160 SubViewport. Scripts: `godot/tools/a5_capture.gd` (ammo, hint, sweep, twomat) and `captures/routes/film_capture.gd` (playclip, floor). Logs in `logs/`.
- **Texture:** Poly Haven `concrete_floor_worn_001`, Dimitrios Savva and Rico Cilliers, CC0.
- **Narration:** Kokoro-82M (kokoro-onnx), voice `am_onyx`, local, $0.
- **Scenes and compile:** brutalist.art runtime (`C:\Users\sarth\brutalist.art`): Remotion components GodotDevWorkbench, ClaudeComposerAsk, BrutalistHesitantWriter, ClaudeVerdictArtifact, ClaudeTitleOutro; `compile.py` via `run_compile_win.py`.
- **Authorship of this film:** Claude Code (Claude Opus 5.5) wrote every script, card and line of narration in this folder. The launchers `run_compile_win.py`, `run_remotion_win.py`, `narration_qc.py`, `inspect_*.py` and `captures/routes/cards.py` were copied from the A3 film.
