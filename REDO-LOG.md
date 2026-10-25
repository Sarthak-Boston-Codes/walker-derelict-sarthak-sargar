# REDO-LOG — Assignment 2 redo as a top-down 3D shooter

Branch `a2-redo-3d`, tagged `a2-redo`.

## Needs you (nothing is blocked)

1. **Better textured character models (optional).** Both `assets/3d/characters/player.glb` and `zombie.glb` have a real Hunyuan3D-2 shape but a texture I projected from your drawing, because the free GPU quota for texturing was used up both times. They read fine from the top-down camera, but the sides and back are stretched. To redo either one:
   - make a free Hugging Face read token (huggingface.co/settings/tokens), set it as `HF_TOKEN`, and re-run `tencent/Hunyuan3D-2` `/generation_all`; or
   - wait about 24 h for the anonymous quota to reset; or
   - use the TRELLIS / Hunyuan3D-2 Space in a browser.

   Save the result over the `.glb`. A side or 3/4 view works better as input than overhead art. The `yaw` in `model_table.gd` must turn the model to face −Z: the current player faces +Z (yaw 180), the current zombie faces +X (yaw 90). Inputs: `design/character/keyed/char_aim.png`, `design/zombie/keyed/zombie.png`.
2. **Play it and judge the feel.** I tested headless and with screenshots, so I've never heard the audio mix or aimed with a real mouse. Tuning knobs are all named constants at the top of `player.gd`, `zombie.gd`, `waves.gd`, `barrel.gd` and `camera_rig.gd`.
3. **`godot/scenes/showcase_3d.tscn` has your uncommitted editor change from before this session.** I never staged it; it's still sitting in your working tree.

## What was built

A top-down 3D zombie shooter that is now the project's main scene (`res://game3d/menu.tscn`). Everything is real 3D with real lights, and all of it lives in `godot/game3d/`. The 2D slice is untouched and still runs from `scenes/main.tscn`.

- **Level:** four connected derelict factory rooms built from primitives at runtime: Loading Bay, Assembly Hall, Boiler Room, Control Room. Conveyors, presses, shipping containers, boilers, consoles, hazard-striped doorways, procedural concrete floor. The A3 crate, barrel and medkit models are placed as interactive props.
- **Player:** WASD + mouse aim + hold-to-fire hitscan gun. Shadow-casting flashlight that follows the aim, muzzle-flash light, tracers. 15-round mag, R to reload, auto-reload on empty. Health with hurt knockback and a red vignette. Smooth camera follow with look-ahead and trauma-based screen shake.
- **Zombies:** shamblers (slow, tough) and runners (fast, fragile). They chase on the navmesh with avoidance, with a windup growl before the swipe, a white hit flash, stagger, and topple-and-sink deaths with blood decals. Endless waves trickle in from spawn points away from the player. Zombies sidestep when wedged on props.
- **Interactions:**
  - medkits heal 40
  - crates splinter after 2 shots and drop ammo
  - rusted barrels are physics bodies that bullets, the player and zombies knock over
  - red explosive barrels blow up after 2 shots, with line-of-sight blast damage, knockback, scorch decals and chain reactions
  - 30% of kills drop a few rounds
- **Flow:**
  - the main menu orbits the real level
  - pause menu with music/SFX toggles
  - HUD: health, ammo + reload bar, wave / infected left / kills, objective line, an objective marker with an edge arrow and distance, keycard indicator, toasts
  - death and win screens with stats and Restart
  - **win:** find the keycard in the Boiler Room → open the security door (which triggers an ambush) → hold the extraction lift for 4 s
- **Atmosphere:** dark ambient, volumetric fog, flickering and dying lamps, pulsing red emergency lights, dust motes lit by the flashlight, blood/spark/dust/explosion particles, glow, SSAO.
- **Audio:** reuses the generated SFX and music through the existing `Assets`/`Sound` autoloads, pitch-shifted for new events, with distance falloff. Music and SFX mutes stay separate; pause muffles the music.
- **Model swap table:** `game3d/model_table.gd`. One line per model; empty path = generated placeholder. The player and both zombie types now use image-to-3D models made from your art. The runner shares the zombie mesh with a red-brown tint and 0.9 scale.
- **Tests:** `tests/game3d_smoke_test.tscn` (27 checks covering every system end to end), `tests/game3d_soak_test.tscn` (a bot plays for 4 min), and `tests/game3d_shot.tscn` (windowed screenshot harness). Last results: smoke PASS; the soak bot reached wave 4 with 40 kills and no script errors; 137 FPS with 14 zombies in a window on the RTX 4050.

## Controls

| Key | Action |
|---|---|
| WASD | Move |
| Mouse | Aim (the flashlight follows) |
| Left click (hold) | Fire |
| R | Reload |
| F | Flashlight on/off |
| Esc | Pause |
| M / N | Mute music / mute SFX |

Run headless tests: `godot --headless --path godot res://tests/game3d_smoke_test.tscn` (exit code = failures).

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
37. **It's now the player model**, with a procedural footstep bob/sway because it has no rig. Back to the placeholder = set its path to `""` in `model_table.gd`. (Zombies: see 41.)
38. **Soak test with a bot** (`tests/game3d_soak_test.tscn`): it plays 4 minutes of game time at 2× speed. It aims at the nearest visible zombie and forages for crates/pickups on the navmesh between fights. It found two real bugs: (a) a zombie wedged behind a barrel stalled a wave forever, (b) ammo ran dry in wave 2.
39. **Fixes from the soak:** zombies push props hard enough to bulldoze barrels (7 per physics frame), and a chasing zombie that moves less than 0.4 m in 1.5 s sidesteps for 0.7 s and repaths. Balance: shambler 5 → 4 HP, 60 spare rounds at start (was 45), 30% chance a kill drops 5–9 rounds. Bot results after the fixes: waves 4, 4 and 8 (up to 115 kills) at 71–87% accuracy, no script errors.
40. **End screen shows accuracy** (zombie hits / shots fired).
41. **Zombie model from your Gemini art.** Gemini prompt: *"Full-body game character: an infected former lab test subject in torn grey scrubs, pale sickly green-grey skin, hunched shambling stance, arms reaching forward, three-quarter front view, simple clean shapes, flat colors, dark outline, on a solid flat bright green background"*. Original: `design/zombie/zombie_original.jpg`. Keyed: `design/zombie/keyed/zombie.png`.
42. **Keying:** `python tools/chroma_key.py design/zombie/zombie_original.jpg design/zombie/keyed/zombie.png --low 0.2 --high 0.8`. The defaults (0.10/0.97) left the green-grey skin and scrubs only about 88% opaque, because the tool reads green-ish pixels as partly background, and a few JPEG-noise pixels reached the image edges. With 0.2/0.8 the body is fully opaque and the bounds fit the figure. The despill step pulls the skin slightly toward grey.
43. **Generators tried, in order (all anonymous):**
    - `tencent/Hunyuan3D-2` `/generation_all` (textured): ZeroGPU quota exceeded (135 s needed, 127 s left, resets in ~23 h).
    - `trellis-community/TRELLIS` `/generate_and_extract_glb`: quota exceeded (120 s needed, 127 s left; it still refuses).
    - `tencent/Hunyuan3D-2mini-Turbo`: its API returns HTTP 500.
    - `stabilityai/stable-fast-3d` `/run_button`: generic error (almost certainly the same quota).

    I checked the HF API: every running free image-to-3D Space (Unique3D, InstantMesh, TripoSG, LGM, TRELLIS.2, Hi3DGen, Hunyuan3D-2.1/2mv…) is on ZeroGPU and shares that one quota. TripoSR and CRM are down. So I used **the same fallback as the player**: `tencent/Hunyuan3D-2` `/shape_generation` worked (about 10 s, 355k faces). I cleaned it locally: removed 140k zero-area faces, kept the main body (no floor sheet this time), decimated to 12k triangles, and textured it by projecting your drawing front-to-back. **The texture is my projection, not AI-generated.**
44. **Zombie model details:** `assets/3d/characters/zombie.glb`, 776 KB, 12k triangles (lighter than the player's 20k because up to 16 can be on screen), 1.8 m tall. Hunyuan read the 3/4 drawing as a side-on hunched figure facing +X, so the table uses yaw 90. I re-centred the pivot on the hips, not the bounding box, so the reaching arms don't push the collision capsule off the body.
45. **Telling the types apart:** both zombie types use `zombie.glb`. I added an optional `tint` field to the table; the runner gets `Color(1.0, 0.5, 0.42)` (feverish red-brown skin) and 0.9 scale. Combined with its speed it reads as a different creature from the grey shambler at a glance.
46. **Attack tell on a rigless mesh:** there are no arm pivots to swing, so the windup rears the body back and the strike lunges it forward. The growl still plays. Trade-off: the placeholder zombies had glowing red eyes, which made them visible outside the flashlight; these don't. They're darker in unlit areas now, which suits the horror but is a tuning call for you.
