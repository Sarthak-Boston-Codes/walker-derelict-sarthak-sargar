# PROMPTS — DERELICT A3 (3D assets) film

## B00, cold open (reconstructed, not a recording)
> Please use Walker to convert my game design document about DERELICT's first 3D assets — a supply crate, a rusted barrel and a medkit — into Blender models and a Godot showcase scene that proves each one matches its brief.

Built from CHANGE-BRIEF.md's Assignment 3 section. The real build happened over a step-by-step session; this prompt summarises its intent.

## B05, the crate prompt (author, verbatim excerpt from the session, 2026-10-15)
> Task: build only this asset: supply crate, exactly as the brief specifies (0.5x0.5x0.5m, origin at base centre, wood-brown body with dark-gray straps, ≤100 triangles). Start from an empty scene with metric units; Blender is Z-up.

## B06, the colour correction (author, verbatim excerpt from the session)
> The brief's RGB values were meant as normal sRGB colour-picker values (the kind you'd get from a hex code or colour swatch), not linear shader values. Convert them correctly (sRGB to linear) when setting M_Crate_Wood and M_Crate_Strap, re-render with look, and confirm it now reads as the intended darker wood-brown and dark gray.

## B22, Your Turn (suggested; read aloud verbatim)
> Use Walker on my DERELICT project. Rebuild the rusted barrel in Blender with 8 sides instead of 12. Before you export, predict its triangle count. Then export it, run godot/tests/showcase_3d_test.tscn, and tell me whether the prediction and the test agree.

The narration gives the prediction to check against (28) and asks the viewer to find out why before believing either result if they disagree.
