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

### 2026-10-07 — scope cuts and build decisions
- CHAR-RUN left out of the final state list; walk alone covers the "movement changed" read.
- The flashlight/darkness mechanic in CONCEPT.md's art direction was not built in this slice — the room is lit normally. This means predicted failure case #4 (readability in the dark) can't be tested; mark it not-tested in TEST-REPORT.md, not fixed.
- Re-grab: the zombie is shoved back at the moment of the grab and can walk back and re-grab if the player stands still through GRABBED-FAIL+RECOVER+invulnerability (~2.8s from the grab; the player can walk away for the last ~1.5s of it). An alternative (holding on until the player breaks free) was proposed and not built, for time. Current behavior is kept; flag as a known limitation if it feels punishing in playtest.
- The asset-list panel numbers here are off by one against STORYBOARD.md (from trimming 9 panels to 7 earlier) and reference panels 8-9, which no longer exist. Left uncorrected for time — STORYBOARD.md's numbers are what the build actually follows.

## Assignment 3 — first 3D assets

**Scope note:** DERELICT's gameplay is 2D top-down and is untouched by this assignment. These three assets live in a separate 3D showcase scene (floor, one light, one camera) added to this repository, per the assignment's explicit allowance that a 2D game's 3D assets don't need to connect to the game yet. Asset IDs below use a PROP-/ENV-/PICKUP- prefix to keep them distinct from the 2D game's CHAR-/ZOMBIE- IDs.

### 1. PROP-SUPPLY-CRATE
- **In-scene role:** a scavengeable supply crate prop, shown in the 3D showcase scene.
- **Size:** 0.5 m × 0.5 m × 0.5 m — scaled against the player capsule's rough human proportions, so it reads as a carryable crate.
- **Origin:** centre of the underside, so it sits flush on a floor.
- **Look:** a single box body with two thin cuboid straps across it. Flat materials: wood-brown body (~0.40, 0.24, 0.12 base colour), dark-gray metal straps (~0.08, 0.08, 0.08, slightly metallic).
- **Budget:** ≤100 triangles.

### 2. ENV-RUSTED-BARREL
- **In-scene role:** environment set-dressing — an industrial barrel for the derelict site.
- **Size:** 0.6 m diameter × 0.9 m tall.
- **Origin:** centre of the underside.
- **Look:** a single cylinder with a low segment count (8-12 sides, not Blender's 32 default) so it reads as round without wasting budget. Flat rust-orange material, matching CONCEPT.md's existing decay palette.
- **Budget:** ≤200 triangles — the only curved primitive of the three, so it gets the largest share.

### 3. PICKUP-MEDKIT
- **In-scene role:** a collectible medical-supply pickup.
- **Size:** 0.3 m × 0.2 m × 0.15 m.
- **Origin:** centre of the underside.
- **Look:** a box with a flattened lid and a simple cross (two thin crossed cuboids) on top. Flat cream case, red cross — deliberately high-contrast so it reads as a pickup.
- **Budget:** ≤150 triangles.

### Predicted failure cases
1. **An asset arrives lying on its side or rotated unexpectedly.** Check: after import, confirm each asset's Godot rotation reads 0,0,0, and that it visually stands upright.
2. **Scale isn't applied in Blender before export, so the asset is wrong by a large factor (e.g. ×10) in Godot.** Check: apply all transforms (Ctrl+A → All Transforms) before export; Godot's node scale should read 1,1,1.
3. **The origin sits at the object's centre instead of its base, so it floats or sinks into the floor.** Check: place each asset on the Godot floor plane and look from the side for a gap or clipping.
4. **The MCP server doesn't connect within a short time-boxed attempt.** Check/outcome: it connected cleanly (see FRICTIONAL.md) — this case didn't occur, kept here since it was a genuine prediction made beforehand.

### Revisions
(dated entries go here as the build proceeds)

#### 2026-10-15 — PROP-SUPPLY-CRATE built in Blender (not yet exported)
- Built via the Blender MCP in a cleared scene (default cube, light and camera deleted; units metric, metres, scale 1.0). No asset libraries or generators used.
- Single object `SupplyCrate`: body box plus two strap boxes, joined. Rotation and scale applied — rot 0,0,0, scale 1,1,1, origin at base centre (0,0,0).
- Size exactly 0.5 × 0.5 × 0.5 m. To hit that exactly, the straps fit inside the cube: the body is 0.50 × 0.48 × 0.49 m and the straps (0.06 m wide, at x = ±0.15) sit 1 cm proud on the top and ±Y faces. Straps run over the top and down the front/back; the ±X sides are plain.
- 36 triangles (budget ≤100). Materials: `M_Crate_Wood` (0.40, 0.24, 0.12, roughness 0.8), `M_Crate_Strap` (0.08, 0.08, 0.08, metallic 0.3, roughness 0.5).
- Known limitations: the parts are overlapping closed shells, not one merged surface, so some strap faces are hidden inside the body (counted in the 36). Strap and body bottoms are coplanar at z = 0 and may z-fight when seen from below (not visible on a floor).
- Open question: in Material Preview the wood reads as light tan, because the brief's colour values are applied as linear. If they were meant as sRGB, the body should be darker — to judge by eye.
- Not yet verified: export, Godot import (predicted failure cases 1–3), final render, showcase scene (floor, light, camera not built yet). The .blend file is not saved.
