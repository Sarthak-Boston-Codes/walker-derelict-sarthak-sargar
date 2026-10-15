"""Builds beat_sheet.json + gamedev-evidence.json for the DERELICT A3 (3D assets) film.

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
SLUG = "claude-liam-derelict-a3-gamedev"
TITLE = "DERELICT: Three Props, Built and Checked"
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
        for k in ("lead_silence_baked", "tts_speed", "narration_padded_to", "narration_voiced_s"):
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


def tree_beat(bid, act, narration, title, label, tree, source, notes):
    dur = measured(bid, narration).get("actual_duration_s") or est(narration)
    beat(bid, act, narration, {
        "type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "tree-reveal",
        "remotion": {"pattern": "GodotDevWorkbench", "props": {
            "mode": "tree", "title": title, "project": "walker-derelict-sarthak-sargar", "source": source,
            "treeLabel": label, "tree": tree, "notes": notes, "durationSeconds": dur}}})


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


CAPTURE_QC = {
    "full_bleed": True,
    "contrast_reason": "Full-frame 3D engine capture with no on-screen text: the gray floor and backdrop are "
                       "the picture, not a text background."}


def result_beat(bid, narration, media, observation, label, hold_note=None):
    is_clip = media.endswith(".mp4")
    shot = {"type": "FOOTAGE" if is_clip else "STILL", "source": "own", "treatment": "none",
            "evidence_media": media, "motion": "footage" if is_clip else "hold", "label": label}
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


HOLD = ("capture plays at capture speed; if measured narration is longer, a frame hold labelled HOLD is "
        "appended after it (never slowed). Built in step 4.")
CAPTURE = "Godot 4.7.2 · 3840×2160 SubViewport capture (showcase_capture.gd)"

# --- bookends -------------------------------------------------------------------------
beat("B00", "ASK",
     "Hej — this is Liam, in for Bear. DERELICT is a top-down 2D Godot game. For this assignment, the student "
     "added three 3D props, built in Blender by Claude through an MCP connection, then checked in a Godot "
     "showcase scene. Here's how they got from brief to scene.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on",
      "remotion": {"pattern": "ClaudeComposerAsk", "props": {
          "greeting": "Hej, Liam", "topic": "GODOT · 3D ASSETS", "segment": "DERELICT",
          "command": "Please use Walker to convert my game design document about DERELICT's first 3D assets — a "
                     "supply crate, a rusted barrel and a medkit — into Blender models and a Godot showcase scene "
                     "that proves each one matches its brief.",
          "runningText": "reading CHANGE-BRIEF.md, Assignment 3…",
          "folderLabel": "@NikBearBrown", "modelLabel": "Claude", "effortLabel": "High",
          "output": ["Three props, under budget.", "One showcase scene.", "One test for three predicted failures."]}}},
     role_note="COLD OPEN — reconstructed Walker prompt (labelled in FACTCHECK.md), not a recording.")

beat("B01", "BLUF",
     "Three 3D props, built and verified. A test checks every one against its brief, and a person checks what "
     "a test can't. That checking is what this film takes apart.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on-correct",
      "remotion": {"pattern": "BrutalistHesitantWriter", "props": {
          # Single-token trigger: the component matches whitespace tokens with their
          # punctuation stripped, so the trigger is the bare word, not "imported.".
          "text": "Three 3D props, built and imported.\nA test for every brief,\na person for the rest.",
          "triggerWords": "imported", "replacementWords": "verified",
          "contextTitle": "DERELICT · 3D", "brandLabel": "@NikBearBrown",
          "fontSize": 110, "lineSpacing": 1.5, "align": "center", "seed": "derelict-a3-gamedev",
          "mistakeRate": 2, "hesitateWithin": 0, "hesitateBetween": 1,
          "ink": "#3D3929", "accent": "#D97757", "bg": "#FAF9F5"}}},
     lead_silence_s=0.8, estimated_duration_s=12.0,
     role_note="Misconception corrected: the props are done once 'imported' -> done once 'verified'. Audio >= 9 s.")

tree_beat("B02", "SETUP",
          "The assignment: three 3D assets built in Blender and brought into Godot, each with a size, an origin "
          "and a triangle budget. DERELICT's gameplay stays 2D and untouched. The props live in a separate "
          "showcase: a floor, one light, one camera.",
          "What the brief asked for.", "CHANGE-BRIEF.md → Assignment 3",
          ["PROP-SUPPLY-CRATE — 0.5 m cube, ≤ 100 tris", "ENV-RUSTED-BARREL — 0.6 × 0.9 m, ≤ 200 tris",
           "PICKUP-MEDKIT — 0.3 × 0.2 × 0.15 m, ≤ 150 tris", "Origin — centre of the underside (all three)",
           "Showcase — floor · one light · one camera", "2D gameplay — untouched"],
          "CHANGE-BRIEF.md · Assignment 3 — first 3D assets",
          [{"label": "Started from", "value": "the finished 2D slice"}, {"label": "Blender", "value": "5.2.2 LTS"}])

tree_beat("B03", "SETUP",
          "Before anything was built, the brief predicted three ways this goes wrong. An asset arrives on its "
          "side. Its scale isn't applied, so it's off by a large factor. Or its origin sits in the middle, so it "
          "floats or sinks. Every check in this film points back at these three.",
          "Three predicted failures.", "CHANGE-BRIEF.md → predicted failure cases",
          ["1 · Lying on its side → Godot rotation must read 0, 0, 0",
           "2 · Scale not applied → node scale must read 1, 1, 1",
           "3 · Origin at the centre → must sit on the floor, no gap"],
          "CHANGE-BRIEF.md · Assignment 3 · predicted failure cases 1–3",
          [{"label": "Case 4", "value": "MCP connection: didn't occur"}])

# --- Blender side (stills) -----------------------------------------------------------------
still_beat("B04", "INTERFACE",
           "First, the tool. This is the student's own Blender session: the 3D viewport, the toolbar down the left, "
           "the Outliner listing the medkit, the Properties editor with its transform values, the sidebar holding "
           "the MCP panel, and the mode selector, set to Object Mode.",
           "media/B04.png", "author's own screenshot + BLENDER-NOTES.md part names (make_cards.py)")

still_beat("B05", "TRACE",
           "The crate started as one prompt: build only this asset, exactly to the brief. Claude made a body and "
           "two straps, one call per object, joined them, and checked: origin at zero, no rotation, scale one, "
           "half a metre each way, thirty-six triangles out of a hundred.",
           "media/B05.png", "trace card: author's prompt + get_scene_info output (session) + a3-stills/blender_01")

still_beat("B06", "TRACE",
           "And it looked wrong. The brief's colours are colour-picker values, but Blender's shader reads linear "
           "light, so the same numbers came out pale tan. The fix wasn't eyeballing it: convert each channel from "
           "sRGB to linear first. Converted back, the numbers match the brief exactly.",
           "media/B06.png", "before/after a3-stills + conversion code and output quoted from the session log",
           role_note="What Claude got wrong, part 1. Code is from the session transcript, not a repo file.")

still_beat("B07", "TRACE",
           "The barrel is a single twelve-sided cylinder, inside the brief's eight to twelve, at forty-four "
           "triangles of two hundred. The brief gave no number for rust, so Claude picked one, and the student "
           "approved it.",
           "media/B07.png", "a3-stills/blender_03 + values from get_scene_info and CHANGE-BRIEF.md Revisions")

still_beat("B08", "TRACE",
           "The medkit: a case, a lid inset by a centimetre, and a cross of two thin bars. Forty-eight triangles. "
           "Remember that cross. At this size, it's about to cause trouble.",
           "media/B08.png", "a3-stills/blender_04 + values from get_scene_info and CHANGE-BRIEF.md Revisions")

still_beat("B09", "EXPORT",
           "Then export. This reads the exported files directly, not Blender's view of them. Every node at "
           "rotation zero and scale one, sizes now Y-up, every base at zero, and the colours convert back to the "
           "brief's values. The barrel's twelve-sided caps became triangles, as assumed.",
           "media/B09.png", "logs/glb_inspect.log (inspect_glb.py on godot/assets/3d/*.glb)")

# --- Godot: the showcase scene --------------------------------------------------------------
code_beat("B10",
          "In Godot, the showcase places each exported file as an instance. The crate sits one metre left, the "
          "barrel at the origin, the medkit one metre right. No offsets, rotations or scale of its own, so if an "
          "asset is wrong, this scene won't hide it.",
          "scenes/showcase_3d.tscn", 29, 35, "Three files, one row.",
          [(29, "crate at x = −1", "The crate sits"),
           (32, "barrel at the origin", "barrel at the origin"),
           (34, "medkit at x = +1", "the medkit one metre right")],
          [{"label": "Instances of", "value": "res://assets/3d/\n*.glb (lines 3–5)"},
           {"label": "Floor", "value": "PlaneMesh 4 × 3 m\nat y = 0"}],
          "B11")
result_beat("B11", "Here it is running, through the scene's own camera: all three upright, on the floor, "
                   "casting shadows.",
            "media/B11.mp4",
            "showcase_3d.tscn running (4K SubViewport capture, scene Camera3D): crate, barrel and medkit upright "
            "on the floor at x = −1, 0, +1, with shadows. Static scene: nothing moves.",
            CAPTURE + " · scene camera", hold_note=HOLD)

# --- the test ------------------------------------------------------------------------------------
code_beat("B12",
          "The test starts by copying the brief into data: each asset's size and triangle budget. The comment "
          "matters. Blender is Z-up and Godot is Y-up, so the medkit's fifteen-centimetre height moves to the "
          "middle slot.",
          "tests/showcase_3d_test.gd", 16, 22, "The brief, as data.",
          [(19, "size + budget per asset", "size and triangle budget"),
           (17, "Blender Z-up → Godot Y-up", "Blender is Z-up"),
           (21, "medkit height: middle slot", "the medkit's fifteen")],
          [{"label": "Tolerance", "value": "0.001 m (line 15)"},
           {"label": "Command", "value": "godot --headless\n--path godot\nres://tests/\nshowcase_3d_test.tscn"}],
          "B13")
result_beat("B13", "On the current build, every row passes: rotation zero, scale one, bases at zero, sizes "
                   "matching the brief, triangles inside budget. Exit code zero.",
            "media/B13.png", "Recorded run on an isolated copy of HEAD: 3 × ok, PASS, exit 0.",
            "logs/showcase_pass.log, rendered as a card")

still_beat("B14", "HAND-EDIT",
           "Then the student tried it by hand: select the medkit, press S, drag, click to confirm. The logged "
           "result: scale went from one to one point nine five, location untouched, the mesh itself unchanged. "
           "This pair is a staged reconstruction. It was reverted. But what if it hadn't been?",
           "media/B14.png", "STAGED RECONSTRUCTION: author's screenshots (my_session.png, a3-stills/blender_07)",
           role_note="Narrates the FRICTIONAL.md value (1.95508), not the staged 1.897 visible in the still.")

code_beat("B15",
          "Here's the check for each asset. It walks every mesh inside the imported scene, not just the top node, "
          "and rejects any rotation or scale on them. Then it measures the real bounding box against the floor "
          "and the brief, and counts triangles.",
          "tests/showcase_3d_test.gd", 55, 65, "Every mesh, not just the root.",
          [(58, "mesh node: rotation 0, scale 1", "rejects any rotation"),
           (59, "world-space bounding box", "measures the real bounding box"),
           (63, "base on the floor ± 1 mm", "against the floor"),
           (65, "triangles ≤ budget", "counts triangles")],
          [{"label": "Line 62", "value": "instance root:\nrotation 0, scale 1"}],
          "B16")
result_beat("B16", "A demonstration on a throwaway copy: export the medkit with that scale left in, and run the "
                   "test. The medkit fails at twice its size. The scale column still says one. That's the "
                   "instance. The doubled scale is on the mesh inside, which is why the check walks the meshes.",
            "media/B16.png",
            "DEMONSTRATION on an isolated copy: medkit.glb exported at scale 1.95508 → Medkit FAIL, size "
            "(0.587, 0.293, 0.391), exit 1. SCALE column prints the instance root (1.00).",
            "logs/showcase_handedit_fail.log, rendered as a card · DEMONSTRATION, not the shipped build")

# --- inspect and revise ----------------------------------------------------------------------------
code_beat("B17",
          "The brief allows one light and one camera. The sun casts shadows; the camera's position and tilt "
          "decide what a viewer sees first. These two lines are the inspect-and-revise fix.",
          "scenes/showcase_3d.tscn", 15, 27, "One light, one camera.",
          [(22, "shadows on", "casts shadows"),
           (25, "camera position", "position and tilt"),
           (26, "tilt −35°", "These two lines")],
          [{"label": "Was (b74d239)", "value": "position (0, 1.3, 2.6)\nrotation −20°"},
           {"label": "Changed in", "value": "343a90c"}],
          "B18")
result_beat("B18", "Left, the first showcase: at a shallow twenty degrees, the medkit's cross is a few pixels. "
                   "Bigger arms alone barely helped. Right, the camera raised and tilted to thirty-five degrees, "
                   "with the larger cross. Now it reads as a pickup. One problem, two fixes.",
            "media/B18.png",
            "New 4K captures of each revision's scene camera: b74d239 (−20°, cross 0.12 × 0.04 m) vs HEAD (−35°, "
            "0.14 × 0.045 m); enlarged crops of the medkit.",
            "captures/b18_*.png (4K, each revision's own camera) composed as a card")

beat("B19", "HUMAN CHECK",
     "The human check: walk the camera around everything, behind and below. This is a capture-only camera, not "
     "the scene's. No missing faces. With a single light, the shadowed sides go very dark. And from underneath, "
     "the floor isn't drawn at all. It's a one-sided plane.",
     {"type": "FOOTAGE", "source": "own", "treatment": "none", "media": "media/B19.mp4", "motion": "footage",
      "label": "Godot 4.7.2 · 3840×2160 · CAPTURE CAMERA (added by showcase_capture.gd), not the scene's camera",
      "hold_policy": HOLD},
     qc=CAPTURE_QC,
     role_note="Mirrors the author's HUMAN CHECK in TEST-REPORT.md; the author's own pass was in the editor.")

still_beat("B20", "TRACE",
           "And what Claude got wrong, part two. The first camera pointed at the sky: its transform was written "
           "with the rows in the wrong order, and caught before any commit. The small cross was found after the "
           "showcase was committed, and took two fixes in a later commit.",
           "media/B20.png", "text card from TEST-REPORT.md (no image of the sky-camera frame survives)")

# --- verdict / your turn / outro ------------------------------------------------------------------
beat("B21", "VERDICT",
     "Implemented: three props under budget, exported upright at scale one with their origins on the floor, a "
     "showcase scene, and a test for all three predicted failures that catches a hand-edit leaking through. "
     "Limits: hidden faces inside overlapping boxes, flat shading on the barrel, dark sides under one light, and "
     "a test row that prints the wrong node's scale. Human judgment: the colours, the proportions, the hand-edit, "
     "and the walk-around in the editor.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "artifact-reveal",
      "remotion": {"pattern": "ClaudeVerdictArtifact", "props": {
          "artifactTitle": "Verdict", "artifactHeading": "Three props, checked.", "brandLabel": "@NikBearBrown",
          "artifactLines": ["Implemented: 3 props under budget, upright, scale 1, origin on the floor; showcase; a test for cases 1–3.",
                            "Catches: an unapplied scale leaking through export (demonstrated).",
                            "Limits: hidden faces, flat barrel, dark sides, SCALE column shows the root.",
                            "Human judgment: colours, proportions, the hand-edit, the editor walk-around."]}}})

beat("B22", "HANDOFF",
     "Your turn. Paste this: 'Use Walker on my DERELICT project. Rebuild the rusted barrel in Blender with eight "
     "sides instead of twelve. Before you export, predict its triangle count. Then export it, run the showcase "
     "test, and tell me whether the prediction and the test agree.' Here's the number to beat: eight sides give "
     "sixteen side triangles, and each cap splits into six, so twenty-eight. If the test says otherwise, find out "
     "why before you believe either. Liam, in for Bear.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on",
      "remotion": {"pattern": "ClaudeComposerAsk", "props": {
          "greeting": "Your turn.", "topic": "GODOT · 3D ASSETS", "segment": "DERELICT",
          "command": "Use Walker on my DERELICT project. Rebuild the rusted barrel in Blender with 8 sides instead "
                     "of 12. Before you export, predict its triangle count. Then export it, run "
                     "godot/tests/showcase_3d_test.tscn, and tell me whether the prediction and the test agree.",
          "runningText": "paste this into Claude…", "folderLabel": "@NikBearBrown", "modelLabel": "Claude",
          "effortLabel": "High", "output": ["One change.", "One prediction.", "One test to check it."],
          "animateTyping": True}}})

beat("B23", "OUTRO", "Liam, in for Bear.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "mascot-title",
      "remotion": {"pattern": "ClaudeTitleOutro", "props": {"title": TITLE, "slug": SLUG}}},
     audio_policy="silence", estimated_duration_s=7.0,
     role_note="Locked outro: @NikBearBrown, slug-seeded mascot, stock jingle only; no narration or game audio.")

sheet = {"metadata": {
    "title": TITLE, "slug": SLUG, "topic": "GODOT · 3D ASSETS", "kind": "gamedev", "mode": "walker",
    "brand": "claude-liam", "register": "Teardown", "engine": "kokoro", "voice": "am_onyx", "voice_kokoro": "am_onyx",
    "palette": "claude", "style_preset": "claude", "ground": "#FAF9F5", "aspect_ratio": "16:9", "fit": "pad",
    "captions": False, "greeting": "Hej, Liam",
    "greeting_note": "hello lexicon: Hej (Swedish); previous reels used Jambo, Bula. Liam never takes Wagwan.",
    "persona": "Liam (in for Bear)", "presenter": "Liam (in for Bear)", "in_for_bear": True,
    "game": "walker-derelict-sarthak-sargar", "game_code_revision": "e0a1e00",
    "note": "godot-gamedev walker film, Assignment 3. Captures: captures/MEDIA-LEDGER.json; Blender stills: "
            "youtube/claude-liam-derelict-gamedev/media/a3-stills (PROVENANCE.md). No game change, paid call, "
            "upload or publication."},
    "beats": beats}

files = {}
def assign(component, *paths):
    for p in paths:
        files.setdefault(p, []).append(component)

COMPONENTS = [
    ("glb_assets", "Three Blender exports (glTF binary, +Y up, transforms applied) and their Godot import settings: "
     "the props themselves, inspected directly.", ["B09", "B10", "B11"],
     ["assets/3d/supply_crate.glb", "assets/3d/supply_crate.glb.import", "assets/3d/rusted_barrel.glb",
      "assets/3d/rusted_barrel.glb.import", "assets/3d/medkit.glb", "assets/3d/medkit.glb.import"]),
    ("showcase_scene", "Separate 3D showcase: floor, one shadowed directional light, one camera, and the three GLBs "
     "as unmodified instances in a row.", ["B10", "B11", "B17", "B18", "B19"], ["scenes/showcase_3d.tscn"]),
    ("showcase_test", "Headless check of predicted failure cases 1-3 per asset and per mesh node, plus brief size "
     "and triangle budget; its printed SCALE column shows only the instance root.", ["B12", "B13", "B15", "B16"],
     ["tests/showcase_3d_test.gd", "tests/showcase_3d_test.tscn"]),
]
for cid, _, _, paths in COMPONENTS:
    assign(cid, *paths)

TWO_D = "2D gameplay slice, untouched by Assignment 3; covered by youtube/claude-liam-derelict-gamedev"
inventory = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob("*")
                   if p.is_file() and ".godot" not in p.relative_to(GAME).parts and p.suffix != ".uid")
SPECIAL = {
    "project.godot": "project config unchanged by A3 (main scene is the 2D slice); its Sound autoload still loads "
                     "in the showcase, which is why headless runs print the known MUS-LOOP leak warning (FACTCHECK.md)",
    ".editorconfig": "editor formatting config; not runtime", ".gitattributes": "Git line-ending config; not runtime",
    ".gitignore": "Git ignore rules for the Godot cache; not runtime",
    "art/.gdkeep": "empty placeholder keeping the folder in Git", "audio/.gdkeep": "empty placeholder keeping the folder in Git",
    "icon.svg": "default Godot project icon; not used", "icon.svg.import": "import settings for the unused default icon",
}
EXCLUSIONS = [(p, SPECIAL.get(p, TWO_D)) for p in inventory if p not in files]

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
