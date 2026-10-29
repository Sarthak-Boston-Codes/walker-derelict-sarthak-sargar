# FACTCHECK — every claim in the narration, and where it comes from

Written by Claude Code. "Inspected by Claude" means Claude Code looked at a capture; it is not the student's check.

| Beat | Claim | Source |
|---|---|---|
| B00 | Prompt in the composer | **Reconstruction**: no such prompt was typed; the student asked Claude Code to run the kit's runbook. The composer shows a suggested Walker prompt. |
| B00 | top-down 3D zombie shooter, Godot | README.md, REDO-LOG.md |
| B01 | "the shader code is AI-written, with the TA's permission" | SOURCES.md A5 section; the permission is verbal, written confirmation pending |
| B02 | state `player.mag <= 5`; `player.gd:37`, signal `player.gd:9` | CHANGE-BRIEF §1, verified in its 2026-10-29 revision |
| B02 | frame 0 mag 15 / frame 90 mag 5, red | logs/film_capture_playclip.log (`FRAME 0 mag 15 low_ammo 0.0000`, `FRAME 90 mag 5 low_ammo 1.0000`) |
| B03 | line 13 of low_ammo; concrete_wet.tres:11 and :19; concrete_surface :1, :13, :34 | the files at a8f1bc2 |
| B05 | (242,193,78), (248,120,63), (255,48,48), (255,0,18) | logs/capture_ammo_fixed.log MEASURE lines |
| B05 | "hint range doesn't clamp a value set from code" | the 2.0 reading; a clamp would give (255,48,48) |
| B06 | rates 4.0 / 2.0, pausable, priority 100 | low_ammo_driver.gd:10-11, :21-23 |
| B07 | real fire input, mag 15 → 5, fade in, reload, fade out | logs/film_capture_playclip.log; the clip is SCRIPTED (labelled) |
| B08 | a quarter second at each rate within a frame; pause; time scale; R7 test-emitted | logs/final_low_ammo_test_*fps.log |
| B10 | 64/128/192 and 137/188/225, "exactly the prediction" | logs/capture_hint.log; CHANGE-BRIEF §3 table |
| B12 | wet floor hard to tell apart in game | inspected by Claude on media/B12.png; human check H7 pending |
| B13 | only uv_scale 0.05 shows readable detail; wet_darkening 1.0 → black (mean luma 1.2) | logs/capture_sweep.log; inspected by Claude |
| B15 | both tiles change on the shader edit; only dry on the value edit; reverts exact | logs/capture_twomat.log (G 100.3/55.8 → 79.5/35.9; → 69.3/55.8; → 100.3/55.8). Edits made in memory, not on disk. |
| B16 | "written by Godot itself"; G:34, G:46 | header line 1 of standard_generated.gdshader; the file |
| B17 | one match, 1698 characters; the obvious call is not available | logs/dump_standard_shader.log; A5-LOG Phase 6 |
| B18 | mutations (a) (b) (c) exit 1; under (b) the timing rules still passed | logs/mutation_*.log; docs/evidence/mutation_b_rename.log has the R1–R7 PASS lines |
| B19 | shadow turned red; fixed; glyph pixels unchanged | logs/capture_ammo.log vs capture_ammo_fixed.log; CHANGE-BRIEF revision e434f65; fix a8f1bc2 |
| B20 | sign reversed; "as copied" mislabel redone; capture hang | A5-LOG Phases 4 and 7; commits 33398ad, 1ddd300, 752adca |
| B21 | authorship and TA statement; Poly Haven CC0 | SOURCES.md, ATTRIBUTION.md |
| B23 | "half a second everywhere, R1 fails" | **prediction**, not run: 1 / 2.0 = 0.5 s; the test asserts 0.25 ± 1 frame |

Known gaps: no person reviewed the narration before render; pronunciation ("Kia ora", "GLSL", "g d") has not been checked by ear.
