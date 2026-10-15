# RIFF — DERELICT A3 (3D assets) film

| Artifact + range | Visible observation | Interpretation (source) | Narration | Next experiment |
|---|---|---|---|---|
| `media/B11.mp4` 0–8 s | Crate, barrel, medkit upright on the floor, shadows to the back-left; nothing moves | Instances carry position only, so this is what the GLBs are (showcase_3d.tscn 29–35) | "all three upright, on the floor, casting shadows" | Add a fill light and compare the shadowed sides |
| `captures/b18_*` | −20°: cross a few pixels; −35°: cross reads | Camera angle, not only cross size, controlled readability (CHANGE-BRIEF.md Revisions) | "One problem, two fixes." | Try −35° with the original cross to isolate the camera's share |
| `media/B19.mp4` 0–10.5 s | Full turn: no missing faces; back faces of crate and barrel near black | One directional light, no environment fill | "the shadowed sides go very dark" | WorldEnvironment ambient |
| `media/B19.mp4` 10.5–14 s | Dip below y = 0: floor disappears, props seen from underneath | PlaneMesh is single-sided | "the floor isn't drawn at all" | Check whether a game camera can ever get there; if not, it doesn't matter |
| `logs/showcase_handedit_fail.log` | Medkit FAIL, SCALE 1.00, SIZE 0.587 × 0.293 × 0.391 | Scale lives on the imported mesh node, not the instance root | "The scale column still says one. That's the instance." | Print the mesh node's scale in the row |

Observations come from inspected frames and recorded logs; the B19 pass is a scripted capture camera, not a human playtest (the author's own walk-around was in the editor).
