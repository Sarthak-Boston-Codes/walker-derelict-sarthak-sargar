extends RefCounted
## Physics layer bits shared by every 3D game script.

const WORLD := 1 # walls, floor, machines: the only layer baked into the navmesh
const PLAYER := 2
const ZOMBIE := 4
const PROP := 8 # crates and barrels
const PICKUP := 16

## What a bullet can hit.
const SHOT_MASK := WORLD | ZOMBIE | PROP
