# SOURCES.md — DERELICT

## Started from
Empty Godot 4 project (Godot 4.7.2, GDScript). Not an extension of Assignment 1 — different genre, clean start.

## Generative models used

| Model | Where run | License/terms (free tier) |
|---|---|---|
| Suno (music — attempted, not used) | suno.com, free plan | Personal, non-commercial use; attribution to Suno required. Acceptable for coursework; rejected here for an unrelated download-access reason (see log). |
| ElevenLabs Music (attempted, not used) | elevenlabs.io/music, free plan | Non-commercial use on free tier. Rejected here — WAV export gated behind a paid plan. |
| ElevenLabs Sound Effects (music loop + all 4 SFX) | elevenlabs.io/sound-effects, free plan | Non-commercial use; attribution required. Acceptable for coursework. |
| Gemini (all character art + environment art) | gemini.google.com, free account | Google does not claim ownership of generated output; commercial use is permitted on the free tier. Free-tier prompts/images may be used by Google for its own model training by default (opt-out available in account settings) — a data-privacy note, not a usage restriction. |

## Asset log

| Asset ID | Model | Prompt / settings | Outcome | Edits | Where used |
|---|---|---|---|---|---|
| char_reference (not a game asset) | Gemini | "Top-down 2D game sprite, lone scavenger character viewed directly from above, standing neutral pose, muted olive-gray gear, a flashlight mounted on one shoulder casting warm yellow light, holding a sidearm low and ready, simple clean silhouette, flat colors, no background, dark outline" | First attempt **rejected**: requested "transparent background," got a background drawn to look like a transparency checkerboard — not real alpha. Re-prompted for a solid green background instead; **accepted**. | Chroma-keyed green background to real alpha (`tools/chroma_key.py`, custom, no install). Rotated 180° on the assumption of a flat top-down view; later found the art has baked-in elevation. `godot/art/char_reference.png` is kept as originally keyed (rotated 180°); the in-game CHAR-IDLE, made from the same source image, was re-keyed without rotation once Option C (mirror + tilt facing) was adopted. | Reference only — compared against for every other pose (CHANGE-BRIEF failure case #1); not an in-game asset. |
| CHAR-IDLE | Gemini | Same reference image, used directly | Accepted | Chroma-keyed, scaled 0.12 (same factor as every pose, keeps relative zoom consistent), re-keyed without rotation | godot/art/char_idle.png |
| silhouette (design doc only) | Gemini | "now as a solid black silhouette, same pose" | Accepted | None beyond generation | CHARACTER-SHEET.md reference only, not an in-game asset |
| CHAR-AIM | Gemini | "now the same character, aiming a gun forward" | Accepted | Chroma-keyed, scaled 0.12, no rotation | godot/art/char_aim.png |
| CHAR-SHOOT-FOLLOWTHROUGH | Gemini | "now the same character, shoot follow-through" | Accepted | Chroma-keyed, scaled 0.12, no rotation | godot/art/char_shoot.png |
| CHAR-HURT | Gemini | "now the same character, hurt and flinching" | **Accepted despite being off-palette** (blue-grey, not the olive/tan from CONCEPT.md's palette) — kept as a documented color-consistency limitation, same as GRABBED | Chroma-keyed, scaled 0.12, no rotation | godot/art/char_hurt.png |
| CHAR-GRABBED-FAIL | Gemini | "now the same character, grabbed/fail" | **Accepted despite being off-palette** (blue-grey, like HURT) — kept as a documented color-consistency limitation rather than spending another generation cycle, given time constraints | Chroma-keyed, scaled 0.12, no rotation | godot/art/char_grabbed.png |
| CHAR-RECOVER | Gemini | "now the same character: getting back up from a crouch, re-gripping the gun, facing east (screen-right), same elevated angle and zoom as the aim pose, olive-and-tan palette matching the standing reference, flashlight on the same shoulder, no baked-in light beam or shadow" | Accepted | Chroma-keyed, scaled 0.12, no rotation | godot/art/char_recover.png |
| CHAR-CELEBRATE | Gemini | First attempt: "now the same character, celebrating" | First attempt **rejected**: came back with blood drops and a dropped weapon, contradicting a "safe success" read. Re-prompted: "...celebrating, arms raised, no blood, no dropped weapon..." **Accepted.** | Chroma-keyed, scaled 0.12, no rotation | godot/art/char_celebrate.png |
| CHAR-WALK | Gemini | "now the same character: walking, gun hand facing east (screen-right), same elevated angle and zoom as the aim pose, olive-and-tan palette matching the standing reference, flashlight on the same shoulder, no baked-in light beam or shadow" | Accepted | Chroma-keyed, scaled 0.12, no rotation | godot/art/char_walk.png |
| ENV-FACTORY-FLOOR | Gemini | "Top-down 2D game background, the floor of an abandoned derelict factory interior room, muted concrete gray with rust-orange stains, cracks, scattered debris and broken glass, flat colors, no characters" | Accepted | No background removal needed (the whole image is the floor, not a subject on a backdrop). Scaled 0.9375 and trimmed 20px per side to fit the 1280×720 room. | godot/art/env_factory_floor.png |
| MUS-LOOP | Suno (free, Simple mode, Instrumental) | "Sparse, tense ambient horror atmosphere, slow droning synth pads, distant metallic resonance, no strong melody, no percussion, built to loop quietly under exploration gameplay" | **Rejected** — got a usable track but could not download it. Suno changed its free-tier policy on Sept 3, 2026: accounts created on/after that date (this one) aren't guaranteed any trial downloads, unlike older accounts' automatic 7. Not a quality rejection. | — | Not used |
| MUS-LOOP | ElevenLabs Music (free) | Same prompt as above | **Rejected** — got a usable track, but WAV export (required by the assignment; MP3 is banned from the repo) was gated behind a paid plan even on free tier. | — | Not used |
| MUS-LOOP | ElevenLabs Sound Effects (free) | "Sparse, tense ambient horror drone, slow synth pad, distant metallic resonance, continuous atmospheric texture, no melody, no percussion, seamless loop"; duration 30s (max), Looping on | Accepted | Downloaded as WAV (free, no gate on this tool). Loop import setting in Godot set to Forward manually, since the file carries no loop marker of its own. | godot/audio/mus_loop.wav |
| SFX-SHOT | ElevenLabs Sound Effects (free) | "A single suppressed pistol shot, close-up, short and sharp, no echo"; ~2-3s, Looping off | Accepted (usable on first generation) | None — minor source clipping (~0.4% of samples) noted and left as-is | godot/audio/sfx_shot.wav |
| SFX-DOWN | ElevenLabs Sound Effects (free) | "A heavy body collapsing to a concrete floor, a final groan fading out"; ~2-3s, Looping off | Accepted (usable on first generation) | None — minor source clipping (~1.9% of samples) noted and left as-is | godot/audio/sfx_down.wav |
| SFX-HURT | ElevenLabs Sound Effects (free) | "A short pained human grunt, close-up, male voice"; ~2-3s, Looping off | Accepted (usable on first generation) | None — minor source clipping (~0.15% of samples) noted and left as-is | godot/audio/sfx_hurt.wav |
| SFX-CLEAR | ElevenLabs Sound Effects (free) | "A short two-note success chime, subtle, non-musical UI tone"; ~2-3s, Looping off | Accepted (usable on first generation) | None | godot/audio/sfx_clear.wav |

## Rejected outputs (thumbnails, not full-size — keep small per the assignment)
- Reference image, attempt 1: fake-transparent background (drawn checkerboard, not real alpha). Thumbnail: `design/character/rejected/reference-attempt1-fake-transparency.jpg`.
- CHAR-CELEBRATE, attempt 1: blood drops and a dropped weapon. Thumbnail: `design/character/rejected/celebrate-attempt1-blood-dropped-gun.jpg`.
- MUS-LOOP, Suno attempt: audio itself not rejected — the account's download access was the blocker.
- MUS-LOOP, ElevenLabs Music attempt: audio itself not rejected — WAV export was paywalled.

## Documented art/audio limitations (not fixed — see TEST-REPORT.md and CHANGE-BRIEF.md Revisions)
- CHAR-HURT and CHAR-GRABBED-FAIL kept in an off-palette blue-grey.
- CHAR-IDLE's baked-in flashlight beam points southwest while CHAR-AIM/CHAR-SHOOT-FOLLOWTHROUGH's implied light points east — inconsistent across states.
- CHAR-WALK/CHAR-RECOVER/CHAR-CELEBRATE were generated from a slightly different art angle and come out ~25% larger than the other five poses.
- The art's fixed-elevation perspective (not true top-down) means the sprite can't stay upright at every facing under free rotation; Option C (mirror + ±30° tilt, capped) was adopted so it's never upside-down, at the cost of the held weapon not always pointing exactly where the shot goes.
- Player readability against the final floor art, and the floor's visual detail (walls, machinery, doorway gaps) not matching the actual collision shapes — both cosmetic, collision behavior itself is correct.
