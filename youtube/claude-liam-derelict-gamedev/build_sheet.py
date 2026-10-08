"""Builds beat_sheet.json + gamedev-evidence.json for the DERELICT gamedev film.

Code excerpts are read from the game files by line range, so the displayed
code is verbatim by construction. Rerun after any game or media change; the
checker (verify_gamedev.py) fails on stale hashes or line drift.

  python build_sheet.py
"""
import hashlib, json
from pathlib import Path

FILM = Path(__file__).resolve().parent
REPO = FILM.parents[1]
GAME = REPO / "godot"
SLUG = "claude-liam-derelict-gamedev"
TITLE = "DERELICT: Wiring Generated Art Into Godot"
WPS = 2.5  # narration words/second, for estimates only (step 3 measures)


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def lines(path, a, b):
    src = (GAME / path).read_text(encoding="utf-8").splitlines()
    return "\n".join(src[a - 1:b])


def est(text, minimum=4.0):
    return round(max(minimum, len(text.split()) / WPS + 0.6), 1)


beats, excerpts, pairs = [], [], []

# Measurements written by generate_audio_kokoro.py survive a rebuild only while
# the beat's narration text is unchanged; edited narration must be re-voiced.
_old = FILM / "beat_sheet.json"
MEASURED = {b["beat_id"]: b for b in json.loads(_old.read_text(encoding="utf-8"))["beats"]} if _old.exists() else {}


def measured(bid, narration):
    o = MEASURED.get(bid)
    if o and o.get("narration_text") == narration and o.get("audio_file"):
        keep = {"audio_file": o["audio_file"], "actual_duration_s": o["actual_duration_s"]}
        for k in ("lead_silence_baked", "tts_speed", "narration_padded_to", "narration_voiced_s"):  # baked-in audio facts travel with the file
            if k in o:
                keep[k] = o[k]
        return keep
    return {}


def anchored_cues(narration, duration, cues):
    """Kokoro gives no word timestamps: place each highlight at its anchor
    phrase's character offset in the narration, scaled to the beat duration."""
    out = []
    for line, label, anchor in cues:
        i = narration.find(anchor)
        assert i >= 0, f"cue anchor not in narration: {anchor!r}"
        out.append({"at": round(duration * i / len(narration), 1), "line": line, "label": label})
    return sorted(out, key=lambda c: c["at"])


def beat(bid, act, narration, shot, **extra):
    b = {"beat_id": bid, "act": act, "narration_text": narration, "voice": "am_onyx", "engine": "kokoro",
         "estimated_duration_s": extra.pop("estimated_duration_s", est(narration) if narration else 4.0),
         "shot": shot}
    b.update(extra)
    b.update(measured(bid, narration))
    beats.append(b)
    return b


def code_beat(bid, narration, path, a, b, title, cue_anchors, notes, result):
    code = lines(path, a, b)
    excerpts.append({"beat_id": bid, "path": path, "start_line": a, "end_line": b, "text": code})
    dur = measured(bid, narration).get("actual_duration_s") or est(narration)
    cues = anchored_cues(narration, dur, cue_anchors)
    beat(bid, "MECHANISM", narration, {
        "type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "line-highlight",
        "remotion": {"pattern": "GodotDevWorkbench", "props": {
            "mode": "code", "title": title, "project": "walker-derelict-sarthak-sargar",
            "path": path, "source": f"godot/{path} lines {a}-{b} · Godot editor reconstruction",
            "code": code, "startLine": a, "cues": cues,
            "inspectorLabel": "Source notes — not Inspector values", "notes": notes,
            "output": [f"{path} · code → visible result", "Godot editor reconstruction"],
            "durationSeconds": dur}}},
         cue_timing="highlights placed by anchor-phrase character offset × measured duration (no TTS word timestamps)")
    pairs.append({"code_beat": bid, "result_beat": result})


def result_beat(bid, narration, media, observation, motion="footage", hold_note=None):
    shot = {"type": "FOOTAGE" if media.endswith(".mp4") else "STILL", "source": "own",
            "treatment": "none", "evidence_media": media,
            "motion": "hold" if media.endswith(".png") else motion,
            "label": "Godot 4.7.2 Movie Maker capture · input-only route" if media.endswith(".mp4")
                     else "engine render"}
    if hold_note:
        shot["hold_policy"] = hold_note
    extra = {}
    if media.endswith(".mp4"):
        # final_frame_check per-beat declarations for gameplay capture.
        extra["qc"] = {
            "full_bleed": True,
            "contrast_regions": [{"label": "HUD readout", "box": [0.012, 0.035, 0.30, 0.195]}],
            "contrast_reason": "Full-frame gameplay capture: the dark game floor is the picture, not a text "
                               "background. The essential on-screen text is the HUD readout, measured in its "
                               "box; conform_clips.py darkens non-text pixels behind it to 30% (disclosed). "
                               "Player-sprite readability on the floor is a documented limitation (TEST-REPORT)."}
    beat(bid, "RESULT", narration, shot, **extra)
    for p in pairs:
        if p["result_beat"] == bid:
            p["observation"] = observation
            p["media"] = {"path": media, "sha256": sha(FILM / media)}


HOLD = ("action plays at capture speed; if measured narration is longer, a frame hold "
        "labelled HOLD is appended after the action (never slowed). Built in step 4.")

# --- bookends -------------------------------------------------------------------
beat("B00", "ASK",
     "Jambo — this is Liam, in for Bear. A student built DERELICT: a top-down Godot game where a "
     "scavenger clears one derelict factory room, with its art and sound made by generative models, "
     "all but the zombie. So I asked Claude to take the game apart and show how those assets actually got in.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on",
      "remotion": {"pattern": "ClaudeComposerAsk", "props": {
          "greeting": "Jambo, Liam", "topic": "GODOT · GAME TEARDOWN", "segment": "DERELICT",
          "command": "Please use Walker to convert my game design document about DERELICT — a lone "
                     "scavenger clearing a derelict factory, one infected, one exit — into a Godot 4 "
                     "slice that proves generated art, sound and music working together.",
          "runningText": "reading CONCEPT.md, STORYBOARD.md, CHANGE-BRIEF.md…",
          "folderLabel": "@NikBearBrown", "modelLabel": "Claude", "effortLabel": "High",
          "output": ["Eight player states, one infected, one exit.",
                     "Every asset routed through one table.",
                     "A test that counts every sound."]}}},
     role_note="COLD OPEN — reconstructed Walker prompt (labelled in FACTCHECK.md), not a recording.")

beat("B01", "BLUF",
     "Generated art gets wired in, not dropped in. One table, one line each, and a test for every sound. "
     "That wiring is what this film takes apart.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on-correct",
      "remotion": {"pattern": "BrutalistHesitantWriter", "props": {
          # The component matches single whitespace tokens only (comma-separated list),
          # so the misconception is carried by one word: dropped -> wired.
          "text": "Generated art gets dropped in.\nOne table, one line each,\na test for every sound.",
          "triggerWords": "dropped", "replacementWords": "wired",
          # contextTitle/brandLabel frame the typed lines so the beat isn't mostly
          # empty page (final_frame_check underfill: content bbox >= 55% of safe area).
          "contextTitle": "DERELICT", "brandLabel": "@NikBearBrown",
          "fontSize": 110, "lineSpacing": 1.5, "align": "center", "seed": "derelict-gamedev",
          "mistakeRate": 2, "hesitateWithin": 0, "hesitateBetween": 1,
          "ink": "#3D3929", "accent": "#D97757", "bg": "#FAF9F5"}}},
     lead_silence_s=0.8, estimated_duration_s=12.0,
     role_note="Misconception corrected: art gets 'dropped' in -> 'wired' in. Audio window >= 9 s.")

beat("B02", "SETUP",
     "The assignment: a player in at least two art states, one environment, four sound events on real "
     "triggers, one looping track, and a mute that leaves the game readable. It started from an empty "
     "Godot four point seven point two project. Everything you see comes from one commit, shown on screen.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "tree-reveal",
      "remotion": {"pattern": "GodotDevWorkbench", "props": {
          "mode": "tree", "title": "What the assignment asked for.", "project": "walker-derelict-sarthak-sargar",
          "source": "SUBMISSION.md · CHANGE-BRIEF.md asset list · game code f88f58d",
          "treeLabel": "Requirement → asset IDs",
          "tree": ["Player, ≥ 2 art states → CHAR-IDLE … CHAR-CELEBRATE (8)",
                   "One environment → ENV-FACTORY-FLOOR",
                   "Four sound events → SFX-SHOT · SFX-DOWN · SFX-HURT · SFX-CLEAR",
                   "One looping track → MUS-LOOP",
                   "Mute, still readable → Music (M) · SFX (N)"],
          "notes": [{"label": "Started from", "value": "empty Godot 4.7.2 project"},
                    {"label": "Game code shown", "value": "f88f58d"}],
          "durationSeconds": 16}}})

beat("B03", "ANATOMY",
     "One main scene: a floor sprite, four wall colliders, the zombie, the player, the exit marker, a "
     "fixed camera and the HUD. Above it sit two autoloads. Assets resolves every asset ID. Sound owns "
     "the music, the effects, and both mutes.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "tree-reveal",
      "remotion": {"pattern": "GodotDevWorkbench", "props": {
          "mode": "tree", "title": "The whole game, one scene.", "project": "walker-derelict-sarthak-sargar",
          "path": "scenes/main.tscn", "source": "godot/scenes/main.tscn · godot/project.godot [autoload]",
          "treeLabel": "Scene (saved, local)",
          "tree": ["Main (Node2D) — main.gd", "  Floor (Sprite2D)", "  Walls (StaticBody2D) ×4 colliders",
                   "  ExitMarker — exit_marker.tscn", "  Zombie — zombie.tscn", "  Player — player.tscn",
                   "  Camera2D", "  HUD — hud.tscn",
                   "Autoload Assets — assets/asset_manifest.gd",
                   "Autoload Sound — audio/audio_director.gd"],
          "notes": [{"label": "Draw order", "value": "Zombie before Player: the body draws under the player"},
                    {"label": "Physics layers", "value": "1 walls · 2 player · 3 zombie"}],
          "durationSeconds": 16}}})

# --- assets ---------------------------------------------------------------------------
code_beat("B04",
          "Here's the heart of it. Every art ID from the change brief has one line in this table. An empty "
          "string means the game draws a generated placeholder at runtime; a real file path loads the file. "
          "Each swap was one line. The zombie's two lines are still empty.",
          "assets/asset_manifest.gd", 10, 22, "One table resolves every asset.",
          [(11, "one line per asset ID", "one line in this table"),
           (18, "CHAR-CELEBRATE → real PNG", "a real file path loads"),
           (19, "ZOMBIE-* still \"\" → placeholder", "The zombie's two lines")],
          [{"label": "texture(id), line 41", "value": "\"\" → PlaceholderFactory\n.make_texture(id)\nelse load(path)"},
           {"label": "Audio", "value": "same pattern: AUDIO table, stream(id)"}],
          "B05")
result_beat("B05",
            "Same frame, same code. Left: an isolated copy with every art path blanked — circles and a grid. "
            "Right: the real build.",
            "media/B05.png",
            "Blanking the ART paths in an isolated copy turns every sprite and the floor into runtime "
            "placeholders; nothing else differs.")

# --- player -----------------------------------------------------------------------------
code_beat("B06",
          "The shot is deliberate. Holding aim enters AIM, and a click only fires once that state has lasted "
          "a quarter of a second, the wind-up. A faint ready cue shows exactly when a click would work.",
          "scenes/player.gd", 72, 81, "Aim, wind-up, fire.",
          [(74, "aim held → enter AIM", "Holding aim enters AIM"),
           (80, "fire only after aim_windup (0.25 s)", "a click only fires")],
          [{"label": "aim_windup", "value": "0.25 s (@export, line 31)"},
           {"label": "Ready cue, line 112", "value": "visible while AIM and _state_time ≥ aim_windup"},
           {"label": "Fire input", "value": "one press event per click (_unhandled_input)"}],
          "B07")
result_beat("B07", "Aim. The cue appears. Click: follow-through, and the tracer stops on the zombie.",
            "media/B07.mp4", "AIM, ready cue, one shot, SHOOT-FOLLOWTHROUGH; HUD SHOT 0 → 1.", hold_note=HOLD)

code_beat("B08",
          "A grab is guarded. Take-hit refuses while the player is hurt, grabbed, recovering or celebrating, "
          "and for one second after. Only a landed hit plays the hurt sound, and the arrow points back at "
          "the attacker.",
          "scenes/player.gd", 117, 125, "One hit, one sound.",
          [(119, "invulnerable or mid-chain → refuse", "Take-hit refuses"),
           (124, "SFX-HURT only on a landed hit", "Only a landed hit"),
           (123, "arrow faces the attacker", "the arrow points back")],
          [{"label": "Chain", "value": "HURT 0.3 s → GRABBED 1.0 s → RECOVER 0.5 s\n→ 1.0 s post-hit window"},
           {"label": "Zombie side", "value": "landed hit → shoved back 80 px"}],
          "B09")
result_beat("B09", "Contact. Hurt, arrow on the zombie. Grabbed, no control. Recover, and walk away.",
            "media/B09.mp4", "HURT with arrow toward the zombie, GRABBED-FAIL, RECOVER, walk away; HUD HURT 0 → 1.",
            hold_note=HOLD)

# --- zombie --------------------------------------------------------------------------------
code_beat("B10",
          "The zombie can't vanish on impact. take-shot flashes it for a hundred and fifty milliseconds, then "
          "go-down runs, the only place the down sound is played, so it fires exactly once.",
          "scenes/zombie.gd", 63, 76, "Visible hit, then down.",
          [(63, "flash", "flashes it"),
           (64, "wait hit_flash_time (0.15 s)", "a hundred and fifty milliseconds"),
           (66, "then _go_down()", "then go-down runs"),
           (75, "SFX-DOWN: the one alive → down change", "the only place the down sound")],
          [{"label": "Guard, line 60", "value": "already DOWN or hit\n→ take_shot ignored"},
           {"label": "After DOWN", "value": "collision_layer 0: shots and player pass over"}],
          "B11")
result_beat("B11", "The flash, then the body. Now listen.",
            "media/B11.mp4", "Hit flash, then ZOMBIE-DOWN; HUD DOWN 0 → 1.", hold_note=HOLD)

beat("B12", "LISTEN", "",
     {"type": "FOOTAGE", "source": "own", "treatment": "none", "evidence_media": "media/B12.mp4",
      "label": "Game audio only · no narration · Movie Maker capture RUN_A 2.0–6.0 s",
      "note": "SFX-SHOT, SFX-DOWN collapse, MUS-LOOP bed as the engine mixed them."},
     clock="source", audio_policy="preserve", estimated_duration_s=4.0,
     role_note="AUDIBLE-AUDIO BEAT. clock:source + audio_policy:preserve is compile.py's only path that "
               "keeps a clip's own audio (verified by the audio experiment); not labelled SOURCE_REPORT.")

# --- audio ------------------------------------------------------------------------------------
code_beat("B13",
          "Music and effects live on separate buses, and M and N each flip one bus's mute. Muting silences "
          "a bus without stopping what's playing on it, so a sound muted halfway can come back as a tail. "
          "The capture waits out the collapse before unmuting.",
          "audio/audio_director.gd", 70, 80, "Two buses, two mutes.",
          [(80, "M / N toggle one bus each", "M and N each flip"),
           (71, "mute = AudioServer bus mute", "Muting silences a bus")],
          [{"label": "Buses", "value": "Music, SFX → Master\n(default_bus_layout\n.tres)"},
           {"label": "Keys", "value": "hud.gd: toggle_music (M), toggle_sfx (N)"}],
          "B14")
result_beat("B14",
            "M: music off. N: effects off. A silent kill still reads. The sound comes back, and a shot you "
            "can hear.",
            "media/B14.mp4",
            "Music bus muted at M, SFX bus at N; silent kill with HUD SHOT/DOWN 1; unmute; audible shot.",
            hold_note=HOLD)

# --- facing ---------------------------------------------------------------------------------------
code_beat("B15",
          "The generated art is drawn from a fixed, elevated angle, so spinning it freely turned it "
          "upside-down. Facing mirrors the sprite to the side you aim at, then tilts it at most thirty "
          "degrees. The shot itself still goes anywhere.",
          "scenes/facing.gd", 11, 18, "Mirror, then tilt.",
          [(16, "mirror by aim side", "mirrors the sprite"),
           (18, "tilt clamped to ±max_tilt (30°)", "tilts it at most thirty degrees")],
          [{"label": "Convention", "value": "art stored upright, facing east"},
           {"label": "Used by", "value": "player.gd _face(), zombie.gd chase"}],
          "B16")
result_beat("B16",
            "Left, the first build rotating freely: upside-down facing north, the gun ninety degrees off. "
            "Right, mirror and tilt: upright everywhere. Straight up or down, the gun is still sixty degrees "
            "off the shot. That trade is on the record.",
            "media/B16.png",
            "Free rotation (7fc6a99) draws poses upside-down and the gun 90° off; mirror+tilt keeps every "
            "pose upright, gun within 30° except straight up/down.")

# --- CELEBRATE trace -----------------------------------------------------------------------------------
beat("B17", "TRACE",
     "One asset, end to end. Storyboard panel seven and pose ten asked for a calm success beat. Per the "
     "asset log, the first prompt came back with blood and a dropped gun, and was rejected. The correction "
     "asked for arms raised, no blood, no dropped weapon, on solid green.",
     {"type": "STILL", "source": "own", "treatment": "none", "motion": "hold", "media": "media/B17.png",
      "label": "trace board: real images only (make_trace_cards.py)"},
     role_note="Storyboard panel 7 + sheet pose 10 (SVG sheets rasterised by headless Chrome), rejected "
               "thumbnail, accepted raw output; prompts quoted from SOURCES.md line 27.")

beat("B18", "MECHANISM",
     "The green comes off with a short script. Alpha is how green a pixel is compared with the background "
     "sampled from the border. Then the key colour's share is subtracted, so the edges don't glow green.",
     {"type": "STILL", "source": "own", "treatment": "none", "motion": "hold", "media": "media/B18.png",
      "label": "code card: tools/chroma_key.py lines 25-38, verbatim, numbered 25-38",
      "code_sha256": hashlib.sha256("\n".join((REPO / "tools/chroma_key.py").read_text(encoding="utf-8")
                                               .splitlines()[24:38]).encode()).hexdigest()},
     role_note="Not GodotDevWorkbench (file is outside godot/, and its header says Godot) and not "
               "GitHubCodeViewer (numbers lines from 1). Card built by make_trace_cards.py.")
beat("B19", "RESULT",
     "Raw output, keyed to real alpha, then scaled by the same factor as every other pose, to a "
     "hundred-sixty-nine by ninety-two pixel sprite.",
     {"type": "STILL", "source": "own", "treatment": "none", "motion": "hold", "evidence_media": "media/B19.png",
      "label": "actual files: raw JPG, keyed master, game PNG"})

code_beat("B20",
          "It reaches the screen through one asset-table line and the exit marker. The first player entry sets "
          "a flag, calls celebrate, plays the clear chime and fades the music. The flag, not the trigger, "
          "stops a second chime.",
          "scenes/exit_marker.gd", 17, 26, "Reaching the exit.",
          [(20, "the flag is the guard", "sets a flag"),
           (23, "CHAR-CELEBRATE", "calls celebrate"),
           (24, "SFX-CLEAR", "plays the clear chime"),
           (25, "music fades over 1.5 s", "fades the music")],
          [{"label": "Asset table, line 18", "value": "\"CHAR-CELEBRATE\":\n\"res://art/\nchar_celebrate.png\""},
           {"label": "music_fade_time", "value": "1.5 s (@export, line 8)"}],
          "B21")
result_beat("B21", "The walk to the exit. Celebrate. The chime, and the music fading to nothing.",
            "media/B21.mp4", "WALK to exit, CHAR-CELEBRATE, HUD CLEAR 0 → 1, MUS-LOOP fades to silence.",
            hold_note=HOLD)

# --- tests ------------------------------------------------------------------------------------------------
code_beat("B22",
          "The test that guards all of this runs the real scene for a fixed number of physics ticks. This "
          "scenario pins the player on the zombie through the whole hit chain and expects exactly one hurt sound.",
          "tests/trigger_count_test.gd", 80, 89, "Counting triggers.",
          [(87, "test-only: player pinned on the zombie", "pins the player"),
           (84, "chain length from the player's own exports", "the whole hit chain"),
           (89, "expect exactly 1", "expects exactly one")],
          [{"label": "Command", "value": "godot --headless\n--path godot\nres://tests/\ntrigger_count_test.tscn"},
           {"label": "Also checks", "value": "all 16 asset IDs load"}],
          "B23")
result_beat("B23",
            "It passes. On a copy with the four guards removed, it fails four times: one shot became four, one "
            "hurt became a hundred and thirty-five. What it can't tell you is whether anything is audible. It "
            "counts calls, and it teleports. That's why the listening beat exists.",
            "media/B23.png",
            "Recorded runs on isolated copies: PASS (exit 0); guards removed → 4 FAIL (exit 4).")

# --- verdict / your turn / outro ------------------------------------------------------------------------------
beat("B24", "VERDICT",
     "Implemented: eight states, one infected, a real floor, four sounds and a loop, separate mutes, and a test "
     "that fails when its guards are removed. Limits: the olive scavenger fades into the floor, the poses drift in palette and angle, the "
     "zombie is still a placeholder, and the flashlight darkness was cut. Human judgment: the student played it "
     "with sound on and muted, and confirmed the loop and the fade by ear.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "artifact-reveal",
      "remotion": {"pattern": "ClaudeVerdictArtifact", "props": {
          "artifactTitle": "Verdict", "artifactHeading": "DERELICT, taken apart.", "brandLabel": "@NikBearBrown",
          "artifactLines": ["Implemented: 8 states, 1 infected, floor, 4 SFX + loop, 2 mutes, a trigger-count test.",
                            "Limits: readability on the floor, pose drift, zombie placeholder, no darkness.",
                            "Trade-off: gun up to 60° off the shot when aiming straight up/down.",
                            "Human judgment: author playtest, sound on and muted; loop + fade by ear."]}}})

beat("B25", "HANDOFF",
     "Your turn. Paste this: 'Use Walker on my DERELICT project. In the player script, change max tilt degrees "
     "from thirty to forty-five. Before running anything, predict what the eight-direction facing grid will show. Then "
     "re-render it, and tell me whether the gun got closer to the shot, and how much more the figure leans.' "
     "One number, one prediction, one picture to check it against. If the lean reads worse than the aim error, "
     "put it back. Liam, in for Bear.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on",
      "remotion": {"pattern": "ClaudeComposerAsk", "props": {
          "greeting": "Your turn.", "topic": "GODOT · GAME TEARDOWN", "segment": "DERELICT",
          "command": "Use Walker on my DERELICT project. In godot/scenes/player.gd, change max_tilt_deg from 30 "
                     "to 45. Before running anything, predict what the 8-direction facing grid will show. Then "
                     "re-render it and tell me whether the gun got closer to the shot, and how much more the "
                     "figure leans.",
          "runningText": "paste this into Claude…", "folderLabel": "@NikBearBrown", "modelLabel": "Claude",
          "effortLabel": "High", "output": ["One number.", "One prediction.", "One picture to check it."],
          "animateTyping": True}}})

beat("B26", "OUTRO", "Liam, in for Bear.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "mascot-title",
      "remotion": {"pattern": "ClaudeTitleOutro", "props": {"title": TITLE, "slug": SLUG}}},
     audio_policy="silence", estimated_duration_s=7.0,
     role_note="Locked outro: @NikBearBrown, slug-seeded mascot, stock jingle only; no narration or game audio.")

sheet = {"metadata": {
    "title": TITLE, "slug": SLUG, "topic": "GODOT · GAME TEARDOWN", "kind": "gamedev", "mode": "walker",
    "brand": "claude-liam", "register": "Teardown", "engine": "kokoro", "voice": "am_onyx", "voice_kokoro": "am_onyx",
    "palette": "claude", "style_preset": "claude", "ground": "#FAF9F5", "aspect_ratio": "16:9",
    # compile.py's vf_fit knows only "pad" (letterbox) or else crop-to-fill; wide stills
    # (B05, B16, B19, B23) would lose most of their content under crop.
    "fit": "pad",
    "captions": False, "greeting": "Jambo, Liam",
    "greeting_note": "hello lexicon: Jambo (Swahili); previous reel used Bula. Liam never takes Wagwan.",
    "persona": "Liam (in for Bear)", "presenter": "Liam (in for Bear)", "in_for_bear": True,
    "game": "walker-derelict-sarthak-sargar", "game_code_revision": "f88f58d",
    "note": "godot-gamedev walker film. Footage: Movie Maker captures in captures/ (MEDIA-LEDGER.json). "
            "No game change, paid call, upload or publication."},
    "beats": beats}

files = {}
def assign(component, *paths):
    for p in paths:
        files.setdefault(p, []).append(component)

COMPONENTS = [
    ("architecture", "Main scene tree, autoloads and project configuration: what exists at startup and how it is wired.",
     ["B02", "B03"], ["project.godot", "scenes/main.tscn", "scenes/main.gd"]),
    ("asset_table", "One manifest resolves every art/audio ID to a real file or a runtime-generated placeholder; "
     "the swap is one line per ID.", ["B04", "B05"],
     ["assets/asset_manifest.gd", "assets/placeholder_factory.gd", "art/char_idle.png", "art/char_idle.png.import",
      "art/char_walk.png", "art/char_walk.png.import", "art/char_aim.png", "art/char_aim.png.import",
      "art/char_shoot.png", "art/char_shoot.png.import", "art/char_hurt.png", "art/char_hurt.png.import",
      "art/char_grabbed.png", "art/char_grabbed.png.import", "art/char_recover.png", "art/char_recover.png.import",
      "art/char_celebrate.png", "art/char_celebrate.png.import", "art/env_factory_floor.png",
      "art/env_factory_floor.png.import"]),
    ("player_states", "Eight-state player: aim wind-up and single-press fire, hit chain with invulnerability, "
     "threat arrow, celebrate lock.", ["B06", "B07", "B08", "B09"], ["scenes/player.gd", "scenes/player.tscn"]),
    ("zombie", "Chase within 220 px, visible hit flash before the one alive→down transition, knockback on a grab.",
     ["B10", "B11"], ["scenes/zombie.gd", "scenes/zombie.tscn"]),
    ("audio_and_mutes", "Sound autoload: SFX players and trigger counts, MUS-LOOP with Forward loop import, two "
     "buses with independent mutes driven by the HUD.", ["B13", "B14"],
     ["audio/audio_director.gd", "default_bus_layout.tres", "ui/hud.gd", "ui/hud.tscn",
      "audio/sfx_shot.wav", "audio/sfx_shot.wav.import", "audio/sfx_down.wav", "audio/sfx_down.wav.import",
      "audio/sfx_hurt.wav", "audio/sfx_hurt.wav.import", "audio/sfx_clear.wav", "audio/sfx_clear.wav.import",
      "audio/mus_loop.wav", "audio/mus_loop.wav.import"]),
    ("facing", "Mirror + capped tilt drawing for fixed-elevation art; gameplay direction stays 360°.",
     ["B15", "B16"], ["scenes/facing.gd"]),
    ("celebrate_trace", "CHAR-CELEBRATE from storyboard/sheet through prompts, keying and scaling to the exit "
     "marker that shows it in engine.", ["B17", "B19", "B20", "B21"],
     ["scenes/exit_marker.gd", "scenes/exit_marker.tscn", "art/char_celebrate.png", "art/char_celebrate.png.import"]),
    ("trigger_test", "Scripted trigger-count test: every asset ID loads, each SFX fires once per event under "
     "held and repeated input; cannot prove audibility.", ["B22", "B23"],
     ["tests/trigger_count_test.gd", "tests/trigger_count_test.tscn"]),
]
for cid, _, _, paths in COMPONENTS:
    assign(cid, *paths)

EXCLUSIONS = [
    (".editorconfig", "editor formatting config; not runtime"),
    (".gitattributes", "Git line-ending config; not runtime"),
    (".gitignore", "Git ignore rules for the Godot cache; not runtime"),
    ("art/.gdkeep", "empty placeholder keeping the folder in Git"),
    ("audio/.gdkeep", "empty placeholder keeping the folder in Git"),
    ("icon.svg", "default Godot project icon; not used by gameplay"),
    ("icon.svg.import", "import settings for the unused default icon"),
    ("art/char_reference.png", "design reference image; never loaded by the game (SOURCES.md)"),
    ("art/char_reference.png.import", "import settings for the unloaded reference image"),
]

evidence = {
    "schema_version": 1, "teaching_contract": "code-then-result-v1",
    "files": [{"path": p, "sha256": sha(GAME / p), "role": "runtime source/asset" if not p.endswith(".import")
               else "import settings", "component_ids": c} for p, c in sorted(files.items())],
    "components": [{"id": cid, "explanation": ex, "beat_ids": bids, "files": paths}
                   for cid, ex, bids, paths in COMPONENTS],
    "excerpts": excerpts,
    "exclusions": [{"path": p, "reason": r} for p, r in EXCLUSIONS],
    "code_result_pairs": pairs,
}

(FILM / "beat_sheet.json").write_text(json.dumps(sheet, indent=2, ensure_ascii=False), encoding="utf-8")
(FILM / "gamedev-evidence.json").write_text(json.dumps(evidence, indent=2, ensure_ascii=False), encoding="utf-8")
total = sum(b["estimated_duration_s"] for b in beats)
print(f"{len(beats)} beats, est {total:.0f} s ({total/60:.1f} min); {len(excerpts)} excerpts; "
      f"{len(pairs)} code/result pairs; {len(files)} files in {len(COMPONENTS)} components; {len(EXCLUSIONS)} exclusions")
