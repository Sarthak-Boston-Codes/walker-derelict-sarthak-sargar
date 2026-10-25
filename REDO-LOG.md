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
10. **Hitscan bullets, aimed on a plane at 0.95 m.** The cursor is projected onto that plane so shots are level and hit zombies and barrels. If the cursor is over a zombie or prop, the shot aims at the actual 3D point under it instead, which lets you shoot low crates.
11. **Weapon numbers:** 15-round mag, 45 spare (cap 150), 0.14 s auto fire, 1.25 s reload, auto-reload on empty. R reloads, F toggles the flashlight (extra control, not in the brief).
12. **SFX reuse:** a 12-voice pool (`game3d/sfx.gd`) plays the existing `Assets` sounds on the SFX bus, pitch-shifted for new events (dry click, reload, flashlight). It isn't `Sound.play_sfx`, because that has one voice per sound and rapid fire would cut itself off. Music and the mutes stay with the `Sound` autoload.
13. **Camera:** fixed angle about 66° down, offset (0, 14.5, 6.5), exponential follow with a small look-ahead toward the aim, trauma-based shake (big on hits, tiny on each shot).
14. **Headless smoke test** `tests/game3d_smoke_test.tscn` drives the real game scene (fire, reload, damage, death) and is extended each step.
15. **Zombie stats:** shambler 5 HP, 1.9 m/s, 18 dmg, 0.5 s windup. Runner 2 HP, 4.4 m/s (player is 5.2), 9 dmg, 0.25 s windup. A hit staggers them and cancels a windup, so shooting a lunging zombie saves you.
16. **Chase:** NavigationAgent3D with avoidance. It repaths every ~0.3 s (jittered so a pack doesn't repath on the same frame) and steers straight at the player inside 3 m, because navmesh corners look robotic up close. Zombies rise out of the floor over 0.7 s with a dust puff, so they can't pop in on top of you.
17. **Waves:** wave N = 3 + 3N zombies, trickled in. Runners from wave 2 (15% per wave, cap 55%). Max 16 alive. They spawn 9–26 m from the player, in unlocked rooms only, with a 7 s breather between waves. Waves never stop; the win comes from extraction (step 5).
18. **Boilers shortened to 2.6 m**, because at 3.4 m they filled the screen from the top-down camera.
19. **Crates are shot open** (2 hits), not opened with a key. They splinter into short-lived debris and always drop an ammo box (12–20 rounds). They're static bodies on the prop layer, so they block movement but stay out of the navmesh.
20. **Barrels are RigidBody3D** (rusted 14 kg, explosive 25 kg, low centre of mass). Bullets, the player and zombies all apply impulses, so they slide and topple.
21. **Explosive barrel:** 2 hits. Blast radius 5 m with a line-of-sight check (walls block it). It deals 10 to zombies (kills any type), 10–55 to the player by distance, breaks crates, flings barrels, and chains into other explosive barrels after 0.18 s. A damaged barrel's hazard light stutters as a warning.
22. **Pickups stay put if useless** (medkit at full health, ammo at cap), so they're never wasted. Medkit heals 40.
23. **Bug found by screenshot:** `CPUParticles3D` defaults to `emitting = true`, so every burst fired at the world origin before being moved. Particles are now positioned before `add_child` and started after.
24. **Win condition:** keycard (on a desk in the far corner of the Boiler Room) → security door on the Boiler Room's west wall → stand on the freight lift for 4 s. Stepping off resets the countdown. Opening the door rebakes the navmesh, unlocks Control Room spawns, and triggers an 8-zombie ambush there, so the finale is a fight, not a walk.
25. **The door sinks into the floor** instead of sliding, so nothing has to clip into the walls.
26. **Pause/mute keys are read by the HUD** (`PROCESS_MODE_ALWAYS`), because a paused game root never sees Esc.
27. **Main menu renders the real level** under a slow orbit camera, so there's no separate art to keep in sync. Music/SFX toggles are on the menu, in pause, and on M/N everywhere.
28. **Music after death:** I use `Sound.fade_out_music()` and restart the track on restart/menu. That reaches into `Sound._music`, a private field of the shared autoload, because I didn't want to edit the 2D slice's audio director.
29. **Crosshair:** a generated ring-and-dot cursor in flashlight yellow while playing; the normal arrow in menus.
30. **No pipes over walkways.** From above, an overhead pipe hid the player completely.
31. **Light animation lives in one node** (`light_animator.gd`), not a script per light. Lamps tagged `flicker` stutter and black out at random, `dead` lamps sputter on for a frame or two, and emergency lights pulse red on staggered phases. Each bulb's emission dims with its light, so you can see which lamp is failing.
32. **Dust motes are shaded, not glowing**: 260 tiny world-space billboards around the player that only show where light hits them, so they sparkle in the flashlight cone. Fog is volumetric (set up in step 1), so the beam and the lamps get visible shafts.
33. **Audio mapping (all reused sounds, no new files):** SFX-SHOT = gunshot (also the dry click, reload clack, flashlight click and barrel ping at higher pitch, and part of the explosion at 0.35×). SFX-DOWN = zombie death (also the zombie windup growl at 0.5–0.7×, reload start, crate break, and the explosion boom at 0.45×). SFX-HURT = player hurt (also crate thunk and the locked-door buzz). SFX-CLEAR = wave cleared, pickups, keycard, door unlock, extraction. MUS-LOOP = music via the `Sound` autoload.
34. **Distance falloff without AudioStreamPlayer3D:** world events use `Sfx.play_at()`, which drops 0.55 dB per metre from the player and is silent past 32 m, so a growl in another room doesn't sound like it's next to you. Shared voices, no per-zombie players.
35. **Pause muffles the music** with a temporary low-pass on the Music bus, added at runtime. The 2D slice's `default_bus_layout.tres` is untouched. Music and SFX mutes stay separate (M / N, and buttons in the menu and pause screen).
36. **Image-to-3D:** `tencent/Hunyuan3D-2` (`/shape_generation`, anonymous) made the shape from `design/character/keyed/char_aim.png`. `char_idle` has a flashlight cone painted in, so I didn't use it. Every texturing endpoint (Hunyuan3D-2 `/generation_all`, 2.1, TRELLIS, stable-fast-3d, TripoSG) failed on the anonymous ZeroGPU quota. I cleaned and decimated the mesh locally (1.04M → 20k triangles, removed a floor sheet the generator added) and textured it by projecting the input image front-to-back. Result: `assets/3d/characters/player.glb`, 1.8 m, feet at the origin, facing +Z, so the table line uses yaw 180.
37. **It's now the player model**, with a procedural footstep bob/sway because it has no rig. Back to the placeholder = set its path to `""` in `model_table.gd`. Zombies stay placeholders; there's no zombie art to convert.
