extends RefCounted
## How a character sprite is drawn for a given facing direction.
##
## Art convention: stored upright as generated, facing east (weapon on the
## right). The art has a baked-in elevated perspective, so it is never
## rotated far: mirror it left/right by which side `dir` points to, then tilt
## toward `dir` by at most max_tilt. Gameplay direction (aim, shots) stays a
## full 360 degrees; only the drawn angle is limited.


static func apply(sprite: Sprite2D, dir: Vector2, max_tilt: float) -> void:
	if dir == Vector2.ZERO:
		return
	# Straight up/down has no side: keep the current one so it doesn't flicker.
	if absf(dir.x) > 0.01:
		sprite.flip_h = dir.x < 0.0
	var forward := Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	sprite.rotation = clampf(forward.angle_to(dir), -max_tilt, max_tilt)
