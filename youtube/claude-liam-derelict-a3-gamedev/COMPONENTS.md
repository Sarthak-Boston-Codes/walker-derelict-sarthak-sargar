# COMPONENTS — DERELICT A3 (3D assets) film

Scope: the Assignment 3 additions inside `godot/`. Everything else (the 2D slice) is excluded with a reason in `gamedev-evidence.json` and covered by `youtube/claude-liam-derelict-gamedev`.

| Component | Files | Beats | What enters → what changes → what the viewer sees | Design choice / trade-off |
|---|---|---|---|---|
| `glb_assets` | `assets/3d/{supply_crate,rusted_barrel,medkit}.glb` + `.import` | B09, B10, B11 | Blender exports (+Y up, transforms applied) → imported as PackedScenes → three props on the floor | Inspected as files, not trusted from Blender's view. Trade-off: overlapping closed boxes leave hidden interior faces counted in the budget |
| `showcase_scene` | `scenes/showcase_3d.tscn` | B10, B11, B17, B18, B19 | Three instances with position only, floor plane, one shadowed DirectionalLight3D, one Camera3D | No transforms of its own, so a bad asset isn't masked. Trade-off: a single light with no ambient leaves shadowed sides very dark; the one-sided floor vanishes from below |
| `showcase_test` | `tests/showcase_3d_test.gd`, `.tscn` | B12, B13, B15, B16 | Brief table (Y-up sizes, budgets) → per asset and per mesh node: rotation, scale, floor contact, size, triangles → PASS / FAIL, exit code = failures | Walks mesh nodes, so an unapplied Blender scale is caught (B16). Trade-off: the printed SCALE column shows only the instance root, so the evidence shows up in SIZE; it can't judge looks |

Input → state → output trace (B14 → B15 → B16): an S-key scale left unapplied in Blender → exported as node scale 1.95508 on the mesh → the test's mesh-node and size checks fail the medkit, exit 1.
