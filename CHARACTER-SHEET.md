# CHARACTER-SHEET.md — the scavenger

**Sketches: `design/character/sheet.svg`** — one combined sheet, all 10 poses plus the collision note. (Made for you given the time crunch — open it, and if you want anything changed, just say what.)

- **Concept in one sentence:** A lone scavenger in practical, worn gear — flashlight mounted on one shoulder, sidearm held low-ready — reads instantly as cautious, not as a soldier on a mission.
- **Silhouette at on-screen size:** pose 2 on the sheet — filled solid black at actual in-game scale (48×48 px top-down sprite; adjust once your real scene scale is set).
- **Orientation:** Art is stored upright as generated, facing east (screen-right, weapon on the right) — no separate directional sprites generated. The generated art has a fixed elevated perspective, not true top-down, so it is never freely rotated (that drew it upside-down facing north and with the gun 90° off the aim). At runtime the sprite is mirrored left/right by which side the aim/movement points to, then tilted toward it by at most ±30° (`godot/scenes/facing.gd`). Aim and shots stay a full 360°; the ready cue and tracer show the true direction. Accepted limitation: aiming straight up or down, the drawn gun is ~60° off the actual aim. Mirroring also swaps which shoulder the flashlight appears on when facing left.
- **Reference:** pose 1 on the sheet — neutral standing, straight-on from directly above, full detail. Every other pose is checked against this.

## Poses (10 — meets the minimum)
1. **Reference / neutral standing** — locks proportions and gear placement
2. **Silhouette at game size** — proves the shape reads before detail is added
3. **Idle** (CHAR-IDLE) — flashlight on, scanning; the pose the player sees most
4. **Walk** (CHAR-WALK) — cautious stride, weapon lowered
5. **Aim** (CHAR-AIM) — weapon raised, the deliberate wind-up before firing
6. **Shoot follow-through** (CHAR-SHOOT-FOLLOWTHROUGH) — recoil settling, confirms the shot happened
7. **Hurt** (CHAR-HURT) — recoiling from a scratch or grab, flinch readable from any angle
8. **Grabbed / fail** (CHAR-GRABBED-FAIL) — the failure beat from Storyboard Panel 5
9. **Recover** (CHAR-RECOVER) — breaking free, re-arming; control returning after a hit
10. **Celebrate** (CHAR-CELEBRATE) — the relief beat at a cleared extraction, Storyboard Panel 7

## Collision overlay
A single circle/capsule collider centered on the torso, roughly matching body width (see note on the sheet, under pose 1). Identical and centered the same way across every pose. Fair to the player: the collider only ever needs to contain the body an infected can actually grab or that a shot can actually hit — not the equipment.

## Palette
- Gear/clothing: `#4A4F4D` (muted olive-gray)
- Skin tone: `#C9A27E` (adjust to taste)
- Flashlight / warm accent: `#F2C14E`
- Rust / decay accent (shared with environment art): `#8B4A2B`
- Outline / shadow: `#1C1C1C`

Checked against the environment: the flashlight yellow and outline black are the two colors guaranteed not to appear in the dim concrete/rust environment palette, so the character silhouette separates from the background even in low light.

## Consistency rules
Same proportions (height, head-to-body ratio) in every pose. Same outline weight throughout. Same equipment placement — flashlight always on the same shoulder, weapon always in the same hand — in every state. Same five palette colors across all poses; no new colors introduced pose-to-pose.
