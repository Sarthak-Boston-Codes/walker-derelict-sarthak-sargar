# FRICTIONAL.md — DERELICT

Dated log of the design thinking, filled in daily. A rejected attempt is just as valid an entry as an accepted one — log it either way, downloaded or not.

## 2026-10-07 — first music exploration (Suno)
- Wanted:
- Asked: (model/version, exact prompt, any settings)
- Got:
- Decided: rejected / edited / accepted, because
- Next:
- Human / Claude / model:
- Still unresolved:

(Copy this block for each new day's attempt — music, SFX, or art. One entry per real attempt, even a rejected one.)

## 2026-10-07 — ambient loop, Suno (rejected)
- Wanted: a sparse ambient loop (per CONCEPT.md).
- Asked: Suno (free, Instrumental) with the planned prompt.
- Got: a usable track, but couldn't download it — "out of downloads" on a brand-new account.
- Decided: rejected. Suno changed policy Sept 3 2026 — free accounts made on/after that date aren't guaranteed any trial downloads, unlike older accounts' automatic 7 lifetime trial downloads.
  Rejected Suno for this reason, not the music.
- Next: switched to ElevenLabs Music.
- Human / Claude / model: Human — the student's own decision, made directly from using Suno. Claude only organized these notes.
- Still unresolved: none.

## 2026-10-07 — ambient loop as WAV, ElevenLabs Music (rejected)
- Wanted: the same loop as WAV (assignment requires OGG/WAV, not MP3).
- Asked: ElevenLabs' Music tool, same account.
- Got: a fine track, but WAV download was paywalled on that specific tool even on free tier.
- Decided: rejected that tool for the gate, not the audio.
- Next: switched to ElevenLabs' Sound Effects tool instead (already working), using Looping-on and max duration to make the loop there instead. Downloaded free, no gate.
- Human / Claude / model: Human — the student's own decision, made directly from using ElevenLabs Music. Claude only organized these notes.
- Still unresolved: none.

## 2026-10-07 — four event sounds, ElevenLabs Sound Effects (accepted)
- Wanted: four short event sounds: a shot, a kill confirmation, a hurt grunt, a success chime.
- Asked: ElevenLabs Sound Effects, four prompts, 2–3s, looping off.
- Got: all four usable on the first generation.
- Decided: accepted all four as-is, judged by ear against what each event needed.
- Next:
- Human / Claude / model: Human — the student's own decision, made directly from using ElevenLabs Sound Effects. Claude only organized these notes.
- Still unresolved: none.

## 2026-10-07 — reference sprite, transparent background, Gemini (rejected, re-prompted)
- Wanted: a top-down reference sprite on a transparent background (CHARACTER-SHEET.md).
- Asked: Gemini, prompt explicitly requested transparent background.
- Got: an image that looked transparent but was actually a flat picture with a checkerboard pattern drawn into it — not real transparency.
- Decided: rejected for use as-is — this is the exact failure CHANGE-BRIEF predicted and the assignment itself warns about.
- Next: re-prompted for a solid green background instead, removed it after with a chroma-key script.
- Human / Claude / model: Human — the student's own decision, made directly from using Gemini. Claude only organized these notes.
- Still unresolved: none.

## 2026-10-07 — reference sprite orientation, Gemini (edited plan)
- Wanted: a strict top-down sprite, rotatable 180 for all four directions.
- Asked: Gemini for the reference character.
- Got: a slight elevated-angle view, not true top-down — rotating it 180 would look wrong, not just "facing away."
- Decided: first planned left/right mirroring, then kept free 360° rotation because aiming at any angle needs it. Once the real poses were in-engine, free rotation drew the figure upside-down facing north (the default), and an in-engine render at four facings showed a 180° offset would only swap which direction is upside-down — and that the gun was drawn 90° off the aim either way, because the poses hold the pistol to the side. Settled on: art stored upright facing east, mirrored by aim side and tilted toward the aim by at most ±30°. Aim/shots stay 360°; only the drawn angle is limited. Re-keyed the five poses without the 180° rotation.
- Next: generate the remaining poses (walk, recover, celebrate) facing east with the gun hand on the right, same angle/zoom/palette as aim and shoot, nothing baked in (no beam); regenerate idle, whose baked beam points behind the player.
- Human / Claude / model: Human — chose mirror + tilt (option C) from options Claude laid out after Claude ran the in-engine facing check; the earlier mirroring and free-rotation decisions were the student's own, made from using Gemini.
- Still unresolved: aiming straight up/down, the drawn gun is ~60° off the actual aim; mirroring swaps the flashlight's shoulder when facing left.

## 2026-10-15 — Medkit hand-edit in Blender (reverted)
- Wanted: to try moving and resizing an object by hand in Blender's viewport, without the MCP.
- Asked: Blender 5.2.2 LTS, `tools/blender/medkit.blend`. With Medkit selected in Object Mode: dragged it sideways, then pressed S to scale and confirmed with a left-click.
- Got (measured afterwards via the MCP):
  - Location: unchanged at (0, 0, 0). The sideways drag didn't move the object.
  - Scale: (1, 1, 1) → (1.95508, 1.95508, 1.95508), the same factor on all three axes.
  - Size: 0.3 × 0.2 × 0.15 m → 0.5865 × 0.3910 × 0.2933 m. Rotation stayed at 0, 0, 0.
  - The mesh itself was unchanged (still 0.3 × 0.2 × 0.15 m, 48 triangles). Only the object's Scale value changed, so the edit lived in the transform, not the geometry.
- Learned about the interface:
  - S scales all three axes together by default; restricting it to one axis needs an axis key (X/Y/Z) during the scale.
  - S scales around the object's origin. The medkit's origin is at the centre of its underside, so it grew upward and outward but stayed sitting on the floor.
  - Scaling with S changes the object's Scale field, not the mesh. If exported like that, it would arrive at the wrong size in Godot. That's predicted failure case #2 in CHANGE-BRIEF.md, and why scale is applied or reset before export.
  - Click-dragging with the default Select Box tool draws a selection box rather than moving the object; moving needs G or the Move tool. That's the likely reason location stayed at 0, 0, 0 (not confirmed).
- Decided: reverted. Scale reset to 1, 1, 1 directly (not applied, which would have baked the 1.955× into the mesh); location confirmed at 0, 0, 0. Re-exported `medkit.glb`, which came out byte-identical to the committed version, and `showcase_3d_test` still passes (exit 0, 0 failures).
- Next: none.
- Human / Claude / model: Human — the hand-edit itself was the student's. Claude measured the result, reverted it to the approved spec, re-exported and re-ran the check.
- Still unresolved: none.

## 2026-10-29 — Assignment 5: shaders and materials

Sources: the `a5` branch commits (`git log main..a5`), `A5-LOG.md` and Claude Code's own session. Authors: **student**, **Claude chat**, **Claude Code** (ran it), **model** (Godot's own generated output). Nothing here records the student's opinions or struggles; the student's section is at the end and is theirs to fill.

- **Wanted:** a state shown by a shader (low ammo), a textured material, the hint experiment, and Godot's generated shader for comparison. Spec in CHANGE-BRIEF.md. *Design decisions:* student, accepting Claude chat's defaults. *Spec text, shaders, predictions:* Claude chat.
- **Asked:** the student asked Claude Code to extract the kit and run `A5-RUNBOOK.md` end to end without questions.
- **Got / decided, in commit order:**
  - Brief references all checked correct. Three facts it missed were added as a revision: the label's drop shadow, the mag-0 colour, and the HUD never pausing. *Claude Code.*
  - CLAUDE.md first draft listed a screenshot harness as a test and cited a nonexistent brief section; corrected in a separate commit. *Claude Code.*
  - Driver and test passed at 30/60/144 fps on the first full run. Mutation (b) showed every timing rule still passing with a renamed uniform, which confirms failure case 4: only the uniform-list check caught it. *Claude Code.*
  - Kit's `normal_map_check` came out reversed (GL 1.30, DX 0.70) and weakly separated. The sign was flipped and the maps downsampled to 256 px (0.33 / 1.67), and the threshold set from that pair. *Claude Code, correcting Claude chat's file.*
  - Claude Code's own mistake: it committed the flipped file under the message "as copied". Caught before pushing and redone as two commits.
  - StandardMaterial3D's shader is not reachable through `get_shader_rid()` from GDScript; found by scanning RenderingServer RIDs instead. *Claude Code; the code itself: model (Godot).*
  - **First windowed capture showed the drop shadow turning red at full warning** (failure case 5). Brief revision first, then the fix (skip pure-black pixels); recapture confirmed. *Shader: Claude chat; bug found and fixed by Claude Code; also seen by the student.*
  - Claude Code's capture script hung on its first play run (a reload press timed after `frame_post_draw` was never "just pressed"); fixed.
  - Hint experiment measured exactly as predicted; `hint_range` confirmed not to clamp (2.0 → (255, 0, 18)).
- **Next:** the student's own checks (HUMAN-CHECK-NOTES.md), and the film upload.
- **Still unresolved:** the default `uv_scale` makes the concrete read as near-uniform grey from the game camera; R7 cannot be reached by real input.

### Student's own notes


