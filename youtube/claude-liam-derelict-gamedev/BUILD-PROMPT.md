# BUILD-PROMPT — how this film is (re)built

Folder: `youtube/claude-liam-derelict-gamedev/` (repo root, outside `godot/`). Slug: `claude-liam-derelict-gamedev`.

## Step 1: media ✓
1. **Captures:** `captures/routes/record_all.ps1`. Godot Movie Maker, three input-only routes (`ROUTE=clear|grab|mute`); route logs alongside.
2. **Inspect captures:** `python captures/routes/inspect_captures.py <outdir>` writes contact sheets plus 100 ms loudness envelopes.
3. **Stills:** `python captures/routes/make_stills.py <scratch>`. B05 and B16 come from isolated copies, plus a `git archive` of 7fc6a99.
4. **Media:** `python captures/routes/make_media.py <scratch>`. It produces the per-beat trims, the CELEBRATE trace files, the test logs (clean, and with 4 guards removed) and `MEDIA-LEDGER.json`.
5. **Composites:** `python captures/routes/make_composites.py` builds B16 (before | after) and B23 (logs).

## Step 2: sheet and evidence ✓
```
python build_sheet.py
./art godot-gamedev --check youtube/claude-liam-derelict-gamedev --game godot
```
On Windows, run the checker as `python <brutalist>/skills/make/godot-gamedev/scripts/verify_gamedev.py`; it's the same script `./art` runs.

## Step 3: narration
`python runtime/scripts/generate_audio_kokoro.py <reel>` (kokoro-onnx, `am_onyx`).
- **Narration files:** must land where `compile.py` looks, `mp3/beat-Bxx.mp3` (or set `audio_file`). Note that its preflight and `build_master_audio` use different default paths (`mp3/beat-` vs `audio/`); set `audio_file` explicitly.
- **Silent-audio exceptions:** B12 (preserve) and B26 (silence) need no narration file.
- **Then:** measure, write `actual_duration_s`, and bind workbench cue times to phrases.

## Step 3 notes (done)
- `lead_silence_s` is not read by any runtime script. `narration_qc.py` bakes it into the mp3 (B01: 0.8 s) and marks the beat `lead_silence_baked`, so it's applied once.
- B25 was voiced with `--speed 0.9` (`tts_speed` on the beat).

## Step 4: scenes and clip conform
- **Windows:** run scenes through `python run_remotion_win.py <REEL> --only Bxx [--force]` with `C:\Users\sarth\nodejs` on PATH. `remotion_scenes.py` calls bare `npx`, which fails on Windows ([WinError 2]); the launcher only resolves that path. Worth fixing upstream.
- **Chrome cold start:** the first render timed out connecting to the headless shell (25 s). A retry worked, and both halves were tested working on their own.
- **Notes panel width:** about 22 characters per line. Keep note tokens ≤ 23 characters, or break them at `.` or `/`.
- **Provenance stamps:** rebuilding `beat_sheet.json` drops the `rendered` provenance stamps; re-rendering restores them.
- **Code panel:** shows at most 14 source rows (long lines wrap and use more rows). B10 was cut to lines 63–76 after line 75 fell off-screen.
- **Notes panel:** fits about 7 wrapped lines; three notes overflowed in B13. Keep it to two short notes.
- **Hesitant writer:** `BrutalistHesitantWriter` matches single whitespace tokens only (`triggerWords` is a comma-separated word list). A multi-word phrase never matches, and the correction silently doesn't happen, despite ai-explainer telling authors to put the whole phrase in `triggerWords`. B01 uses one word: dropped → wired. Keep each line under about 30 characters at fontSize 110.
- **Batch:** 14 scenes in 28 min (about 2 min each). `inspect_scenes.py <outdir>` checks durations and builds frame sheets.
- Render one workbench code beat as a pilot through `runtime/scripts/remotion_scenes.py`, inspect it, then batch. (Pilot B04: passed after the notes-wrap fix.)
- **Conform:** `python conform_clips.py` builds `media/Bxx.mp4` from `media/action/Bxx.mp4`:
  - action at capture speed;
  - B07 adds a labelled REPLAY 0.5x;
  - a labelled HOLD (top-centre, clear of the HUD) when narration is longer;
  - when the action is longer, the narration is padded with silence instead;
  - frame counts are `ceil(duration × 30)`, exactly what `compile.py` renders, so nothing is retimed;
  - B12 is a byte-identical copy (preserve);
  - the original voiced mp3s are kept as `mp3/voiced-Bxx.mp3`.
- **B17, B18 stills:** built by `captures/routes/make_trace_cards.py` (called by `make_media.py`).
- B17 trace imagery; B18 `GitHubCodeViewer` props to confirm.
- Rerun `build_sheet.py` and the checker (result media hashes change).

## Step 5: review cut (native Windows)
```
python run_compile_win.py <reel> --review --fps 30 --height 1080
```
`run_compile_win.py` makes `compile.py`'s own `has_drawtext()` return False. The review cut's running timecode uses `fontfile=C:\...`, and the drive-letter colon breaks ffmpeg's filtergraph parser. The cut therefore has no timecode clock (use the player's), and is otherwise unchanged. WSL was dropped.
- **Inspect:** `python inspect_cut.py <cut>.mp4` reports streams, the per-beat timeline and loudness, and B12 vs its clip. `qc-sheet.png` has the mid-frame of every beat.
- **Human:** watch and listen; B12 must be audible.
- **Me:** inspect frames, clock and loudness. Then revise.

## Step 6: final
On Windows:
```
set PYTHONUTF8=1
python run_compile_win.py <reel> --height 2160 --fps 30 --out <reel>/exports/landscape
```
(Equivalent to `./art final`.) Rerun the checker at handoff.

- **`PYTHONUTF8=1` is required on Windows.** Without it, `final_frame_check.py` writes REPORT.md in cp1252 and crashes on the "✓" in its clean verdict, exiting 2 even when the gate passed.
- **Check the gate first** (seconds, versus 40 min for a failed final): `python <brutalist>/runtime/qc/final_frame_check.py <reel> --mp4 <review cut>`.
- **Gate rules met:**
  - title-safe is a 5% inset, so all stills are cards inside it (`captures/routes/cards.py`);
  - B01 uses `contextTitle` and `brandLabel` so the typed text isn't underfilled;
  - gameplay beats declare `qc.full_bleed` and a HUD `contrast_region` (with a `contrast_reason`), and carry the HUD backing.
- **First final attempt:** refused by the gate (34 defects). Fixed as above, without weakening the gate.

No game change, paid call, Git push or publication is part of this build.
