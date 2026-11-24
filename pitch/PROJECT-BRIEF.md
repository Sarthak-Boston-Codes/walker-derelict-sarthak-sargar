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
