# TEST-REPORT.md — DERELICT

Source revision: f88f58d (game code; later commits are documentation only)
Engine version: Godot 4.7.2 (stable)

| Check | Evidence to collect | Result |
|---|---|---|
| Startup and controls | Scene runs from a fresh copy; movement and every state change work | PASS. Author playtest: WASD movement works as expected. Right-mouse aim and left-click fire confirmed — clicking fires on the zombie. Both mute keys confirmed individually and together (see Muted play row). |
| Character against the sheet | In-engine screenshots of each state beside the character sheet poses; collision mismatches noted | States trigger correctly through actual play: idle/walk while moving, aim/shoot on input, hurt on zombie contact, recover afterward, celebrate at the exit. Readability against the final floor art was flagged as a limitation during development (see Known limitations) — not separately re-confirmed in this playtest. |
| Storyboard against the slice | Each panel the slice covers, beside an in-engine screenshot; differences listed | PASS, and more complete than a clean run: author playtest covered panel 3 (encounter), panel 4 (success — zombie shot and killed), panel 5 (failure — caught by the zombie), panel 6 (recovery — continued after), and panel 7 (end of session — reached the exit, game ended). Panels 1 and 2 are design-view only and not gameplay-covered by design. (Panel numbers follow STORYBOARD.md, not CHANGE-BRIEF's off-by-one asset table.) |
| Sound events | Each of the 4 events produces exactly one sound per occurrence, including rapid repeats and a held input | SFX-SHOT and SFX-HURT specifically confirmed by ear during play (shot sound on click; an audible hurt cue on zombie contact). SFX-DOWN and SFX-CLEAR's *triggering events* both occurred during play (the zombie died; the exit was reached and ended the session) but their specific sounds weren't separately called out by the player. One-trigger-per-event is additionally confirmed by the automated check below, independent of by-ear confirmation. |
| Music | The loop repeats without a click or gap; pause and end behave as predicted | MUS-LOOP confirmed smooth by ear, no reported click or gap. End: on reaching the exit, MUS-LOOP fades out over 1.5 s as SFX-CLEAR plays, as CHANGE-BRIEF predicts — verified by a scripted check during development (−30 dB at 0.75 s, stopped once the fade ends, also with Music muted) and confirmed by ear in the author playtest. Pause: the slice has no pause menu, so pause behavior isn't applicable. |
| Muted play | The slice can still be played and understood with all sound muted | M and N each confirmed to mute their own channel independently, and confirmed to mute both at once when pressed together. A full run was completed with both muted. The specific visual cues used to follow the action while muted weren't separately described. |
| Automated check | At least one automated check you added, for example counting sound triggers per event during a scripted input sequence, with its command and result | `godot --headless --path godot res://tests/trigger_count_test.tscn`. Checks all 16 asset IDs resolve, then five scripted scenarios against the real main scene: SFX-SHOT fires once on a single held fire, and is capped at the 0.55s shot-spacing limit under rapid-fire; SFX-HURT fires exactly once across the full hit chain even when held on the zombie; SFX-DOWN fires exactly once even when hit multiple times in one frame; SFX-CLEAR fires exactly once across repeated exit entries. Exit code 0, 0 failures. |

## Inspect-and-revise cycle
**Observed:** after the real character art was wired in and rotated to face "north," the sprite rendered upside-down at the default facing. **Changed:** measured the actual cause by rendering the real poses at all four facings with the aim direction drawn as a line, rather than guessing — this showed the art has a baked-in fixed-elevation perspective (not true top-down), so no single rotation offset could make every facing upright, and separately that the drawn weapon didn't point where shots actually went. **Why:** switched from free 360° rotation to mirroring left/right plus a capped ±30° tilt toward the aim direction (Option C) — the sprite is now upright at every facing, at the documented cost of the weapon not always pointing exactly at the shot when aiming straight up or down.

## Playtester
Author playtest, sound on. Controls (WASD, aim, fire, M, N) all worked as expected. Encountered the zombie, got caught once (hurt sound, briefly unable to act, then recovered and continued — no death or restart, matching the hurt/recover design rather than a game-over), then shot and killed the zombie and reached the exit, ending the session. Repeated a full run with both music and effects muted — confirmed both keys produce full silence together, and completed the run. Not specifically observed: readability of the aim mirror/tilt in motion, whether two fast shots sound jarring cutting off, and specific by-ear confirmation of the SFX-DOWN and SFX-CLEAR sounds individually (their triggering events were reached).

## Known limitations (carried from development, not from this playtest)
- Player readability against the final floor art (related to, but distinct from, predicted failure case #4).
- Floor art details (walls, machinery, doorway gaps) don't match the actual collision shapes — cosmetic only, collision itself is correct.
- Exit marker sits on the catwalk grating in the floor art — reads less clearly there, but still fully functional.
- CHAR-GRABBED-FAIL and CHAR-HURT are both off-palette (blue-grey rather than the specified olive/tan).
- CHAR-IDLE's baked-in flashlight beam direction doesn't match the implied light direction in CHAR-AIM/CHAR-SHOOT-FOLLOWTHROUGH.
- CHAR-WALK/CHAR-RECOVER/CHAR-CELEBRATE are drawn from a slightly different art angle and come out larger than the other five poses.
- The flashlight/darkness mechanic from CONCEPT.md's art direction was not built in this slice (predicted failure case #4 — not tested, not fixed).
- The zombie can re-grab the player if they stand still through the full hurt/recover/invulnerability window (~2.8s) — documented in CHANGE-BRIEF.md Revisions, not rebuilt.

## Assignment 3 — 3D assets

Blender: 5.2.2 LTS (build hash d13f752e3b9c). Godot: 4.7.2.stable.official.ed1daf0bf.

| Check | Evidence to collect | Result |
|---|---|---|
| Interface notes | Six parts in own words + screenshot | See BLENDER-NOTES.md |
| Size | Dimensions match brief, both in Blender and Godot | All three confirmed exact matches, verified both in Blender (get_scene_info) and in the exported .glb files: SupplyCrate 0.5x0.5x0.5m, RustedBarrel 0.6m dia x 0.9m tall, Medkit 0.3x0.2x0.15m. |
| Upright and scale | Stands correctly; node scale 1,1,1 | PASS, automated check (`showcase_3d_test.gd`): all three read rotation 0,0,0 and scale 1,1,1 after export. |
| Origin | Sits on floor, doesn't float | PASS, automated check: all three bases sit on the floor plane within 1mm. |
| Triangle count | Within budget | SupplyCrate 36/100, RustedBarrel 44/200, Medkit 48/150 — all within budget. |
| Imports and appears | All three import without error, appear in scene | PASS — confirmed by the automated check (exit 0) and by direct human viewing in the Godot 3D editor. |
| HUMAN CHECK: look | Walk the camera around each asset, including behind and below | Done, author's own session in the Godot editor (not the automated check). Orbited the showcase scene: the crate reads as a wooden crate, the barrel as a rusted drum, the medkit as a white case with a red cross — all three recognisable at a glance. Viewed from behind and below: no missing faces or obvious breakage; shadows read as slightly small; the underside of the floor plane is a plain flat gray surface, as expected for a single-sided floor plane. |
| What Claude got wrong | At least one thing | Two real instances: (1) the showcase camera's first transform was written with rows in the wrong order, which pointed it at the sky — caught and fixed before any commit, and before any passing screenshot was taken; (2) the medkit's red cross was initially too small to read clearly from the showcase camera's original angle — required both enlarging the cross geometry and re-angling the camera to actually resolve, not just one fix alone; this was found after the showcase was first committed, and the fix landed in its own separate later commit, 343a90c. |

## Inspect-and-revise cycle
**Observed:** after building the medkit and viewing it in the Godot showcase at the planned camera angle, the red cross — the one visual feature meant to identify it as a pickup — was only a few pixels and didn't read. **Changed:** enlarged the cross's arms from 0.12x0.04m to 0.14x0.045m (kept at the same 1cm height to stay within the medkit's approved 0.15m total height), and separately raised the showcase camera (1.3m to 1.6m) and tilted it more steeply down (-20° to -35° pitch), since the shallow angle alone was hiding the medkit's top regardless of cross size. **Why:** the enlarged cross alone was a small improvement; the real fix needed addressing the camera angle too, confirmed by re-running the automated check (still 0 failures) and a new screenshot showing the cross clearly on the medkit.

## Playtester
Author's own session, walking the Godot 3D viewport camera around all three assets including from behind and below (see HUMAN CHECK row above for the specific observations).
