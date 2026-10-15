# SHOTLIST — DERELICT A3 (3D assets) film (walker)

Durations are measured narration (Kokoro am_onyx); capture beats are conformed to them in step 4. Total ≈ 5:30.

| Beat | Act | Visual | Media / scene | s | Audio |
|---|---|---|---|---|---|
| B00 | Ask | Composer, "Hej, Liam", reconstructed Walker prompt + 3 output lines | ClaudeComposerAsk | 15.3 | narration |
| B01 | BLUF | Hesitant writer: "imported." → "verified." | BrutalistHesitantWriter | 10.3 (0.8 lead) | narration |
| B02 | Setup | Brief: three specs, origin, showcase, 2D untouched | Workbench tree | 14.0 | narration |
| B03 | Setup | Predicted failure cases 1–3 | Workbench tree | 14.3 | narration |
| B04 | Interface | Author's Blender screenshot, six numbered parts | `media/B04.png` (hold) | 14.5 | narration |
| B05 | Trace | Crate: prompt → get_scene_info → look | `media/B05.png` (hold) | 14.5 | narration |
| B06 | Trace | Colour: before/after + conversion code (session) | `media/B06.png` (hold) | 15.3 | narration |
| B07 | Trace | Barrel still + values | `media/B07.png` (hold) | 11.5 | narration |
| B08 | Trace | Medkit first build + values | `media/B08.png` (hold) | 9.4 | narration |
| B09 | Export | GLB inspection log | `media/B09.png` (hold) | 15.9 | narration |
| B10 | Code | `showcase_3d.tscn` 29–35 | Workbench code | 13.9 | narration |
| B11 | Result | Showcase running, scene camera | `media/B11.mp4`: 8.0 s capture framed on a card (title + source caption); narration padded | 8.0 | narration |
| B12 | Code | `showcase_3d_test.gd` 16–22 | Workbench code | 12.2 | narration |
| B13 | Result | PASS log | `media/B13.png` (hold) | 9.9 | narration |
| B14 | Hand-edit | Before/after, **STAGED RECONSTRUCTION** | `media/B14.png` (hold) | 15.1 | narration |
| B15 | Code | `showcase_3d_test.gd` 55–65 | Workbench code | 13.4 | narration |
| B16 | Result | Hand-edit FAIL log, **DEMONSTRATION** | `media/B16.png` (hold) | 14.6 | narration |
| B17 | Code | `showcase_3d.tscn` 15–27 | Workbench code | 10.3 | narration |
| B18 | Result | b74d239 vs HEAD camera + enlarged crops | `media/B18.png` (hold) | 14.0 | narration |
| B19 | Human check | Orbit, behind and below, **capture camera** | `media/B19.mp4`: 14.0 s capture framed on a card ("CAPTURE CAMERA" caption) + HOLD 0.3 s | 14.3 | narration |
| B20 | Trace | What Claude got wrong (text) | `media/B20.png` (hold) | 14.0 | narration |
| B21 | Verdict | Verdict artifact, 4 lines | ClaudeVerdictArtifact | 22.2 | narration |
| B22 | Your Turn | Composer: 8-sided barrel + prediction | ClaudeComposerAsk | 25.9 | narration; Liam signs off |
| B23 | Outro | Locked title card | ClaudeTitleOutro | 7.0 | stock jingle only |

## Rules this shot list holds to
- **No retimed captures:** both clips play at capture speed; narration is padded (B11) or a labelled HOLD is appended (B19).
- **Code then result:** each workbench code beat (B10, B12, B15, B17) is immediately followed by its narrated result with hashed media (checker: code-then-result-v1).
- **Labels on screen:** B14 STAGED RECONSTRUCTION banner; B16 "Demonstration" title and footer; B19 "capture camera" in its shot label; workbench beats "Godot editor reconstruction"; B06 code "quoted from the session (not a repo file)".
- **Captures framed, not cropped:** B11/B19 are scaled whole into a 2756×1550 box on the cream card (title-safe; the visual gate reads a bare gray 3D frame as underfilled). The 4K original is `media/action/`.
- **No game audio:** the showcase has none; all audio is narration plus the outro jingle.
