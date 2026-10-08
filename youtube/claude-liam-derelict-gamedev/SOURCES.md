# SOURCES — DERELICT gamedev film

## Game
- **Repository:** walker-derelict-sarthak-sargar.
- **Game code shown:** **f88f58d** (`godot/`). Later commits change only docs and `design/` images.
- **Engine:** Godot 4.7.2 stable (official build), Windows 11.
- **Per-file SHA-256:** in `gamedev-evidence.json` (46 files + 9 exclusions).

## Engine captures
All in `captures/`; hashes in `MEDIA-LEDGER.json`.

| Capture | Raw (MJPEG + PCM 48 kHz) sha256 | Route log |
|---|---|---|
| RUN_A_clear (13.9 s) | f63d6ce641881f8c2e2f944105e8a2aead48cbd2e71592ff2b5787dce249259d | RUN_A_clear.route.log |
| RUN_B_grab (8.1 s) | 187bd3d9fdd5cc09c60d762157e755c7d360ba73333c2cfaf04ef6351bf2562f | RUN_B_grab.route.log |
| RUN_C_mute (7.6 s) | de1188caff09281aa488dbf298e92b063ceda9e9dd14b8b2bf0307dd1178b1a2 | RUN_C_mute.route.log |

- **Method:** `godot --path godot --write-movie <file>.avi --fixed-fps 30 -s captures/routes/route.gd`, game time at fixed 30 fps.
- **Input-only route:** input-map actions, mouse motion and an OS cursor warp. No node edits, no time scaling.
- **Converted to** H.264 crf 12 + AAC 256 kHz. Per-beat clips are frame-accurate trims of those MP4s (intervals in the ledger).
- **Superseded takes:** an earlier RUN_C (the muted shot killed the zombie, and unmuting revealed the collapse tail) and an earlier RUN_B (never grabbed). Their findings are in RIFF.md.

## Outro
`ClaudeTitleOutro`: exact title, @NikBearBrown, slug-seeded mascot. **Silent**, because the stock jingle (`svg/claude/mp3/`) is missing from the toolkit. Nothing was substituted; the author decided to ship it silent.

## Video edits
- **B07, B09, B11, B14, B21:** HUD backing. Non-text pixels inside the HUD box are darkened to 30%; text pixels are untouched (`conform_clips.py`, `hud_backing()`). Added because the HUD text failed the final gate's contrast check over the floor art. B12 is not edited.

## Audio edits
- **B12:** the only beat that plays game audio. One fixed −10 dB gain; video stream-copied; no retiming. The raw Movie Maker mix was about 16 dB louder than the narration.
- **Narration:**
  - B01 has a baked 0.8 s lead silence;
  - B07, B09, B11, B14 and B21 are padded with trailing silence to whole frames or to their action length;
  - the originals are kept as `mp3/voiced-Bxx.mp3`.

## Stills
- **B05:** two isolated copies of `godot/`, one with all 11 ART paths blanked (`make_stills.py`), rendered in a 1920-wide window. B05, B17, B18, B19 and B23 are native 3840×2160 cards in one shared style (`captures/routes/cards.py`).
- **B16:**
  - after: `facing_grid_c.gd` on an isolated copy of f88f58d;
  - before: `facing_grid_free.gd` on a `git archive` of **7fc6a99**.
- **B19, B23:** composed from the actual files and logs (`make_composites.py`, `make_media.py`); pixels and text are not edited.

## Runtime-tree note
B03 shows the **saved** `main.tscn` plus the autoloads from `project.godot`. The `AudioStreamPlayer` children that `Sound` creates in `_ready()` exist only at runtime and aren't shown as saved nodes.

## Asset generation (as recorded by the student)
- **Art:** Gemini (free).
- **SFX and music loop:** ElevenLabs Sound Effects (free).
- **Prompts and rejections:** the repo's `SOURCES.md` (sha256 recorded in `media/trace/celebrate_prompts.txt`).
- **Raw CELEBRATE output:** `media/trace/celebrate_raw_greenscreen.jpg`, copied from the original Gemini download, sha256 2d095d3f9e8a… (full hash in the ledger).

## Pipeline
- brutalist.art: `compile.py` (preserve-path behaviour verified by the audio experiment), `verify_gamedev.py`.
- **Review cuts:** run natively on Windows through `run_compile_win.py`, which skips only the timecode overlay (it fails on the `C:` font path).
- **Scenes:** rendered through `run_remotion_win.py` (resolves `npx.cmd`).

## Upstream documentation consulted
None. Godot behaviour claims (e.g. bus mute doesn't stop playback) are from observed engine output in this project, not from docs.

No secrets, no `.env` contents, no paid API calls.
