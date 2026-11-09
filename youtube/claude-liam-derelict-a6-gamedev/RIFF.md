# RIFF: commentary grounded in inspected output

- The most instructive result is a setting that does nothing. The brief's scale rows load, read back correctly and pass the configuration test, yet no particle changes size, because the billboard draw step drops the process scale. Only a capture showed it, and only a probe explained it.
- The Godot 3 rename failed loudly in the test and silently everywhere else: no warning on load, and the effect still fired with slower sparks.
- A one-shot emitter's `emitting` means "still emitting new particles", not "still visible". The first state test believed the second meaning and counted one live burst under held fire.
- The wound smoke needed a control run to be seen at all. By eye, the first strip said "nothing"; the diff said "a small patch on the player". The second revision's prediction mostly held; the first's did not, and the failure pointed at the real cause.
- In motion the smoke trail reads well, as pale discs behind the player. In the stationary strip it barely leaves the silhouette. The strip is the worst case, not the game.
