# PROJECT-BRIEF.md — DERELICT final project pitch

Working title: **DERELICT**. Student: Sarthak Sargar. Target role: **gameplay programmer**, with **tools programmer** as the second role. Written by Claude from the student's three answers (below) and the repository's own records. The film's script, visuals, captures and the other documents in `pitch/` are written by Claude Code. Dated revisions go at the bottom. References marked (verify) are checked by Claude Code against the repo before the film is built, and corrected by a dated revision.

**The student's own words, as given in chat (verbatim):**
- Role: "tool s programmer would be good and also gameplay programmer!"
- Comparables: "I have played GTA (all of them till gta 4) and also Call of Duty!"
- Why: "new skill that I have aquired is that I have made significant focused work and also my gaming skills have increased a lot!"

How the pitch uses them: the two roles as stated. Both games as the student's played comparables. "Gaming skills have increased" is left out of the film's claims, because nothing in the repository measures it. "Significant focused work" is shown through the tagged assignments, not asserted.

## 1. What is it?
**One sentence:** DERELICT is a small top-down 3D zombie shooter in four connected factory rooms, lit by a flashlight, that I will take to a finished one-run vertical slice (title screen to win or death screen), together with the one-command test and capture toolkit that verifies every layer of it.

**What exists when it is done:** a Windows desktop export of the slice (Godot 4.7.2, Forward+ renderer, one folder with the `.exe`), and the repository `walker-derelict-sarthak-sargar` with its tests and tools, so a reviewer can rerun the checks.

## 2. Why would anyone care, and what makes it different?
- **What it gives the player:** a short run in the dark, where a flashlight, a hit burst where every bullet lands, smoke from your own wounds, a warning when the magazine runs low and a visible reload tell you what is happening without reading the HUD.
- **What it gives a reviewer:** a small game where each layer was specified in a brief, pinned by a behaviour test, attacked with mutations that had to fail, and measured, so they can check how I work in a few minutes.
- **Comparables I have played:** Call of Duty's zombies mode is the nearest. DERELICT is single-player, top-down, four rooms, and small enough to open in a minute. It is not bigger, deeper or better than that game; the difference is that every layer has a test and a measured cost a stranger can rerun. GTA (the games up to GTA 4) is the other game I have played; DERELICT does not try to be open-world, and I mention it only to say what is out of scope.

## 3. Who opens it, and what do they do?
- **Reader:** a lead engineer or hiring manager at a game studio, or a recruiter.
- **Target roles:** gameplay programmer (the player, zombie, pickup and HUD state systems, with their pinned and edge tests) and tools programmer (the test wrapper, the read-back checks, the capture and measurement scripts, the mutation workflow).
- **First sixty seconds (will, not yet true):** unzip the export, run `DERELICT.exe`, reach the menu, press Play and be shooting within a minute without reading anything. The tools reader instead opens the README and runs one test command. A stopwatch run of both paths is part of the work and is not done yet.

## 4. What does it prove about me?
Tied to what the course teaches, and to what exists today (tag in brackets):
- **Shaders and materials:** a state shown by a shader (low ammo turns the counter red) and a textured material, both specified before they were built [a5].
- **Particle effects:** two effects, a one-shot hit burst and a value-driven wound smoke, with tuning records and a measured price [a6].
- **Animation and state:** a looping keycard icon and a committing reload action, one authority over each, a state machine with a structure test and edge tests at every phase boundary [a7].
- **Profiling:** headless CPU price with a control, and GPU time on my RTX 4050 laptop GPU against a budget set in advance [a6].
- **Verification habits:** pinned behaviour tests, headless checks and the human checks they cannot replace, mutations run in worktrees that had to fail, and directing an agent with scoped tools and checking its work.

**What a reviewer can fairly conclude:** that I can specify, direct, verify and measure game systems with an agent. **What they cannot:** that I hand-wrote the shaders, effects or animation. Claude wrote them under my direction, and the repository's documents say so. The human checks (watching the effects and animation in play) are still pending, and the film says so.

**Evidence:** the tagged test reports with their counts (verify: Claude Code fills the numbers from `TEST-REPORT.md` at each tag), the mutation logs, the cost logs, and the fixture strips.

## 5. What is in, what is out, what comes first?
- **In:** one run from title screen to end screen; a Windows desktop export; the layers already built; the pending human checks done and recorded in my own words; the known issues fixed or documented; a README that lets a stranger rerun the tests.
- **Out (deliberately):** multiplayer, a save system, more than the four rooms, new enemy types, and a web export.
- **First piece to make run:** the Windows export, launched from its `.exe` to the menu and through one run to the end screen. Someone would know it ran from the export's recorded SHA-256, a scripted run against the exported build that reaches the end screen, and my own playtest recorded in my words.

## 6. What could sink it?
**The risk:** two effects pass their tests but do not yet look as designed on screen. In Godot 4.7.2, billboard particles ignore the process scale, so the impact puff does not grow (found and logged in A6), and the wound smoke is faint over the floor. Nobody has judged either in the running game yet. **What I would do:** apply the pending fix, recapture the strip, judge it myself in play, and if it still fails, ship it as a documented limitation and say so in the film.

## 7. Why this project?
Mostly learning, with a little showing off. The skills that are new to me are Godot shaders, particle effects, animation and state, testing, and directing an AI agent with scoped tools. The evidence for them is the tagged assignments, test reports and captures. What I already had is the experience of playing this kind of game (GTA up to 4, Call of Duty). Nothing in the repository measures that, so I do not claim it as a skill.

## Exists today
(Claude Code fills each line with the tag or commit and the real counts, from `TEST-REPORT.md` at that tag.)
- 3D game core loop: menu, four rooms, player, two zombie types, waves, pickups, win and death screens [a2-redo] (verify)
- Three Blender-built props shown in a showcase scene [a3] (verify)
- Low-ammo shader and textured materials [a5]
- Impact burst and wound smoke, with tuning records and cost measurements [a6]
- Keycard spin and pistol reload, one authority, state and edge tests [a7]
- A test and capture toolkit: `scripts/run-test.sh`, read-back checks, capture and measurement scripts

## Will exist
- A Windows desktop export of one run, with its SHA-256
- A scripted run against the export that reaches the end screen
- My own playtest and human checks, recorded in my words
- The impact-burst and wound-smoke fixes, recaptured and judged by me
- A README a stranger can follow to play and to rerun the tests

## Revisions
(Dated entries below. The text above stays as committed.)

### 2026-11-23 — Phase 0 verification against the repository (Claude Code)

Checked on branch `a8-pitch` (from `refs/heads/a7-animation`, top `bafe6eb`). Every claim above was read against the tags with `git show refs/tags/<tag>:<file>`.

**Tags (all lightweight, all present):** `a3` → `b91201c` (2026-10-15), `a2-redo` → `48eec7e` (2026-10-25), `a5` → `c076952` (2026-10-29), `a6` → `9064ae8` (2026-11-08), `a7` → `660342c` (2026-11-22).

**Exists today, filled in (replaces the "(verify)" markers; counts from `TEST-REPORT.md` at each tag unless named otherwise):**
- 3D game core loop: menu, four rooms (Loading Bay, Assembly Hall, Boiler Room, Control Room, `level.gd:37-40`), player, two zombie types (shambler, runner, `waves.gd:40`), waves, pickups, a win screen (extraction, `State.WON`) and a death screen (`State.DEAD`) [`a2-redo`, `48eec7e`]. **Correction:** `TEST-REPORT.md` at `a2-redo` is still the A2/A3 report and holds no counts for the 3D game. The counts come from `REDO-LOG.md` at that tag: `game3d_smoke_test.tscn` with 27 checks (PASS) and a 4-minute soak bot (no script errors). The same 27 checks pass at `a5`, `a6` and `a7`.
- Three Blender-built props (supply crate, rusted barrel, medkit) in `scenes/showcase_3d.tscn` [`a3`, `b91201c`]: `showcase_3d_test.gd` exit 0 (rotation, scale, floor contact; triangle budgets 36/100, 44/200, 48/150). **Correction on order:** `a3` comes before `a2-redo` in time. At `a3` the project was still the 2D slice, with a 3D showcase scene; the 3D game built at `a2-redo` reuses the three props.
- Low-ammo shader and textured materials [`a5`, `c076952`]: `low_ammo_test.gd` 35 PASS at 30, 60 and 144 fps; `test_materials.gd` 74 PASS; three mutations, each exit 1.
- Impact burst and wound smoke, with tuning records and cost measurements [`a6`, `9064ae8`]: `test_impact_burst_config.gd` 108 PASS; `test_wound_smoke_config.gd` 39 PASS; both state tests PASS; four mutations, each exit 1. GPU price, from a script reading the RenderingServer GPU counter on the NVIDIA GeForce RTX 4050 Laptop GPU (log `docs/evidence/a6/gpu_price.log`): burst +0.018 ms against a 0.30 ms budget, smoke +0.023 ms against a 0.20 ms budget. Both sit at the counter's noise floor.
- Keycard spin and pistol reload, one authority, state and edge tests [`a7`, `660342c`]. Counts are lines starting with `PASS`: keycard read-back 32, reload read-back 57, structure 51, state 34, pins 19 (identical before and after wiring), edges 98. The two-clocks test exits 0 at 60 and 30 fps: the clip trails the game by exactly one frame, where the A7 brief predicted under one. Mutations 1–3 exit 1; mutation 4 exits 0, as expected.
- Test and capture toolkit [`a5` onward, extended at `a6` and `a7`]: `scripts/run-test.sh`, the read-back checks, the capture scripts (`godot/previews/`, `godot/tools/`), and the cost and GPU scripts.

**Corrections and cuts:**
1. §2 says each layer "was specified in a brief, pinned by a behaviour test, attacked with mutations that had to fail, and measured". That holds from `a5` on only. The core loop (`a2-redo`) and the props (`a3`) have a smoke test, a soak bot and a showcase check, but no mutations. Measured cost exists only at `a6`, and behaviour pins (`test_pins_player.gd`) only at `a7`. The film says "from the shader assignment on".
2. §6, "the pending fix": A6 tried revision A-r1 (`billboard_keep_scale` true) and **reverted** it, because the puff became too small (`TUNING.md` at `a6`). The pending fix is A-r2 (keep_scale **and** a raised Puff scale, two settings), which still needs approval. The finding itself is confirmed by `docs/evidence/a6/probe_particle_scale.log` and by the strips in `captures/impact_burst/r0*/` and `r1*/` (fixture captures).
3. §3 and "Will exist", "my own playtest": the student has partly played the game already. There was an author playtest at A2 (`TEST-REPORT.md` at `a3`/`a2-redo`), and a playtest on 2026-10-29 recorded verbatim in `docs/archive/HUMAN-CHECK-NOTES-a5.md` ("I played the game myself…"; "I also saw the ammo counter turn red at 5 rounds or fewer…"). Still pending: every A6 and A7 human check (17 rows in `docs/archive/HUMAN-CHECK-NOTES-a6.md`, 15 in `HUMAN-CHECK-NOTES.md`), most A5 rows, and a playtest of the finished export. The film says only that the effects and the animation have not yet been judged in play.
4. Renderer and engine confirmed: Godot 4.7.2, Forward+ (`project.godot:15`), D3D12 (`:91`). No export exists: no commit contains a `godot/export_presets.cfg`.
5. The GPU name is confirmed (`RenderingServer.get_video_adapter_name()`, `TEST-REPORT.md` at `a6`). The film quotes no frame rate: the A2 redo's "137 FPS with 14 zombies" (`REDO-LOG.md`) has no committed log, so it is left out.
6. Unverifiable, so left out of the film's claims: "gaming skills have increased" (as the brief already says).

### 2026-11-23 — final lists, after verification and the film (Claude Code)

The two lists as the film shows them (B12), with tags and counts. They replace the lists above for the film; the text above is unchanged.

**Exists today**
- 3D game core loop: menu, four rooms, player, two zombie types, waves, pickups, win and death screens [`a2-redo` `48eec7e`; `game3d_smoke_test` 27 checks, soak bot]
- Three Blender-built props in a showcase scene [`a3` `b91201c`; `showcase_3d_test` exit 0]
- Low-ammo shader and textured materials [`a5` `c076952`; `low_ammo_test` 35 PASS at 30/60/144 fps, `test_materials` 74 PASS, 3 mutations exit 1]
- Impact burst and wound smoke, with tuning records and cost measurements [`a6` `9064ae8`; configs 108 + 39 PASS, 4 mutations exit 1; GPU +0.018 / +0.023 ms against 0.30 / 0.20 ms on the NVIDIA GeForce RTX 4050 Laptop GPU]
- Keycard spin and pistol reload, one authority, state and edge tests [`a7` `660342c`; read-backs 32 + 57, structure 51, state 34, pins 19, edges 98 PASS lines]
- A test and capture toolkit: `scripts/run-test.sh`, read-back checks, capture and measurement scripts [`a5`–`a7`]
- The student's own playtests: A2 (author playtest) and A5 (2026-10-29, verbatim in `docs/archive/HUMAN-CHECK-NOTES-a5.md`)
- This pitch film [`a8`; `pitch/README.md`]

**Will exist**
- A Windows desktop export of one run, with its SHA-256
- A scripted run against the export that reaches the end screen
- My own playtest of the export, and my A6 and A7 human checks, recorded in my words
- The impact-burst and wound-smoke fixes (A-r2 needs approval first), recaptured and judged by me
- A README a stranger can follow to play and to rerun the tests
