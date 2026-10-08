# COMPONENTS — DERELICT (game code f88f58d)

Every file in `godot/` is assigned here or excluded in `gamedev-evidence.json` (46 files, 8 components, 9 exclusions; `verify_gamedev.py` PASS). Line numbers refer to f88f58d.

## architecture — B02, B03
- **Where:** `project.godot` (window 1280×720, input map, autoloads `Assets` and `Sound`), `scenes/main.tscn`, `scenes/main.gd`.
- **Data in:** project settings at startup.
- **What changes:** `main.gd` sets the floor texture from the asset table and connects `Player.state_changed` to the HUD.
- **Player sees:** one room; the HUD state readout.
- **Why / trade-off:** a single scene keeps the slice inspectable. The trade-off is no level structure: there's nothing to extend into a second room without new scene plumbing.
- **Saved vs runtime:** the saved tree (B03) does not contain the `AudioStreamPlayer`s that `Sound` creates in code (`audio_director.gd` 20–34), or the autoload nodes themselves. B03 labels the tree "saved, local".

## asset_table — B04, B05
- **Where:** `assets/asset_manifest.gd` (ART 10–22, AUDIO 24–31, `texture()` 37–42, `stream()` 45–50), `assets/placeholder_factory.gd`, the art PNGs and their `.import` files.
- **Data in:** an asset ID string.
- **What changes:** `""` → `PlaceholderFactory.make_texture/stream(id)` (runtime shapes and tones); a `res://` path → `load(path)`, cached.
- **Player sees:** placeholder circles and grid, or the generated art (B05, same frame).
- **Why / trade-off:** every swap is one line. The trade-off is that the table can't express per-asset metadata (scale, pivot, facing): real art had to be pre-sized by `tools/chroma_key.py --scale 0.12` to fit.

## player_states — B06–B09
- **Where:** `scenes/player.gd`, `scenes/player.tscn`.
- **Data in:** input actions (move, aim, fire), `take_hit(from)` from the zombie, `celebrate()` from the exit.
- **Important lines:**
  - aim branch 72–81 (wind-up gate at 80);
  - single-press fire 59–63, with no buffering (110);
  - ready cue 112;
  - hit chain 92–105;
  - `take_hit` 117–125;
  - `_enter` 166–172 (one art ID per state).
- **Player sees:** the 8 art states, the tracer, the ready cue, the threat arrow, half-alpha during the post-hit window.
- **Why / trade-off:** the wind-up makes shooting deliberate (CONCEPT pillar 2). The trade-off is that a click during wind-up is dropped silently; the ready cue is the mitigation.

## zombie — B10, B11 (+ B12 listening beat)
- **Where:** `scenes/zombie.gd`, `scenes/zombie.tscn`.
- **Data in:** player position; `take_shot()` from the player's raycast.
- **Important lines:**
  - chase within `detect_radius` 220 at 55 px/s (44–49);
  - polled touch → `take_hit` → knockback 80 px (53–55);
  - flash 0.15 s, then `_go_down` (59–76), which holds the only `SFX-DOWN` call.
- **Player sees:** chase, grab, flash, then the downed body under the player.
- **Trade-off:** the knockback happens at grab time, so a player who stands still is re-grabbed after the ~2.8 s chain (CHANGE-BRIEF Revisions; not rebuilt).

## audio_and_mutes — B13, B14 (+ B12)
- **Where:** `audio/audio_director.gd`, `default_bus_layout.tres`, `ui/hud.gd`, `ui/hud.tscn`, the five WAVs and their imports.
- **Data in:** `play_sfx(id)` calls; the M/N actions.
- **Important lines:**
  - SFX player per ID, plus counts (20–34, 44–48);
  - fade 51–56;
  - bus mute 70–80.
- **Player sees and hears:** the four SFX, the looping music, both mutes, the HUD counts.
- **Observed behaviour (RUN_C):** bus mute does not stop playback. Unmuting during a sound reveals its remaining tail.
- **Import detail:** `mus_loop.wav.import` sets `edit/loop_mode=2` (Forward); the WAV has no loop chunk.

## facing — B15, B16
- **Where:** `scenes/facing.gd` 11–18, called from `player.gd` 161–163 and `zombie.gd` 48.
- **Data in:** a facing vector.
- **What changes:** `flip_h` by aim side; rotation clamped to ±`max_tilt_deg` (30°); straight up/down keeps the current side.
- **Player sees:** upright poses at every aim (B16).
- **Why / trade-off:** the fixed-elevation art can't be rotated freely (B16 left, commit 7fc6a99). The trade-off: straight up/down, the drawn gun is ~60° off the shot, and mirroring swaps the flashlight's shoulder.

## celebrate_trace — B17–B21
- **Where:** `scenes/exit_marker.gd` 17–26, `scenes/exit_marker.tscn`, `art/char_celebrate.png` (+ import), asset table line 18.
- **Outside `godot/`:**
  - `tools/chroma_key.py` 25–38;
  - `design/character/keyed/char_celebrate.png`;
  - `design/character/rejected/celebrate-attempt1-blood-dropped-gun.jpg`;
  - SOURCES.md line 27.
- **What changes:** first player entry → `_cleared`, `celebrate()`, `SFX-CLEAR`, a 1.5 s music fade.
- **Player sees:** the CELEBRATE pose at the exit, the chime, the music fading out.

## trigger_test — B22, B23
- **Where:** `tests/trigger_count_test.gd`, `tests/trigger_count_test.tscn`.
- **Data in:** the real main scene, scripted input, fixed tick counts.
- **Proves:** all 16 IDs load; one SFX per event under held and repeated input. B23 shows it fails 4/5 when the guards are removed.
- **Cannot prove:**
  - audibility (it counts `play_sfx` calls; audio is muted during the run);
  - real play (it teleports the player in `_hurt_pinned` 87 and the exit scenario).
