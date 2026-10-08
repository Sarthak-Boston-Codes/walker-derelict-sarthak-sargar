# SHOTLIST — DERELICT gamedev film (walker)

Durations are estimates (2.5 words/s). Step 3 measures narration; result clips are then conformed in step 4.

| Beat | Act | Visual | Media / scene | Est. s | Audio |
|---|---|---|---|---|---|
| B00 | Ask | Claude composer, "Jambo, Liam", reconstructed Walker prompt + 3 output lines | ClaudeComposerAsk | 19 | narration |
| B01 | BLUF | Hesitant writer: "just drop into" → "have to be wired into" | BrutalistHesitantWriter | 12 (+0.8 lead) | narration |
| B02 | Setup | Requirement → asset ID list | Workbench tree | 16 | narration |
| B03 | Anatomy | Saved main scene + 2 autoloads | Workbench tree | 16 | narration |
| B04 | Code | `asset_manifest.gd` 10–22 | Workbench code | 21 | narration |
| B05 | Result | Same frame: placeholders vs real art | `media/B05.png` (hold) | 8 | narration |
| B06 | Code | `player.gd` 72–81 | Workbench code | 15 | narration |
| B07 | Result | Aim → cue → shot → tracer | `media/B07.mp4`: 1.3 s action + labelled REPLAY 0.5x 2.6 s + HOLD 0.8 s = 4.70 s | 4.7 | narration |
| B08 | Code | `player.gd` 117–125 | Workbench code | 15 | narration |
| B09 | Result | Grab chain + arrow | `media/B09.mp4`: 3.3 s action (RUN_B 4.0–7.3, contact at 0.27 s) + HOLD 1.8 s = 5.10 s | 5.1 | narration |
| B10 | Code | `zombie.gd` 58–76 | Workbench code | 13 | narration |
| B11 | Result | Flash → body; "Now listen." | `media/B11.mp4`: 1.6 s action + HOLD 1.1 s = 2.70 s | 2.7 | narration |
| **B12** | **Listen** | **Raw gameplay: shot, collapse, music** | **`media/B12.mp4` 4.0 s** | **4.0** | **game audio only (preserve)** |
| B13 | Code | `audio_director.gd` 70–80 | Workbench code | 12 | narration |
| B14 | Result | M, N, silent kill, wait, unmute, audible shot | `media/B14.mp4` 7.1 s action; narration 6.59 s padded with silence to 7.10 s | 7.1 | narration |
| B15 | Code | `facing.gd` 11–18 | Workbench code | 15 | narration |
| B16 | Result | Before (7fc6a99) / after facing grids | `media/B16.png` (hold) | 16 | narration |
| B17 | Trace | Panel 7 + pose 10 → rejected thumb + prompt 1 → correction + raw output | `media/B17.png` trace board (real images) | 15.0 | narration |
| B18 | Code | `tools/chroma_key.py` 25–38, numbered 25–38 | `media/B18.png` code card (not GitHubCodeViewer: numbers from 1) | 10.7 | narration |
| B19 | Result | Raw → keyed → 169×92 | `media/B19.png` (hold) | 7 | narration |
| B20 | Code | `exit_marker.gd` 17–26 | Workbench code | 15 | narration |
| B21 | Result | Walk, CELEBRATE, chime, fade to silence | `media/B21.mp4` 4.8 s action; narration 4.78 s padded to 4.80 s | 4.8 | narration |
| B22 | Code | `trigger_count_test.gd` 80–89 | Workbench code | 13 | narration |
| B23 | Result | Recorded logs: PASS / 4 FAIL | `media/B23.png` (hold) | 19 | narration |
| B24 | Verdict | Verdict artifact, 4 lines | ClaudeVerdictArtifact | 25 | narration |
| B25 | Your Turn | Composer: max_tilt_deg 30 → 45 prompt | ClaudeComposerAsk | 30 | narration; Liam signs off |
| B26 | Outro | Locked title card | ClaudeTitleOutro | 7 | stock jingle only |

## Rules this shot list holds to
- **No slowed gameplay:** footage plays at capture speed. When narration outruns an action, a labelled HOLD frame follows the action; no `setpts` retiming. The compiler's slow-to-fit path would otherwise retime it, so step 4 builds each clip to the measured narration length.
- **Code then result:** every workbench code beat is immediately followed by its narrated result. B18→B19 follows the same pattern outside the checker, because `chroma_key.py` is outside `godot/`.
- **B12 is the only non-narrated body beat.** It sits right after B11's spoken cue ("Now listen.").
- **Small player in full-room footage:** step 4 may crop/zoom result clips, labelled, keeping capture timing.
- **All game audio stops before B26.**
