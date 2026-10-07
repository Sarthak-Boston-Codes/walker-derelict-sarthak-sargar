# TEST-REPORT.md — DERELICT

Source revision: [commit SHA]
Engine version: Godot 4.7.2 (stable)

| Check | Evidence to collect | Result |
|---|---|---|
| Startup and controls | Scene runs from a fresh copy; movement and every state change work | [fill in] |
| Character against the sheet | In-engine screenshots of each state beside the character sheet poses; collision mismatches noted | [fill in] |
| Storyboard against the slice | Each panel the slice covers, beside an in-engine screenshot; differences listed | [fill in] |
| Sound events | Each of the 4 events fires exactly once per occurrence, including rapid repeats/held input | [fill in] |
| Music | Loop repeats with no click/gap; pause and end behave as predicted | [fill in] |
| Muted play | Slice still playable/understandable fully muted | [fill in] |
| Readability in the dark (CHANGE-BRIEF predicted failure #4) | In-engine screenshot at game resolution against the dark environment | **Not tested.** The flashlight/darkness mechanic was not built in this slice (room is lit normally — see CHANGE-BRIEF.md Revisions, 2026-10-07), so this case can't be checked. Not fixed. |
| Automated check | At least one scripted check (e.g., counting sound triggers per event), command + result | [fill in] |

## Known limitations
Documented, not fixed.

1. **Player readability against the factory floor (related to predicted failure #4, but distinct).** #4 is about the cut darkness mechanic and stays not-tested. This finding shows up in the *lit* room: once ENV-FACTORY-FLOOR was swapped in, the olive scavenger blends into the grey concrete and scattered debris (worst at the bottom-left spawn); the placeholder zombie still reads clearly.
2. **Floor art does not match the colliders — cosmetic only.** The painted brick walls are thicker than the 16 px wall colliders, the machinery and pipes have no collision, and the doorway gaps in the art are solid walls in-game. Collision behavior itself is unchanged and correct.
3. **Exit marker sits on the catwalk grating.** It reads less clearly there (raised walkway vs. floor is ambiguous), but it is still fully functional.

## Inspect-and-revise cycle
[At least one: what you observed, what you changed, why.]

## Playtester
[Your own playtest is required and comes first, with sound on AND muted — not filled in by Claude.]
