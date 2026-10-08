# PROMPTS — DERELICT gamedev film

## B00, cold open (reconstructed, not a recording)
> Please use Walker to convert my game design document about DERELICT — a lone scavenger clearing a derelict factory, one infected, one exit — into a Godot 4 slice that proves generated art, sound and music working together.

Built from CONCEPT.md's two-sentence pitch and the slice scope in CHANGE-BRIEF.md. The real build happened over a step-by-step session; this prompt summarises its intent.

## B25, Your Turn (read aloud)
> Use Walker on my DERELICT project. In godot/scenes/player.gd, change max_tilt_deg from 30 to 45. Before running anything, predict what the 8-direction facing grid will show. Then re-render it and tell me whether the gun got closer to the shot, and how much more the figure leans.

Why this prompt:
- **One bounded change:** a single exported number (`player.gd` 40).
- **A prediction before acting.**
- **A concrete check:** the B16 grid, re-rendered with `captures/routes/facing_grid_c.gd`.
- **The trade-off is visible:** 45° moves the gun closer to the shot at north/south (45° off, not 60°) but leans the figure further.
- **Scope note:** the zombie has its own `max_tilt_deg` and won't change.

## Generation prompts shown in B17
Quoted from the repo's SOURCES.md line 27 (the student's own record):
- **Attempt 1:** "now the same character, celebrating" → rejected (blood drops, dropped weapon).
- **Correction:** "...celebrating, arms raised, no blood, no dropped weapon..." → accepted.
