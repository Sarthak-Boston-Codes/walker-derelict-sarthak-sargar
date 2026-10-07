# walker-derelict-sarthak-sargar

**DERELICT.** Extension of nothing — new project, started from an empty Godot 4 project. Built for CSYE 7270, Assignment 2.

## What this is
A lone scavenger explores a derelict site, avoiding or shooting the infected, in a small playable slice proving generated art, sound, and music work together in Godot. See CONCEPT.md for the full pitch.

## Engine
Godot 4.7.2 (stable), GDScript.

## Run instructions
1. Open `godot/project.godot` in Godot 4.7.2 and press Play (F5) — or `godot --path godot` from the folder.

## Controls
WASD to move · hold right mouse to aim · left click to fire · M toggles music · N toggles sound effects.

## What the slice demonstrates
- Player character in at least two states (art)
- One environment asset (art)
- Four sound events tied to real gameplay triggers (sound)
- One looping music track (music)
- Mute control; slice remains readable muted

## Known limitations
- Player readability against the final floor art (related to, but distinct from, predicted failure case #4 — the flashlight/darkness mechanic from CONCEPT.md was not built in this slice, so that predicted failure case is not tested, not fixed).
- Floor art details (walls, machinery, doorway gaps) don't match the actual collision shapes — cosmetic only, collision behavior itself is correct.
- The exit marker sits on the catwalk grating in the floor art — reads less clearly there, but is still fully functional.
- CHAR-HURT and CHAR-GRABBED-FAIL are both off-palette (blue-grey rather than the specified olive/tan).
- CHAR-IDLE's baked-in flashlight beam direction doesn't match the implied light direction in CHAR-AIM/CHAR-SHOOT-FOLLOWTHROUGH.
- CHAR-WALK/CHAR-RECOVER/CHAR-CELEBRATE are drawn from a slightly different art angle and come out larger than the other five poses.
- The character art has a fixed-elevation perspective rather than true top-down; the sprite is mirrored and tilted (±30°, capped) toward the aim direction rather than freely rotated, so the held weapon doesn't always point exactly where the shot goes, especially when aiming straight up or down.
- The zombie can re-grab the player if they stand still through the full hurt/recover/invulnerability window (~2.8s).
- See TEST-REPORT.md and SOURCES.md for full detail, including rejected generation attempts.

## Final film
[link — add once rendered]
