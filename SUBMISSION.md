Assignment: Assignment 5 - Shaders, Materials and the Godot Shading Language
Student: Sarthak Sargar
Project name: walker-derelict-sarthak-sargar
GitHub repository URL: https://github.com/Sarthak-Boston-Codes/walker-derelict-sarthak-sargar
Git tag and submitted commit SHA: a5 / the commit the a5 tag points to (`git rev-parse a5`; a commit can't contain its own hash, so the exact SHA is given in the Canvas submission note)
Game-source revision shown in the film: a8f1bc2 (last change to game, shader, material, scene or texture files)
Godot version, renderer and operating system: Godot 4.7.2.stable.official.ed1daf0bf / Forward+ (D3D12) / Windows 11
Authorship: The A5 shaders (`low_ammo`, `concrete_surface`, `hint_experiment`), the colour line, the predictions and the brief answers in CHANGE-BRIEF.md were written by Claude (chat). The driver, tests, materials, scenes, capture tools, MATERIALS.md, LANGUAGE-NOTES.md and the other documents were written by Claude Code, which also fixed one shader bug (the drop shadow, below). The TA verbally permitted AI-written work for A5 provided the student understands it; the student is getting this confirmed in writing. The student chose the state and the six design decisions by accepting Claude's proposed defaults and did not write shader code.
The state the shader communicates: Low ammo, `player.mag <= 5`. The HUD ammo counter blends from #F2C14E to #FF3030 (`godot/shaders/low_ammo.gdshader`), in over 0.25 s and out over 0.5 s of scaled game time, frozen while paused, extending on retrigger (`godot/game3d/low_ammo_driver.gd`).
The textured object: The factory floor. `godot/shaders/concrete_surface.gdshader` with Poly Haven `concrete_floor_worn_001` (CC0): albedo as colour (`source_color`), roughness and normal as data. Two materials from one shader: `concrete_dry.tres` on the floors, `concrete_wet.tres` on the Boiler Room floor.
Hint experiment: one PNG of greys 64/128/192; measured 64/128/192 through the `source_color` sampler and 137/188/225 without it, matching the prediction exactly.
Generated shader: `godot/shaders/standard_generated.gdshader` (Godot 4.7.2's code for a StandardMaterial3D with albedo, normal and roughness textures); line map and the eight answers in LANGUAGE-NOTES.md (written by Claude Code).
Checks run (command and result): all through `scripts/run-test.sh`. `low_ammo_test.gd` at 30/60/144 fps → exit 0, 35 PASS each. `test_materials.gd` 60 → exit 0, 74 PASS. `calibrate_normal_map_check.gd` 60 → exit 0. Earlier suites at 60 fps (smoke 27 ok, soak PASS, showcase 3 ok, trigger_count 7 ok) unchanged before and after. Mutations: missing semicolon → exit 1; renamed uniform → exit 1; `source_color` removed → exit 1. Detail: TEST-REPORT.md.
Inspect-and-revise: the first windowed capture showed the label's drop shadow turning red at full warning (predicted failure case 5). A dated brief revision came first, then the fix (tint only non-black pixels); the recapture confirmed it. Found and fixed by Claude Code; not yet checked by the student.
Human checks: pending: not yet performed by the student (HUMAN-CHECK-NOTES.md).
Final film URL and filename: pending: added after upload / claude-liam-derelict-a5-gamedev.mp4
Final film SHA-256: pending
Summary of my changes: (to be written by the student in their own words)
Known limitations: (detail in TEST-REPORT.md "Honest limits") Look checked only by Claude Code's inspection so far. R7 is tested with a test-emitted signal, because no real input can end the state inside the fade-in. The shadow fix skips pure-black pixels, so a black label colour would never tint. At the default `uv_scale` the concrete reads as near-uniform grey from the game camera. The wet floor is a visual-only plane. The normal-map check needs 256 px downsampling to separate conventions.
Changed games since Assignment 2: no
