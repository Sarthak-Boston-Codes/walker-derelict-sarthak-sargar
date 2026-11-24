# HONESTY-CHECK — every claim in the narration

Written by Claude Code. Each narration sentence from `beat_sheet.json`, one row each. Each row gives its evidence (a tag, a log, a capture) or the word **will**. The narration speaks as the student. Past tense is used only for things that exist at a tag.

Re-read against the runbook's ground rules 1–3 on 2026-11-23:
- No invented players, playtest quotes, studios, wishlists, downloads or metrics.
- The only measurement quoted is the A6 GPU cost, with its machine and its log.
- The narration never says "I wrote" any code.
- No instructor name, persona or credit line appears.

| Beat | Sentence | Evidence or "will" |
|---|---|---|
| B01 | "DERELICT. I'm Sarthak Sargar, and this is my final project pitch, for a gameplay programmer or a tools programmer role." | The student's answer on roles (`PROJECT-BRIEF.md`, verbatim) |
| B02 | "DERELICT is a small top-down 3D zombie shooter in four connected factory rooms, lit by a flashlight." | tag `a2-redo` (`48eec7e`): `level.gd:37-40` (four rooms), the flashlight (`REDO-LOG.md`); the B02 scripted captures |
| B02 | "I will take it to a finished one-run slice, from the title screen to a win or death screen, together with the test and capture toolkit that checks every layer." | **will**. The win and death screens exist (`State.WON`/`State.DEAD`, `a2-redo`); the finished slice does not. |
| B02 | "When it is done, it will be a Windows build in one folder, plus the repository, so you can rerun the checks yourself." | **will** (no `export_presets.cfg` in any commit) |
| B03 | "For the player, it is a short run in the dark." | tag `a2-redo` (flashlight, dark rooms); scripted capture B03 |
| B03 | "A burst where each bullet lands, smoke from your own wounds, a counter that turns red when ammo runs low, and a visible reload all tell you what is happening." | `a6` (impact burst, wound smoke), `a5` (low-ammo shader), `a7` (pistol reload). The design intent is that they "tell you"; whether they read well in play is pending (the student's checks) |
| B03 | "For a reviewer, it is a small game built so that you can check how I work in a few minutes." | the tagged `TEST-REPORT.md`s and `scripts/run-test.sh`; "built so that" states the purpose; how long a stranger takes has not been measured |
| B04 | "The nearest game I have played is Call of Duty's zombies mode." | The student's answer ("I have played … Call of Duty!"); "zombies mode" comes from `PROJECT-BRIEF.md` §2, written by Claude from that answer |
| B04 | "DERELICT is not bigger or better than that." | a modest comparison, no claim |
| B04 | "It is single-player, top-down, four rooms, and meant to be small enough to open in a minute." | single-player, top-down, four rooms: `a2-redo`. "Meant to be … open in a minute" is the goal, not timed (**will**; B05 says so) |
| B04 | "The difference is that, from the shader assignment on, every layer has tests a stranger can rerun." | `a5`, `a6`, `a7` `TEST-REPORT.md` (commands through `scripts/run-test.sh`); brief revision 2026-11-23, item 1 |
| B04 | "I have also played the GTA games up to GTA 4." | The student's answer, verbatim in `PROJECT-BRIEF.md` |
| B04 | "DERELICT does not try to be open-world." | scope: four rooms (`a2-redo`) |
| B05 | "The reader is a lead engineer, a hiring manager or a recruiter." | `PROJECT-BRIEF.md` §3 (the intended reader) |
| B05 | "In the finished version, they will unzip the build, run the game, press Start, and be shooting within a minute." | **will** (no export; not timed). The menu's Start button exists (`godot/game3d/menu.gd:72`) |
| B05 | "A tools reader will open the README and run one test command." | **will** |
| B05 | "None of that exists yet. There is no export today." | true: no `export_presets.cfg` in any commit |
| B06 | "Here is what exists today, by tag." | the tags `a2-redo`, `a3`, `a5`, `a6`, `a7` |
| B06 | "Shaders and materials, in assignment five." | tag `a5` (`c076952`): `low_ammo_test` 35 PASS ×3 rates, `test_materials` 74 PASS |
| B06 | "Two particle effects in assignment six, with their GPU cost measured on my RTX 4050 laptop, inside a budget set in advance." | tag `a6` (`9064ae8`): `TEST-REPORT.md` Price; `docs/evidence/a6/gpu_price.log`. NVIDIA GeForce RTX 4050 Laptop GPU; +0.018 / +0.023 ms against 0.30 / 0.20 ms. The budgets are in the A6 brief, committed before the change. Measured by Claude Code's script; the student's Visual Profiler read is pending |
| B06 | "Animation and state in assignment seven, with structure and edge tests." | tag `a7` (`660342c`): structure 51, edges 98 PASS lines |
| B06 | "And under all of it, verification: pinned tests, and mutations that had to fail." | pins: `test_pins_player.gd` 19 (`a7`); mutations: `a5` 3, `a6` 4, `a7` 3, each exit 1 |
| B07 | "These lines are copied from a real log of the reload edge test, from assignment seven." | `docs/evidence/a7/final/test_pistol_reload_edges_60fps.log` (`887266f`); `make_pitch.py` copies the lines by line number |
| B07 | "Fire, a second reload and death are tried at every phase boundary." | `TEST-REPORT.md` at `a7` (ticks 29–31, 59–61, 74–76) |
| B07 | "Ninety-eight checks pass, and none fail." | the same log: 98 lines start with `PASS`, 0 with `FAIL` (counted at build time). The 98 includes the final `PASS: 0 failure(s)` line, the A7 counting rule |
| B08 | "So what can you conclude? That I can specify, direct, verify and measure game systems with an AI agent." | `PROJECT-BRIEF.md` §4; the briefs, test reports and logs at `a5`–`a7` |
| B08 | "Not that I hand-wrote the shaders, effects or animation." | `CLAUDE.md` authorship; `SOURCES.md` |
| B08 | "I directed Claude Code to build them, and the repository says so." | `CLAUDE.md` (Authorship), each `TEST-REPORT.md` header |
| B08 | "And I have not yet judged the effects and the animation in play myself." | `docs/archive/HUMAN-CHECK-NOTES-a6.md` (17 pending), `HUMAN-CHECK-NOTES.md` (15 pending) |
| B09 | "In scope: one run from title to end screen, a Windows export, the layers already built, my own checks in my own words, and the known issues fixed or written down." | **will** (scope); "the layers already built" exist at their tags |
| B09 | "Out: multiplayer, saving, more rooms, new enemies and a web build." | scope decision (`PROJECT-BRIEF.md` §5) |
| B09 | "The first piece I will make run is the Windows export, played through to the end screen, with its checksum recorded." | **will** |
| B10 | "The risk is effects that pass their tests but don't look as designed." | `TUNING.md` at `a6`: config tests pass while the puff does not grow and the smoke is faint |
| B10 | "In assignment six, Claude Code found that in this Godot version, billboard particles ignore the particle scale, so the impact puff never grows." | `docs/evidence/a6/probe_particle_scale.log`; `TUNING.md` at `a6`, "diagnosed, not guessed" |
| B10 | "These are the fixture frames." | `captures/impact_burst/r0-light/strip.png` (`fe6044a`), `r1-light/strip.png` (`0788794`), both in `a6`; labelled FIXTURE on screen |
| B10 | "One fix was tried and reverted." | A-r1 `billboard_keep_scale` true, reverted (`TUNING.md` at `a6`) |
| B10 | "I will try the next one, judge it in play, and if it still fails, ship it as a documented limit." | **will** (A-r2 needs approval) |
| B11 | "Why this project? Mostly to learn." | the student's answer on why ("new skill that I have aquired …"), as `PROJECT-BRIEF.md` §7 reads it |
| B11 | "Godot shaders, particles, animation, testing, and directing an AI agent were all new to me, and the tagged assignments are the evidence." | `PROJECT-BRIEF.md` §7; tags `a5`, `a6`, `a7` |
| B11 | "What I already had was playing games like this one." | The student's answer (GTA up to 4, Call of Duty). Not claimed as a measured skill |
| B12 | "So, today: the core loop, three props, a shader, two effects, two animations and the toolkit, each at its tag." | `a2-redo`, `a3`, `a5`, `a6`, `a7`; `scripts/run-test.sh` from `a5` |
| B12 | "Still to come: the export, a scripted run against it, my own checks, the effect fixes, and a README a stranger can follow." | **will** |
| B13 | "That's DERELICT. The repository and its tag are on screen. Thanks for watching." | the repository URL and tag `a8` (set in Phase 7) |
