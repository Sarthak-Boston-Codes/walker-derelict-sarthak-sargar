# CHANGE-BRIEF.md — DERELICT

Started from: empty Godot 4 project. Top-down 2D, single-room slice.

## Asset list

| ID | What it is | Storyboard panel |
|---|---|---|
| CHAR-IDLE | Player idle, flashlight on | 2, 3 |
| CHAR-WALK | Player walking | 2, 7 |
| CHAR-RUN | Player running | (available if the slice uses it) |
| CHAR-AIM | Player raising weapon | 4 |
| CHAR-SHOOT-FOLLOWTHROUGH | Player post-shot recoil | 5 |
| CHAR-HURT | Player flinch | 6 |
| CHAR-GRABBED-FAIL | Player grabbed / fail state | 6 |
| CHAR-RECOVER | Player recovering after a hit | 7 |
| CHAR-CELEBRATE | Player at successful extraction | 9 |
| ZOMBIE-SHAMBLE | Infected, approaching/alive state | 4, 8 |
| ZOMBIE-DOWN | Infected, defeated state | 5 |
| ENV-FACTORY-FLOOR | Background/tile set, main room | 2 |
| SFX-SHOT | Weapon fire (action) | 5 |
| SFX-DOWN | Infected defeated (success) | 5 |
| SFX-HURT | Player hit (failure) | 6 |
| SFX-CLEAR | Extraction reached (completion) | 9 |
| MUS-LOOP | Exploration music loop | 2, 7, 9 |

## Event-to-sound map

| Sound | Triggers on | Anti-double-trigger method |
|---|---|---|
| SFX-SHOT (action) | Player fires | One-shot per discrete fire input, gated by a short per-shot cooldown on the weapon — not re-fired while the button is merely held |
| SFX-DOWN (success) | An infected's state flips alive → defeated | Fires once on that state transition only, not on every frame the infected stays defeated |
| SFX-HURT (failure) | An infected successfully touches the player | A brief invulnerability window (~1s) after a hit blocks a second trigger from the same or another infected during that window |
| SFX-CLEAR (completion) | Player enters the extraction trigger zone | Fires once on zone-enter (`body_entered`), guarded by a boolean flag so re-entering the zone doesn't refire it |

## Music behavior
Plays continuously during exploration. **Pause:** pauses with the game, no separate handling needed. **Failure:** not interrupted — SFX-HURT itself communicates the failure. **Success/end:** fades out over ~1–2 seconds as SFX-CLEAR plays, so the session's end is clear even muted (the lit extraction point backs this up visually).

## Must remain unchanged
N/A for this assignment — this is a new project, not an extension of an existing one. (If later reusing any Assignment 1 structure, e.g. a pause-menu pattern, note it here and credit it in SOURCES.md.)

## Predicted failure cases

**1. Generated poses drift from the reference between separate generations.**
*Check:* overlay each new pose against `reference.png` and `silhouette.png` at the same scale before accepting it.

**2. A sound fires more than once for a single event** — holding the fire button double-triggers SFX-SHOT, or standing inside an infected's hit-zone for several frames re-triggers SFX-HURT.
*Check:* a scripted repeated-input test logging trigger count per event over a fixed number of ticks.

**3. The music loop (MUS-LOOP) clicks or gaps at its seam.**
*Check:* listen to at least three consecutive loop repetitions back to back.

**4. The player or infected becomes hard to see against the deliberately dark environment** — a real risk given the art direction's near-total-darkness choice.
*Check:* an in-engine screenshot at actual game resolution, compared against the silhouette test, confirming both characters read against the real background, not just in isolation.

## Revisions
(none yet)
