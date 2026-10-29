"""Builds beat_sheet.json + gamedev-evidence.json for the DERELICT A5 (shaders and
materials) film. Written by Claude Code, adapted from the A3 film's build_sheet.py.

Code excerpts are read from the game files by line range, so the displayed code
is verbatim by construction. Rerun after any game or media change; the checker
(verify_gamedev.py) fails on stale hashes or line drift.

  python build_sheet.py
"""
import hashlib, json
from pathlib import Path

FILM = Path(__file__).resolve().parent
REPO = FILM.parents[1]
GAME = REPO / "godot"
SLUG = "claude-liam-derelict-a5-gamedev"
TITLE = "DERELICT: Two Shaders, Measured"
PROJECT = "walker-derelict-sarthak-sargar"
WPS = 2.5


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def lines(path, a, b):
    src = (GAME / path).read_text(encoding="utf-8").splitlines()
    return "\n".join(src[a - 1:b])


def est(text, minimum=4.0):
    return round(max(minimum, len(text.split()) / WPS + 0.6), 1)


beats, excerpts, pairs = [], [], []
_old = FILM / "beat_sheet.json"
MEASURED = {b["beat_id"]: b for b in json.loads(_old.read_text(encoding="utf-8"))["beats"]} if _old.exists() else {}


def measured(bid, narration):
    o = MEASURED.get(bid)
    if o and o.get("narration_text") == narration and o.get("audio_file"):
        keep = {"audio_file": o["audio_file"], "actual_duration_s": o["actual_duration_s"]}
        for k in ("lead_silence_baked", "tts_speed", "narration_padded_to", "narration_voiced_s"):
            if k in o:
                keep[k] = o[k]
        return keep
    return {}


def anchored_cues(narration, duration, cues):
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


def tree_beat(bid, act, narration, title, label, tree, source, notes):
    dur = measured(bid, narration).get("actual_duration_s") or est(narration)
    beat(bid, act, narration, {
        "type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "tree-reveal",
        "remotion": {"pattern": "GodotDevWorkbench", "props": {
            "mode": "tree", "title": title, "project": PROJECT, "source": source,
            "treeLabel": label, "tree": tree, "notes": notes, "durationSeconds": dur}}})


def code_beat(bid, narration, path, a, b, title, cue_anchors, notes, result):
    code = lines(path, a, b)
    excerpts.append({"beat_id": bid, "path": path, "start_line": a, "end_line": b, "text": code})
    dur = measured(bid, narration).get("actual_duration_s") or est(narration)
    beat(bid, "MECHANISM", narration, {
        "type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "line-highlight",
        "remotion": {"pattern": "GodotDevWorkbench", "props": {
            "mode": "code", "title": title, "project": PROJECT, "path": path,
            "source": f"godot/{path} lines {a}-{b} · Godot editor reconstruction",
            "code": code, "startLine": a, "cues": anchored_cues(narration, dur, cue_anchors),
            "inspectorLabel": "Source notes — not Inspector values", "notes": notes,
            "output": [f"{path} · code → visible result", "Godot editor reconstruction"],
            "durationSeconds": dur}}},
         cue_timing="highlights placed by anchor-phrase character offset × measured duration (no TTS word timestamps)")
    pairs.append({"code_beat": bid, "result_beat": result})


CAPTURE_QC = {"full_bleed": True,
              "contrast_reason": "Full-frame dark engine capture: the dark scene is the picture. The text that must "
                                 "read is the HUD ammo counter and the SCRIPTED PLAY label, checked as regions.",
              "contrast_regions": [{"label": "HUD ammo counter", "box": [0.12, 0.08, 0.23, 0.17]},
                                   {"label": "SCRIPTED PLAY label", "box": [0.25, 0.91, 0.75, 0.985]}]}


def result_beat(bid, narration, media, observation, label, hold_note=None):
    is_clip = media.endswith(".mp4")
    shot = {"type": "FOOTAGE" if is_clip else "STILL", "source": "own", "treatment": "none",
            "evidence_media": media, "media": media, "motion": "footage" if is_clip else "hold", "label": label}
    if hold_note:
        shot["hold_policy"] = hold_note
    beat(bid, "RESULT", narration, shot, **({"qc": CAPTURE_QC} if is_clip else {}))
    for p in pairs:
        if p["result_beat"] == bid:
            p["observation"] = observation
            p["media"] = {"path": media, "sha256": sha(FILM / media)}


def still_beat(bid, act, narration, media, label, **extra):
    beat(bid, act, narration, {"type": "STILL", "source": "own", "treatment": "none", "motion": "hold",
                               "media": media, "label": label}, **extra)


HOLD = ("capture plays at capture speed; if measured narration is longer, a frame hold labelled HOLD is appended "
        "after it (never slowed). conform_clips.py.")

# --- bookends ----------------------------------------------------------------------------
beat("B00", "ASK",
     "Kia ora. This is Liam, in for Bear. DERELICT is a top-down 3D zombie shooter in Godot. For this assignment it "
     "gained two shaders and two materials: a warning that turns the ammo counter red, and a real concrete floor. "
     "Here's how each was specified, built and checked.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on",
      "remotion": {"pattern": "ClaudeComposerAsk", "props": {
          "greeting": "Kia ora, Liam", "topic": "GODOT · SHADERS", "segment": "DERELICT",
          "command": "Please use Walker to convert my game design document about DERELICT's low-ammo warning and "
                     "concrete factory floor into Godot shaders and materials, with a test for every rule the "
                     "brief predicts.",
          "runningText": "reading CHANGE-BRIEF.md, Assignment 5…",
          "folderLabel": "@NikBearBrown", "modelLabel": "Claude", "effortLabel": "High",
          "output": ["One warning, timed by delta.", "One floor, two materials.", "Every prediction measured."]}}},
     role_note="COLD OPEN: reconstructed Walker prompt (labelled in FACTCHECK.md), not a recording.")

beat("B01", "BLUF",
     "Two shaders and two materials, written and measured. A test for the timing, and a person for the look, though "
     "that person hasn't looked yet. And the plain fact up front: the shader code is AI-written, with the TA's "
     "permission.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on-correct",
      "remotion": {"pattern": "BrutalistHesitantWriter", "props": {
          "text": "Two shaders, written and compiled.\nA test for the timing,\na person for the look.",
          "triggerWords": "compiled", "replacementWords": "measured",
          "contextTitle": "DERELICT · SHADERS", "brandLabel": "@NikBearBrown",
          "fontSize": 92, "lineSpacing": 1.5, "align": "center", "seed": "derelict-a5-gamedev",
          "mistakeRate": 2, "hesitateWithin": 0, "hesitateBetween": 1,
          "ink": "#3D3929", "accent": "#D97757", "bg": "#FAF9F5"}}},
     lead_silence_s=0.8, estimated_duration_s=13.0,
     role_note="Misconception corrected: done once it 'compiled' -> done once it's 'measured'.")

still_beat("B02", "SETUP",
           "The state is low ammo: five rounds or fewer in the magazine. It lives in player dot g d, and reaches the "
           "HUD through the ammo-changed signal. Left, a full magazine in yellow. Right, five rounds, and the "
           "counter has turned red. The textured object is the factory floor.",
           "media/B02.png", "SCRIPTED PLAY frames 0 and 90 (film_capture.gd playclip) + CHANGE-BRIEF §1 references")

tree_beat("B03", "ANSWERS",
          "Four answers, each pinned to a line. A shader is a small program the GPU runs for every pixel; this one's "
          "whole job is line thirteen of low ammo. A material is one shader plus its current values: concrete wet "
          "points at the shared shader, then sets wetness to point eight. A texture is information: the normal "
          "map's numbers are slopes, so it's read as data. And the Godot shading language is GLSL-like code with "
          "Godot's built-ins and hints: shader type spatial, then ALBEDO, and no main function.",
          "Four answers, four lines.", "LANGUAGE-NOTES.md · the brief's questions",
          ["Shader: runs per pixel → low_ammo.gdshader:13  COLOR.rgb = mix(…)",
           "Material: shader + values → concrete_wet.tres:11 shader, :19 wetness = 0.8",
           "Texture = information → concrete_surface.gdshader:13 normal_tex : hint_normal",
           "Shading language → concrete_surface.gdshader:1 shader_type spatial; :34 ALBEDO"],
          "Answers by Claude Code (LANGUAGE-NOTES.md); line numbers from the files",
          [{"label": "Renderer", "value": "Forward+ (default)"}, {"label": "Godot", "value": "4.7.2"}])

# --- shader 1 -------------------------------------------------------------------------------
code_beat("B04",
          "The shader. Two uniforms: low ammo, a number from zero to one, and the warning colour, red. Then the "
          "colour line. COLOR already holds the label's own yellow for this pixel, and mix slides it toward red by "
          "low ammo. The glyph test above it is a fix we'll come back to.",
          "shaders/low_ammo.gdshader", 6, 13, "Two uniforms, one colour line.",
          [(6, "0 → 1, set by the driver", "low ammo, a number"),
           (7, "#FF3030, source_color", "the warning colour"),
           (13, "the colour line", "Then the"),
           (12, "the shadow fix (revision 2026-10-29)", "The glyph test")],
          [{"label": "shader_type", "value": "canvas_item (line 1)"},
           {"label": "Written by", "value": "Claude (chat);\nline 12 fix: Claude Code"}],
          "B05")
result_beat("B05",
            "With the driver paused, the capture script sets the value by hand. At zero, pixel A in the five and "
            "pixel B in the slash read exactly the predicted yellow. At a half: two forty-eight, one twenty, "
            "sixty-three, as predicted. At one, pure warning red. And at two, outside the slider's range: two "
            "fifty-five, zero, eighteen. So hint range doesn't clamp a value set from code.",
            "media/B05.png",
            "Driver paused, low_ammo set to 0, 0.5, 1, 2: pixels A and B read (242,193,78), (248,120,63), "
            "(255,48,48), (255,0,18); the first three match CHANGE-BRIEF §2, the last shows no clamp.",
            "label crops of 4K captures (a5_capture.gd ammo) + logs/capture_ammo_fixed.log")

code_beat("B06",
          "The driver never writes game state. The signal sets a target: one at five rounds or fewer, otherwise "
          "zero. Each frame, the value moves toward it by rate times delta: four per second up, two down. Delta is "
          "scaled game time, and the node is pausable, so pause freezes it.",
          "game3d/low_ammo_driver.gd", 36, 45, "Target from a signal, motion by delta.",
          [(45, "writes only low_ammo", "The driver never"),
           (37, "mag <= 5 → 1.0", "The signal sets a target"),
           (44, "move_toward × delta", "moves toward it")],
          [{"label": "Rates", "value": "RATE_UP 4.0 /s\nRATE_DOWN 2.0 /s"},
           {"label": "_ready()", "value": "PROCESS_MODE_PAUSABLE\npriority 100"}],
          "B07")
result_beat("B07",
            "Scripted play, with real fire input. At five rounds the counter warms to red; reload, and it fades "
            "back.",
            "media/B07.mp4",
            "SCRIPTED PLAY, real Input.action_press fire/reload: mag 15 → 5, low_ammo 0 → 1 (frames 59-67), reload, "
            "back to 0 (logs/film_capture_playclip.log).",
            "Godot 4.7.2 · 3840×2160 SubViewport · SCRIPTED PLAY (film_capture.gd playclip)", hold_note=HOLD)

still_beat("B08", "TESTS",
           "The test drives that with real input and samples the value every frame, at thirty, sixty and a hundred "
           "forty-four frames a second. The fade-in takes a quarter second of game time at each, within one frame. "
           "Pause freezes it. Half time-scale doubles the real time. One caveat: the state can't end during a "
           "fade-in in play, so the test emits that signal itself.",
           "media/B08.png", "logs/final_low_ammo_test_{30,60,144}fps.log rendered as a table")

# --- hint experiment -----------------------------------------------------------------------
code_beat("B09",
          "The hint experiment. One grey strip, three bands: sixty-four, one twenty-eight, one ninety-two. Two "
          "samplers read the same file: one marked source colour, one not. A bool picks which one writes albedo, "
          "unshaded, so lighting can't interfere.",
          "shaders/hint_experiment.gdshader", 7, 13, "One file, two samplers.",
          [(7, "source_color: decoded as sRGB", "one marked source colour"),
           (8, "no hint: read as stored", "one not"),
           (9, "which sampler writes", "A bool picks"),
           (13, "ALBEDO, unshaded", "writes albedo")],
          [{"label": "Texture", "value": "greys_3x1.png\n64 · 128 · 192\nLossless, no mipmaps"},
           {"label": "render_mode", "value": "unshaded (line 2)"}],
          "B10")
result_beat("B10",
            "Predicted, then measured. Through source colour, the bands come back unchanged: sixty-four, one "
            "twenty-eight, one ninety-two. Without it: one thirty-seven, one eighty-eight, two twenty-five. "
            "Exactly the prediction. A colour read as data comes out too bright.",
            "media/B10.png",
            "hint_experiment.tscn captured: source_color quad 64/128/192, plain quad 137/188/225, identical to "
            "CHANGE-BRIEF §3's predictions.",
            "4K capture (a5_capture.gd hint) + logs/capture_hint.log")

# --- textured shader -------------------------------------------------------------------------
code_beat("B11",
          "The floor. One colour texture, sampled as colour, tinted, then darkened by wetness. Roughness is read "
          "from the red channel as data, and wetness pulls it toward glossy. The normal map goes straight into "
          "NORMAL_MAP, as data.",
          "shaders/concrete_surface.gdshader", 31, 37, "One colour texture, two data textures.",
          [(32, "albedo_tex (source_color)", "One colour texture"),
           (33, "roughness: red channel", "Roughness is read"),
           (35, "wet → glossy", "pulls it toward glossy"),
           (36, "normal map as data", "The normal map")],
          [{"label": "UVs", "value": "world-space,\nvertex() lines 25-29"},
           {"label": "Texture set", "value": "Poly Haven\nconcrete_floor_worn_001\nCC0"}],
          "B12")
result_beat("B12",
            "In the game the floor is now the photo texture: dry everywhere, wet in the Boiler Room. Honestly, from "
            "the game's camera, the wet floor is hard to tell apart. Under the lab's single light, the wet tile is "
            "darker and glossier. Whether it reads in play is a human check, still pending.",
            "media/B12.png",
            "Staged in-game still at the Boiler Room doorway (difference barely visible) beside material_lab.tscn "
            "(wet tile visibly darker with a specular patch).",
            "film_capture.gd floor (STAGED) + a5_capture.gd twomat baseline")

still_beat("B13", "SWEEP",
           "Then every uniform, from minimum to maximum, on the dry tile. Most move the picture a little. Two "
           "findings: only the smallest UV scale shows readable concrete detail from this distance, and wet "
           "darkening at full strength turns the floor into a black mirror.",
           "media/B13.png", "16 SCRIPTED captures (a5_capture.gd sweep) + logs/capture_sweep.log")

code_beat("B14",
          "Two materials share that shader. This is the wet one: the same shader path, the same three textures, "
          "wetness point eight and a cooler tint. The dry file is identical except those two lines.",
          "materials/concrete_wet.tres", 11, 20, "A material: a shader plus values.",
          [(11, "the shared shader", "the same shader path"),
           (19, "wetness = 0.8", "wetness point eight"),
           (12, "tint #C8CCD0", "a cooler tint")],
          [{"label": "concrete_dry.tres", "value": "wetness 0.0\nalbedo_tint white"}],
          "B15")
result_beat("B15",
            "So: edit one line of the shared shader, in memory, and both tiles turn red. Revert. Edit one value in "
            "the dry material, and only the dry tile changes. Each revert lands back on the exact baseline numbers.",
            "media/B15.png",
            "Shader line edited: dry G 100.3 → 79.5 and wet G 55.8 → 35.9 (both). Dry albedo_tint edited: dry G → "
            "69.3, wet unchanged at 55.8. Reverts return 100.3 / 55.8.",
            "4K captures (a5_capture.gd twomat) + logs/capture_twomat.log")

# --- the language ------------------------------------------------------------------------------
code_beat("B16",
          "This shader was written by Godot itself, for a standard material with three textures. Line thirty-four "
          "samples albedo, from a sampler declared as source colour. Line forty-six samples the normal map, "
          "declared as data. No main function, no lighting code: Godot's built-ins carry it.",
          "shaders/standard_generated.gdshader", 33, 47, "Godot's own shader.",
          [(34, "albedo sampled (G:7 source_color)", "Line thirty-four"),
           (35, "ALBEDO written", "samples albedo"),
           (46, "normal sampled as data (G:19)", "Line forty-six")],
          [{"label": "Generated by", "value": "Godot 4.7.2 from a\nStandardMaterial3D"},
           {"label": "Saved by", "value": "tools/\ndump_standard_shader.gd"}],
          "B17")
result_beat("B17",
            "Beside ours: the same pattern, line for line. The colour sampler carries source colour; the normal "
            "sampler doesn't. Getting this file was its own problem: the obvious call isn't available to scripts, "
            "so a tool found the shader on the rendering server. One match, sixteen ninety-eight characters.",
            "media/B17.png",
            "dump_standard_shader.gd windowed run printed 'generated StandardMaterial3D shaders found: 1' and "
            "'wrote … (1698 characters)'; card sets G:7/34/19/46 beside C:9/32/13/36.",
            "logs/dump_standard_shader.log + lines read from both shader files")

# --- tests, mistakes, contributions ----------------------------------------------------------------
still_beat("B18", "TESTS",
           "What the tests proved, and proof they can fail. Delete a semicolon: shader error, exit one. Rename the "
           "uniform in the shader only: exit one, but every timing rule still passed, because set shader parameter "
           "accepts a name that doesn't exist. Remove source colour from the albedo sampler: exit one. And no "
           "headless run can show colour, gloss or readability.",
           "media/B18.png", "logs/mutation_{a,b,c}*.log rendered as a card")

still_beat("B19", "REVISION",
           "The mistake a capture caught. The label has a drop shadow, drawn through the same shader. At full "
           "warning the black shadow turned red, and the counter smeared. The brief had flagged that risk. The "
           "revision went into the brief first, then the fix: tint only where the colour isn't black. The glyph "
           "pixels didn't move.",
           "media/B19.png", "before/after 4K label crops (af736a7, a8f1bc2) + CHANGE-BRIEF revision e434f65",
           role_note="What went wrong, part 1: found by Claude Code's capture inspection, not by the student.")

still_beat("B20", "TRACE",
           "Other mistakes. The kit's normal-map check had its sign reversed, and only separated the two "
           "conventions after downsampling. Claude Code committed that fix labelled 'as copied', then redid it "
           "honestly. Its own capture script hung once on a reload press. The uncertainty: every look claim here "
           "is Claude's. Next, the student plays it and writes down what they see.",
           "media/B20.png", "text card from A5-LOG.md and git history")

still_beat("B21", "CREDITS",
           "Who wrote what. Claude chat wrote the three shaders, the colour line and the predictions. Claude Code "
           "wrote the driver, tests, materials, tools, documents and this film, and made the shadow fix. Godot "
           "wrote the generated shader. The student chose the design by accepting Claude's defaults, and wrote no "
           "shader code. The TA allowed that verbally, on condition the student understands it. The concrete is "
           "CC0, from Poly Haven.",
           "media/B21.png", "text card from SOURCES.md and ATTRIBUTION.md")

beat("B22", "VERDICT",
     "Implemented: a low-ammo warning timed by delta, frozen on pause, tested at three frame rates; a textured "
     "floor with two materials from one shader; and a hint experiment measured exactly as predicted. Limits: the "
     "wet floor barely reads from the game camera, one rule needs a test-emitted signal, and the shadow fix skips "
     "black. Human judgment: still to come, from the student.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "artifact-reveal",
      "remotion": {"pattern": "ClaudeVerdictArtifact", "props": {
          "artifactTitle": "Verdict", "artifactHeading": "Two shaders, measured.", "brandLabel": "@NikBearBrown",
          "artifactLines": ["Implemented: low-ammo tint timed by delta, paused with the tree, tested at 30/60/144 fps.",
                            "Implemented: concrete floor, dry and wet materials from one shader; hint experiment exact.",
                            "Limits: wet floor faint in game; R7 via a test-emitted signal; shadow fix skips black.",
                            "Human judgment: pending, from the student (HUMAN-CHECK-NOTES.md)."]}}})

beat("B23", "HANDOFF",
     "Your turn. Paste this: 'Use Walker on my DERELICT project. Change the low-ammo fade-in rate from four to two "
     "per second. Before you run anything, predict what low ammo test reports for the fade-in at thirty, sixty and "
     "a hundred forty-four frames a second, then run it at each.' My prediction: half a second everywhere, and the "
     "R1 line fails, because the brief still says a quarter. If it passes, find out why. Liam, in for Bear.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on",
      "remotion": {"pattern": "ClaudeComposerAsk", "props": {
          "greeting": "Your turn.", "topic": "GODOT · SHADERS", "segment": "DERELICT",
          "command": "Use Walker on my DERELICT project. Change RATE_UP in godot/game3d/low_ammo_driver.gd from 4.0 "
                     "to 2.0. Before you run anything, predict what low_ammo_test.gd reports for R1 at 30, 60 and "
                     "144 fps, then run scripts/run-test.sh low_ammo_test.gd at each.",
          "runningText": "paste this into Claude…", "folderLabel": "@NikBearBrown", "modelLabel": "Claude",
          "effortLabel": "High", "output": ["One change.", "One prediction.", "Three runs to check it."],
          "animateTyping": True}}})

beat("B24", "OUTRO", "Liam, in for Bear.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "mascot-title",
      "remotion": {"pattern": "ClaudeTitleOutro", "props": {"title": TITLE, "slug": SLUG}}},
     audio_policy="silence", estimated_duration_s=7.0,
     role_note="Locked outro: @NikBearBrown, slug-seeded mascot, stock jingle only; no narration or game audio.")

sheet = {"metadata": {
    "title": TITLE, "slug": SLUG, "topic": "GODOT · SHADERS", "kind": "gamedev", "mode": "walker",
    "brand": "claude-liam", "register": "Teardown", "engine": "kokoro", "voice": "am_onyx", "voice_kokoro": "am_onyx",
    "palette": "claude", "style_preset": "claude", "ground": "#FAF9F5", "aspect_ratio": "16:9", "fit": "pad",
    "captions": False, "greeting": "Kia ora, Liam",
    "greeting_note": "hello lexicon: Kia ora (Māori); previous reels used Jambo, Bula, Hej.",
    "persona": "Liam (in for Bear)", "presenter": "Liam (in for Bear)", "in_for_bear": True,
    "game": PROJECT, "game_code_revision": "a8f1bc2",
    "note": "godot-gamedev walker film, Assignment 5, built by Claude Code. Captures: godot/tools/a5_capture.gd and "
            "captures/routes/film_capture.gd. No game change, paid call, upload or publication."},
    "beats": beats}

files = {}


def assign(component, *paths):
    for p in paths:
        files.setdefault(p, []).append(component)


TEX = "textures/concrete/concrete_floor_worn_001_"
COMPONENTS = [
    ("low_ammo_effect", "canvas_item shader on the HUD ammo label, driven by a presentation-only node from the "
     "player's ammo_changed signal; the shader's line 12 skips the black theme shadow (revision).",
     ["B02", "B04", "B05", "B06", "B07", "B19"],
     ["shaders/low_ammo.gdshader", "game3d/low_ammo_driver.gd", "game3d/hud.gd", "game3d/game.gd",
      "game3d/player.gd", "game3d/ui_theme.gd"]),
    ("low_ammo_test", "Headless SceneTree test: uniform list and source defaults, R1-R9 with real input at a "
     "pinned frame rate; R7 uses a test-emitted signal.", ["B08", "B18"], ["tests/low_ammo_test.gd"]),
    ("hint_experiment", "One 3x1 grey PNG read through a source_color sampler and a plain one on two unshaded "
     "quads; measured against the brief's prediction.", ["B09", "B10"],
     ["shaders/hint_experiment.gdshader", "materials/hint_as_colour.tres", "materials/hint_as_data.tres",
      "scenes/hint_experiment.tscn", "textures/hint_experiment/greys_3x1.png",
      "textures/hint_experiment/greys_3x1.png.import", "textures/hint_experiment/make_greys_3x1.gd"]),
    ("concrete_material", "Lit spatial shader with one colour and two data textures (Poly Haven CC0), two "
     "ShaderMaterials (dry, wet) from it, a lab scene to judge them, and level.gd putting them on the floors.",
     ["B11", "B12", "B13", "B14", "B15"],
     ["shaders/concrete_surface.gdshader", "materials/concrete_dry.tres", "materials/concrete_wet.tres",
      "scenes/material_lab.tscn", "game3d/level.gd", TEX + "diff_1k.png", TEX + "diff_1k.png.import",
      TEX + "rough_1k.png", TEX + "rough_1k.png.import", TEX + "nor_gl_1k.png", TEX + "nor_gl_1k.png.import",
      "textures/concrete/ATTRIBUTION.md"]),
    ("generated_shader", "Godot 4.7.2's generated StandardMaterial3D shader, saved by a RID-scan tool, compared "
     "line for line with concrete_surface.", ["B16", "B17"],
     ["shaders/standard_generated.gdshader", "tools/dump_standard_shader.gd"]),
    ("material_audit", "Material test (hints from source, values, import settings, formats, normal-map "
     "convention) and the calibrated kit normal-map check with its DX fixture.", ["B18", "B20"],
     ["tests/test_materials.gd", "tests/calibrate_normal_map_check.gd", "tests/normal_map_check.gd",
      "tests/fixtures/normal_maps/concrete_floor_worn_001_nor_dx_1k.png", "tests/fixtures/.gdignore", "MATERIALS.md"]),
    ("capture_tool", "Windowed 4K SubViewport capture and pixel measurement for the controlled values, hint "
     "experiment, sweep and two-material comparison.", ["B05", "B10", "B13", "B15"], ["tools/a5_capture.gd"]),
]
for cid, _, _, paths in COMPONENTS:
    assign(cid, *paths)

inventory = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob("*")
                   if p.is_file() and not any(x in (".godot", ".git") for x in p.relative_to(GAME).parts)
                   and p.suffix != ".uid")
SPECIAL = {
    "project.godot": "project config, unchanged by A5 (renderer default Forward+; cited in B03 notes)",
    "game3d/shaders/concrete_floor.gdshader": "the pre-A5 procedural floor shader, now unused (level.gd no longer "
                                              "preloads it)",
    "scenes/showcase_3d.tscn": "A3 showcase scene; unchanged by A5",
}


def reason(p):
    if p in SPECIAL:
        return SPECIAL[p]
    if p.startswith("game3d/") or p.startswith("assets/3d/characters"):
        return "3D game code/asset unchanged by A5 (A2 redo); not part of the shader or material work"
    if p.startswith("tests/"):
        return "earlier test suite, unchanged by A5; its before/after counts are in TEST-REPORT.md"
    if p.startswith("assets/3d/"):
        return "A3 asset, unchanged by A5"
    return "2D slice or shared asset from A2, unchanged by A5"


EXCLUSIONS = [(p, reason(p)) for p in inventory if p not in files]
evidence = {
    "schema_version": 1, "teaching_contract": "code-then-result-v1",
    "files": [{"path": p, "sha256": sha(GAME / p), "role": "import settings" if p.endswith(".import")
               else "runtime source/asset", "component_ids": c} for p, c in sorted(files.items())],
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
