# REDO-LOG — Assignment 2 redo as a top-down 3D shooter

Branch `a2-redo-3d`. Summary goes here at the end.

## Decision log

1. **All new code lives in `godot/game3d/`.** The 2D slice (`godot/scenes/`, `godot/ui/`, `assets/asset_manifest.gd`, its tests) is untouched. The `Assets` and `Sound` autoloads are reused read-only.
2. **Scripts are wired with `preload`, not `class_name`.** New global class names need the editor's class cache rebuilt; preload works in a cold headless run without that.
3. **Level is built at runtime in `level.gd`** from boxes/cylinders (StaticBody3D on layer 1) instead of a hand-authored `.tscn`. It keeps the build unattended and every number lives in one readable file. Navmesh bakes from static colliders on layer 1 only, so props (layer 4) never cut holes.
4. **The 2D floor art (`art/env_factory_floor.png`) is not used as a 3D floor** — it's a whole illustrated room with walls painted in, so it doesn't tile. A small world-space concrete shader (`game3d/shaders/concrete_floor.gdshader`) gives slabs, seams, rust and oil stains instead.
5. **Walls are 2.4 m, not 3 m.** The camera sits high and to the south; taller walls hid the player when standing just north of a wall.
6. **Lighting baseline:** dim cool ambient (0.55), ACES tonemap, volumetric fog, glow and SSAO. My first pass (ambient 0.22) was unreadably dark in screenshots, so I raised it; the flashlight is meant to be the main light, but rooms must still read.
7. **New 3D model swap table is `game3d/model_table.gd`** (a separate file, so the 2D `asset_manifest.gd` stays untouched). One line per model: `{"path": "", "scale": 1.0, "yaw": 0.0}`; empty path = generated placeholder.
8. **Main scene is now `res://game3d/game.tscn`** (later the menu). The 2D slice still runs via `scenes/main.tscn`.
9. **Screenshot harness `tests/game3d_shot.tscn`** (windowed) is how I checked visuals during the unattended build.
