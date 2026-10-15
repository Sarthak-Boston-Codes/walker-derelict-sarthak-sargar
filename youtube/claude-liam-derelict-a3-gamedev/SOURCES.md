# SOURCES — DERELICT A3 (3D assets) film

## Game snapshot
- Repo `walker-derelict-sarthak-sargar`, HEAD **e0a1e00** at capture time. Code shown: `godot/scenes/showcase_3d.tscn`, `godot/tests/showcase_3d_test.gd` (hashes in `gamedev-evidence.json`).
- Earlier revision used for B18 "before": **b74d239** (`git archive`, isolated copy).

## Engine captures (`captures/MEDIA-LEDGER.json`)
| Media | Method | Source |
|---|---|---|
| `media/action/B11.mp4` → `media/B11.mp4` | `showcase_capture.gd` MODE=scene, 240 frames, 3840×2160 SubViewport, `--fixed-fps 30`, ffmpeg x264 crf 12 | isolated copy of HEAD |
| `media/action/B19.mp4` → `media/B19.mp4` | MODE=orbit, 420 frames; CaptureCamera added by the script (not the scene's camera) | isolated copy of HEAD |
| `captures/b18_before_b74d239.png`, `captures/b18_after_head.png` | MODE=scene, 1 frame each | isolated copies of b74d239 and HEAD |
| `logs/showcase_pass.log` | `godot --headless … showcase_3d_test.tscn` (stdout) | isolated copy of HEAD |
| `logs/showcase_handedit_fail.log` | same, with `medkit.glb` replaced | isolated copy of HEAD + `captures/medkit_handedit_scale_1.95508.glb` |
| `logs/glb_inspect.log` | `captures/routes/inspect_glb.py` on the committed GLBs | `godot/assets/3d/` at HEAD |

`captures/medkit_handedit_scale_1.95508.glb`: exported through the Blender MCP with Medkit's object scale set to 1.95508 (the FRICTIONAL.md value) and not applied; scale reset to 1 immediately; `medkit.blend` not saved.

## Blender stills
`youtube/claude-liam-derelict-gamedev/media/a3-stills/` (hashes, origins and limits in its PROVENANCE.md): MCP `look` captures 01–05, author's screenshot 07 (staged reconstruction "after"). The "before" is `design/blender/my_session.png`. `godot_06` is provenance only and not used.

## Quoted text
- Author prompts (B05, B06): Claude Code session, 2026-10-15 (PROMPTS.md).
- Conversion code and printed output (B06): same session, `execute_blender_code` call that fixed the crate materials.
- Part names (B04): BLENDER-NOTES.md. Hand-edit values (B14): FRICTIONAL.md. Claude's mistakes (B20): TEST-REPORT.md.

## Tools
Godot 4.7.2.stable.official.ed1daf0bf · Blender 5.2.2 LTS (d13f752e3b9c) via mcp-for-blender · Kokoro-82M (kokoro-onnx), voice am_onyx · Remotion scenes from brutalist.art (`GodotDevWorkbench`, `ClaudeComposerAsk`, `BrutalistHesitantWriter`, `ClaudeVerdictArtifact`, `ClaudeTitleOutro`) · Pillow cards (`captures/routes/make_cards.py`, style from the first film's `cards.py`) · ffmpeg.

No asset libraries, generated meshes, paid calls, uploads or publication.
