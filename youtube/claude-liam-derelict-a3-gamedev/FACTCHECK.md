# FACTCHECK — DERELICT A3 (3D assets) film

Each narrated claim, with the evidence behind it. "Code" = `godot/` at e0a1e00. "Ledger" = `captures/MEDIA-LEDGER.json`. "Session" = the Claude Code session of 2026-10-15 that built the assets (not in the repo; its prompts and tool output are quoted in PROMPTS.md and on the cards).

| Beat | Claim | Evidence | Status |
|---|---|---|---|
| B00 | Walker prompt text | Reconstructed for the cold open from CHANGE-BRIEF.md's Assignment 3 section; not a recorded prompt | Labelled reconstructed (role_note) |
| B00 | Props built in Blender by Claude through an MCP connection | Session: every build step was `execute_blender_code`; SOURCES.md (repo root) A3 table | ✓ |
| B01 | Each prop checked against its brief by a test; a person checks the rest | `tests/showcase_3d_test.gd`; TEST-REPORT.md HUMAN CHECK row | ✓ |
| B02 | Sizes, origins, budgets; 2D gameplay untouched; floor, one light, one camera | CHANGE-BRIEF.md Assignment 3 (specs 1–3, scope note); `scenes/showcase_3d.tscn` | ✓ |
| B03 | Three predicted failure cases | CHANGE-BRIEF.md Assignment 3, predicted failure cases 1–3 (case 4, the MCP connection, didn't occur) | ✓ |
| B04 | Six interface parts | BLENDER-NOTES.md (author's words); `design/blender/my_session.png` | ✓ (markers placed by Claude on the author's screenshot) |
| B05 | One call per object, joined; origin 0, rotation 0, scale 1, 0.5 m, 36 / 100 triangles | Session: three object calls, join call, get_scene_info output (quoted on card) | ✓ |
| B06 | Colour first entered as linear values, came out pale tan; fixed by sRGB → linear conversion; round-trip exact | Session: conversion code and printed output (quoted verbatim on card); a3-stills 01/02; CHANGE-BRIEF.md Revisions | ✓ What Claude got wrong, part 1 |
| B07 | 12 sides, 44 / 200 triangles, colour chosen by Claude and approved | get_scene_info; CHANGE-BRIEF.md Revisions (barrel; colours approved) | ✓ |
| B08 | Inset lid, two-bar cross, 48 triangles | get_scene_info; CHANGE-BRIEF.md Revisions (medkit) | ✓ |
| B09 | Exported nodes rotation 0 / scale 1, Y-up sizes, bases at 0, colours round-trip, barrel caps triangulated | `logs/glb_inspect.log` (inspect_glb.py on the committed GLBs) | ✓ |
| B10 | Instances at x = −1, 0, +1, no transforms of their own | Code: `scenes/showcase_3d.tscn` 29–35 | ✓ (the instances carry position only) |
| B11 | All three upright, on the floor, casting shadows | `media/B11.mp4` (Ledger B11), scene camera | ✓ Seen in frames |
| B12 | Brief copied into data; Z-up vs Y-up axis note | Code: `tests/showcase_3d_test.gd` 16–22 | ✓ |
| B13 | Every row passes, exit code 0 | `logs/showcase_pass.log` (isolated copy of HEAD) | ✓ |
| B14 | Hand-edit: scale 1 → 1.95 (1.95508), location untouched, mesh unchanged; reverted | FRICTIONAL.md 2026-10-15 entry; commit 6668f61 | ✓ Images are a **staged reconstruction** (a3-stills/PROVENANCE.md); narration uses the logged value, not the staged 1.897 |
| B15 | Walks every mesh node, rejects rotation/scale, measures world AABB against floor and brief, counts triangles | Code: `tests/showcase_3d_test.gd` 55–65 | ✓ |
| B16 | Medkit fails at about twice its size; SCALE column prints the instance (1.00); the doubled scale is on the mesh node | `logs/showcase_handedit_fail.log` (exit 1, size 0.587 × 0.293 × 0.391); `captures/medkit_handedit_scale_1.95508.glb` node scale 1.95508 | ✓ **Demonstration** on an isolated copy, not the shipped build |
| B17 | One light with shadows, one camera; position and tilt lines are the fix | Code: `scenes/showcase_3d.tscn` 15–27; commit 343a90c diff | ✓ |
| B18 | Shallow 20° camera, small cross; bigger arms alone barely helped; −35° with larger cross reads | `captures/b18_*.png` (Ledger); CHANGE-BRIEF.md Revisions ("the bigger cross alone barely helped") | ✓ |
| B19 | No missing faces; dark shadowed sides with one light; floor not drawn from below | `media/B19.mp4`, frames inspected (contact sheet) | ✓ Observed in this capture. Note: the author's editor note in TEST-REPORT.md describes the floor's underside as "a plain flat gray surface"; in this running-game capture the one-sided floor isn't drawn from below at all. Not reconciled; both are reported as observed |
| B20 | Sky camera (row order), caught before any commit; cross found after the showcase commit, fixed in a later commit | TEST-REPORT.md "What Claude got wrong"; commits b74d239, 343a90c | ✓ No image of the sky frame survives |
| B21 | Verdict lines | Rows above; limits from CHANGE-BRIEF.md Revisions (hidden faces, flat shading) and B16/B19 | ✓ |
| B22 | 8 sides → 16 side triangles + 2 × 6 cap triangles = 28 | Arithmetic: an n-gon cap triangulates into n − 2 triangles | ✓ Prediction, not a run |

## Known, disclosed
- Headless test runs print a leak warning at exit from the project's Sound autoload (MUS-LOOP), not from the showcase; `audio_director.gd` documents it. Not shown in the film's log cards (lines filtered: only the test's own output).
- Captures render into a 3840×2160 SubViewport because the laptop screen caps the window at 1920×1080 (Ledger).
