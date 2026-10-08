# SCRIPT — DERELICT: Wiring Generated Art Into Godot

Narrator: Liam (in for Bear), Kokoro `am_onyx`. Generated from beat_sheet.json; edit there, not here.

**B00 · ASK** · ~22s · 54 words · _ClaudeComposerAsk_

> Jambo — this is Liam, in for Bear. A student built DERELICT: a top-down Godot game where a scavenger clears one derelict factory room, with its art and sound made by generative models, all but the zombie. So I asked Claude to take the game apart and show how those assets actually got in.

**B01 · BLUF** · ~12s · 27 words · _BrutalistHesitantWriter_

> Generated art gets wired in, not dropped in. One table, one line each, and a test for every sound. That wiring is what this film takes apart.

**B02 · SETUP** · ~21s · 51 words · _GodotDevWorkbench_

> The assignment: a player in at least two art states, one environment, four sound events on real triggers, one looping track, and a mute that leaves the game readable. It started from an empty Godot four point seven point two project. Everything you see comes from one commit, shown on screen.

**B03 · ANATOMY** · ~17s · 41 words · _GodotDevWorkbench_

> One main scene: a floor sprite, four wall colliders, the zombie, the player, the exit marker, a fixed camera and the HUD. Above it sit two autoloads. Assets resolves every asset ID. Sound owns the music, the effects, and both mutes.

**B04 · MECHANISM** · ~20s · 49 words · _GodotDevWorkbench_

> Here's the heart of it. Every art ID from the change brief has one line in this table. An empty string means the game draws a generated placeholder at runtime; a real file path loads the file. Each swap was one line. The zombie's two lines are still empty.

**B05 · RESULT** · ~9s · 22 words · _media/B05.png_

> Same frame, same code. Left: an isolated copy with every art path blanked — circles and a grid. Right: the real build.

**B06 · MECHANISM** · ~15s · 36 words · _GodotDevWorkbench_

> The shot is deliberate. Holding aim enters AIM, and a click only fires once that state has lasted a quarter of a second, the wind-up. A faint ready cue shows exactly when a click would work.

**B07 · RESULT** · ~6s · 13 words · _media/B07.mp4_

> Aim. The cue appears. Click: follow-through, and the tracer stops on the zombie.

**B08 · MECHANISM** · ~15s · 36 words · _GodotDevWorkbench_

> A grab is guarded. Take-hit refuses while the player is hurt, grabbed, recovering or celebrating, and for one second after. Only a landed hit plays the hurt sound, and the arrow points back at the attacker.

**B09 · RESULT** · ~6s · 13 words · _media/B09.mp4_

> Contact. Hurt, arrow on the zombie. Grabbed, no control. Recover, and walk away.

**B10 · MECHANISM** · ~13s · 31 words · _GodotDevWorkbench_

> The zombie can't vanish on impact. take-shot flashes it for a hundred and fifty milliseconds, then go-down runs, the only place the down sound is played, so it fires exactly once.

**B11 · RESULT** · ~4s · 7 words · _media/B11.mp4_

> The flash, then the body. Now listen.

**B12 · LISTEN** · ~4s · 0 words · _media/B12.mp4_

> *(no narration: the game's own audio plays: shot, collapse, music)*

**B13 · MECHANISM** · ~19s · 45 words · _GodotDevWorkbench_

> Music and effects live on separate buses, and M and N each flip one bus's mute. Muting silences a bus without stopping what's playing on it, so a sound muted halfway can come back as a tail. The capture waits out the collapse before unmuting.

**B14 · RESULT** · ~9s · 21 words · _media/B14.mp4_

> M: music off. N: effects off. A silent kill still reads. The sound comes back, and a shot you can hear.

**B15 · MECHANISM** · ~17s · 40 words · _GodotDevWorkbench_

> The generated art is drawn from a fixed, elevated angle, so spinning it freely turned it upside-down. Facing mirrors the sprite to the side you aim at, then tilts it at most thirty degrees. The shot itself still goes anywhere.

**B16 · RESULT** · ~16s · 39 words · _media/B16.png_

> Left, the first build rotating freely: upside-down facing north, the gun ninety degrees off. Right, mirror and tilt: upright everywhere. Straight up or down, the gun is still sixty degrees off the shot. That trade is on the record.

**B17 · TRACE** · ~20s · 49 words · _STILL_

> One asset, end to end. Storyboard panel seven and pose ten asked for a calm success beat. Per the asset log, the first prompt came back with blood and a dropped gun, and was rejected. The correction asked for arms raised, no blood, no dropped weapon, on solid green.

**B18 · MECHANISM** · ~15s · 36 words · _STILL_

> The green comes off with a short script. Alpha is how green a pixel is compared with the background sampled from the border. Then the key colour's share is subtracted, so the edges don't glow green.

**B19 · RESULT** · ~10s · 23 words · _media/B19.png_

> Raw output, keyed to real alpha, then scaled by the same factor as every other pose, to a hundred-sixty-nine by ninety-two pixel sprite.

**B20 · MECHANISM** · ~16s · 38 words · _GodotDevWorkbench_

> It reaches the screen through one asset-table line and the exit marker. The first player entry sets a flag, calls celebrate, plays the clear chime and fades the music. The flag, not the trigger, stops a second chime.

**B21 · RESULT** · ~6s · 14 words · _media/B21.mp4_

> The walk to the exit. Celebrate. The chime, and the music fading to nothing.

**B22 · MECHANISM** · ~15s · 37 words · _GodotDevWorkbench_

> The test that guards all of this runs the real scene for a fixed number of physics ticks. This scenario pins the player on the zombie through the whole hit chain and expects exactly one hurt sound.

**B23 · RESULT** · ~19s · 47 words · _media/B23.png_

> It passes. On a copy with the four guards removed, it fails four times: one shot became four, one hurt became a hundred and thirty-five. What it can't tell you is whether anything is audible. It counts calls, and it teleports. That's why the listening beat exists.

**B24 · VERDICT** · ~29s · 72 words · _ClaudeVerdictArtifact_

> Implemented: eight states, one infected, a real floor, four sounds and a loop, separate mutes, and a test that fails when its guards are removed. Limits: the olive scavenger fades into the floor, the poses drift in palette and angle, the zombie is still a placeholder, and the flashlight darkness was cut. Human judgment: the student played it with sound on and muted, and confirmed the loop and the fade by ear.

**B25 · HANDOFF** · ~33s · 80 words · _ClaudeComposerAsk_

> Your turn. Paste this: 'Use Walker on my DERELICT project. In the player script, change max tilt degrees from thirty to forty-five. Before running anything, predict what the eight-direction facing grid will show. Then re-render it, and tell me whether the gun got closer to the shot, and how much more the figure leans.' One number, one prediction, one picture to check it against. If the lean reads worse than the aim error, put it back. Liam, in for Bear.

**B26 · OUTRO** · ~7s · 4 words · _ClaudeTitleOutro_

> *(card is silent apart from the stock jingle; sign-off recorded as: "Liam, in for Bear.")*

_Estimated total: 396 s (6.6 min) at 2.5 words/s, before measurement._
