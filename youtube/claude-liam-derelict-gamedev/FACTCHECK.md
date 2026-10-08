# FACTCHECK — DERELICT gamedev film

Each narrated claim, with the evidence behind it. "Code" = `godot/` at f88f58d. "Media" = `MEDIA-LEDGER.json`.

| Beat | Claim | Evidence | Status |
|---|---|---|---|
| B00 | Art and sound made by generative models, all but the zombie | `asset_manifest.gd` 10–31: every ID has a real file except ZOMBIE-SHAMBLE/DOWN (runtime placeholders) | ✓ (corrected from a first draft that said "every picture and sound") |
| B00 | Walker prompt text | Reconstructed for the cold open from CONCEPT.md; not a recorded prompt | Labelled reconstructed (role_note) |
| B01 | Art gets wired in, not dropped in; one table, one line each; a test for every sound | `asset_manifest.gd`; trigger-count test (B23 logs) | ✓ |
| B02 | Requirements list | SUBMISSION.md, CHANGE-BRIEF.md asset list, README "What the slice demonstrates" | ✓ |
| B02 | Empty Godot 4.7.2 project; code f88f58d | CHANGE-BRIEF "Started from"; `git log` (f88f58d = last code commit) | ✓ |
| B03 | Scene contents and two autoloads | `main.tscn`; `project.godot [autoload]` | ✓ (saved tree; runtime players disclosed in COMPONENTS) |
| B04 | `""` → placeholder at runtime; path → real file | `asset_manifest.gd` 41 | ✓ |
| B04 | Zombie's two lines still empty | lines 19–20 | ✓ |
| B05 | Left = isolated copy with ART paths blanked | `make_stills.py`; 11 of 11 blanked | ✓ |
| B06 | Fires only after 0.25 s in AIM | `player.gd` 31, 80 | ✓ |
| B06 | Ready cue shows exactly when a click would work | `player.gd` 112 (same condition as 80) | ✓ |
| B07 | Tracer stops on the zombie | RUN_A frame 2.25 s (contact sheet) | ✓ |
| B08 | Refuses while hurt/grabbed/recovering/celebrating and 1 s after | `player.gd` 119; 38 (`post_hit_invuln` 1.0); 103–104 | ✓ |
| B08 | Arrow points at the attacker | `player.gd` 123; RUN_B 4.3 s | ✓ |
| B10 | Flash 150 ms, then the only SFX-DOWN call | `zombie.gd` 20, 63–66, 75 (excerpt 63–76; guard line 60 in notes); grep: each SFX played from exactly one line | ✓ |
| B12 | Audible game audio, no narration | Audio experiment: `clock:source`+`preserve` output envelope = capture envelope (30/30 windows); review cut: B12 in place at 126.4 s, correlation 0.993 with its clip | ✓ |
| B12 | Level | One fixed −10 dB gain on the game audio (`conform_clips.py`): the raw mix measured −11.3 dB RMS against −27 dB narration. Level only: the video is stream-copied, nothing is retimed, and clipping already in the source SFX is unchanged | disclosed |
| B13 | Muting doesn't stop what's playing; a sound muted halfway can come back as a tail | `audio_director.gd` 71 (bus mute only); RUN_C v1 envelope (−5 dB burst on unmute) | ✓ observed |
| B13 | The capture waits out the collapse before unmuting | RUN_C v2 route log: muted kill 2.6 s, unmute 5.6 s (> 2.4 s SFX-DOWN) | ✓ |
| B14 | Silent kill still reads; sound comes back; audible shot | RUN_C v2: silence 1.1–5.5 s, HUD SHOT 1/DOWN 1; music returns 5.6 s; shot 6.4 s | ✓ |
| B15 | Free rotation turned the art upside-down | B16_before (7fc6a99 render) | ✓ |
| B15 | Tilt at most 30° | `facing.gd` 18; `player.gd` 40 | ✓ |
| B16 | Gun 90° off before; ~60° off straight up/down after | facing grid renders; 90 − 30 | ✓ |
| B17 | Panel 7 / pose 10 ask for a calm success beat | STORYBOARD.md panel 7; CHARACTER-SHEET.md pose 10 | ✓ |
| B17 | First prompt → blood + dropped gun → rejected; correction prompt | SOURCES.md line 27 (student's asset log); thumbnail in `design/character/rejected/` | Student-recorded; thumbnail corroborates. Narration says "per the asset log". |
| B18 | Alpha from greenness vs border-sampled key; key share subtracted | `tools/chroma_key.py` 25–38, displayed verbatim (sha256 5666189939ce46cd74ada4ccc92a072452d2df8d868901c5d5068eda6940adcc) | ✓ |
| B19 | Same factor as every pose; 169×92 | MEDIA `celebrate_game_0p12.png` 169×92; SOURCES.md (scale 0.12 for all) | ✓ |
| B20 | Flag, not trigger, stops a second chime | `exit_marker.gd` 18–22; test scenario SFX-CLEAR = 1 | ✓ |
| B21 | Music fades to nothing | RUN_A envelope −120 dB from ~13.3 s | ✓ |
| B22 | Pins the player through the chain; expects 1 | `trigger_count_test.gd` 84–89 | ✓ |
| B23 | Pass; guards removed → 4 FAIL; shot 4, hurt 135 | `media/logs/*.log` | ✓ |
| B24 | Student played with sound on and muted; loop and fade by ear | TEST-REPORT.md "Playtester", Music row | Student's report |
| B24 | Darkness cut; zombie placeholder; readability; pose drift | CHANGE-BRIEF Revisions; README; TEST-REPORT known limitations | ✓ |
| B25 | `max_tilt_deg` 30 in `player.gd` | `player.gd` 40 | ✓ (zombie has its own `max_tilt_deg`, also 30) |

## Disclosures
- **Editor views** are "Godot editor reconstruction" (the workbench label), not recordings.
- **Footage:** Movie Maker captures from input-only routes (`captures/routes/route.gd`). The route reads state to time inputs and warps the OS cursor; it never moves nodes. B07/B11/B12/B21 are overlapping intervals of one take (RUN_A).
- **B12:** routed through `compile.py`'s preserve path (`clock: source`, `audio_policy: preserve`). Internally `is_source_report()` treats this as a source-report beat; it is not labelled SOURCE_REPORT and is not a fellow's report.
- **The test teleports** (B23 narration says so).

## Presentation edits to gameplay footage (disclosed)
- **HUD backing (B07, B09, B11, B14, B21; author-approved option A).** Inside the HUD readout box (normalised 0.012–0.30 × 0.035–0.195), every pixel that is not near-white HUD text is darkened to 30% brightness.
  - **Why:** the final gate measured the raw HUD text at only 0.16–0.19 luminance separation over the floor art (minimum 0.30). That's a real readability finding, consistent with the documented player-readability limitation.
  - **What's untouched:** the text pixels, the rest of the frame, and all timing.
  - **Not applied to B12:** its video stays a direct copy of the capture.
- **Labels:** REPLAY 0.5x and HOLD, top-centre.
- **B12:** −10 dB audio gain (above).
- **Gate declarations:** these beats declare `qc.full_bleed` and the HUD box as their measured contrast region, each with a written `contrast_reason` in the beat sheet.
- **Final gate on the review cut:** 54 frames, 0 BLOCKER, 0 MAJOR.

## Known gap shipped
- **Outro jingle missing (B26 is silent).** OUTRO-LOCK.md specifies a slug-seeded stock jingle from `svg/claude/mp3/`. That folder doesn't exist on the build machine, and `ClaudeTitleOutro` has no audio code. Per godot-waikthrough ("report that asset blocker rather than inventing a substitute") nothing was substituted. Shipped silent by the author's decision, 2026-10-07.

## Corrections applied
1. **B00 overclaimed.** The first draft said "every picture and sound made by generative models". The zombie is a runtime placeholder, so the line now reads "…with its art and sound made by generative models, all but the zombie."
