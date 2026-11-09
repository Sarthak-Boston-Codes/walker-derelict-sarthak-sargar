"""Builds beat_sheet.json + gamedev-evidence.json for the DERELICT A6 (two particle
effects) film. Written by Claude Code, adapted from the A5 film's build_sheet.py.

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
SLUG = "claude-liam-derelict-a6-gamedev"
TITLE = "DERELICT: Two Particle Effects, Measured"
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
                                 "read is the HUD health/ammo panel and the SCRIPTED PLAY label, checked as regions.",
              "contrast_regions": [{"label": "HUD health and ammo", "box": [0.01, 0.02, 0.23, 0.19]},
                                   {"label": "SCRIPTED PLAY label", "box": [0.15, 0.91, 0.85, 0.985]}]}


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
     "Ahoj. This is Liam, in for Bear. DERELICT is a top-down 3D zombie shooter in Godot. This time it gained two "
     "particle effects: a burst where every bullet lands, and smoke that rises from the player's wounds. Here's how "
     "each was specified, built, tuned and checked.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on",
      "remotion": {"pattern": "ClaudeComposerAsk", "props": {
          "greeting": "Ahoj, Liam", "topic": "GODOT · PARTICLES", "segment": "DERELICT",
          "command": "Please use Walker to convert my game design document about DERELICT's bullet impacts and wound "
                     "smoke into two Godot particle effects, with a test for every setting and rule the brief names.",
          "runningText": "reading CHANGE-BRIEF.md, Assignment 6…",
          "folderLabel": "@NikBearBrown", "modelLabel": "Claude", "effortLabel": "High",
          "output": ["One burst per hit.", "Smoke from a game value.", "Every setting read back."]}}},
     role_note="COLD OPEN: reconstructed Walker prompt (labelled in FACTCHECK.md), not a recording.")

beat("B01", "BLUF",
     "Two particle effects, built and measured. Tests for the rules, strips for the look, and a person for the "
     "verdict, though that person hasn't looked yet. And up front: Claude wrote the brief, and Claude Code wrote "
     "everything else, including this film.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on-correct",
      "remotion": {"pattern": "BrutalistHesitantWriter", "props": {
          "text": "Two effects, built and shipped.\nTests for the rules,\nstrips for the look.",
          "triggerWords": "shipped", "replacementWords": "measured",
          "contextTitle": "DERELICT · PARTICLES", "brandLabel": "@NikBearBrown",
          "fontSize": 92, "lineSpacing": 1.5, "align": "center", "seed": "derelict-a6-gamedev",
          "mistakeRate": 2, "hesitateWithin": 0, "hesitateBetween": 1,
          "ink": "#3D3929", "accent": "#D97757", "bg": "#FAF9F5"}}},
     lead_silence_s=0.8, estimated_duration_s=13.0,
     role_note="Misconception corrected: done once it 'shipped' -> done once it's 'measured'.")

still_beat("B02", "SETUP",
           "Effect A tells you a bullet landed, and where. Its event is a new signal, bullet hit, emitted where the "
           "player's fire path resolves a hit on a zombie, barrel or crate. Effect B is a feedback loop: at sixty "
           "health or less, smoke rises from the player, and it thickens as health falls.",
           "media/B02.png", "SCRIPTED PLAY frames (film_capture.gd burstplay 40, smokeplay 190) + CHANGE-BRIEF refs")

tree_beat("B03", "ANSWERS",
          "Every particle system has three parts. Emission decides how many and when: amount, one shot, "
          "explosiveness. Process moves each particle: velocity, gravity, the curves. Draw decides what you see: the "
          "mesh, the material, the blend. Both effects are GPU particles, so the process step is a shader on the "
          "graphics card. A headless test runs no graphics card work, so their headless price is near zero by "
          "construction.",
          "Emission · process · draw.", "effects/impact_burst.tscn · particles_generated.gdshader",
          ["Emission → impact_burst.tscn:173-177  amount = 14, one_shot = true, explosiveness = 1.0",
           "Process  → particles_generated.gdshader:304  force = gravity;",
           "Draw     → impact_burst.tscn:98, :102  blend_mode = 1 (add), billboard_mode = 3 (particles)",
           "Headless → dummy renderer: no particle shader runs"],
          "Lines read from the files; the split of settings is Claude's (TEST-REPORT.md)",
          [{"label": "Node", "value": "GPUParticles3D ×4"}, {"label": "Godot", "value": "4.7.2, Forward+"}])

# --- Effect A ------------------------------------------------------------------------------------
code_beat("B04",
          "Effect A's sparks, straight from the scene file. Fourteen of them, launched upward within a fifty-five "
          "degree cone at three to six metres a second. Real gravity pulls them down, damping slows them, and a "
          "colour ramp takes them from orange to red. Every value is the brief's.",
          "effects/impact_burst.tscn", 81, 94, "Sparks: process settings, from the brief.",
          [(85, "spread 55°", "fifty-five degree cone"),
           (86, "3.0 – 6.0 m/s", "three to six metres"),
           (88, "gravity −9.8", "Real gravity"),
           (89, "damping 0.5 – 1.5", "damping slows them"),
           (93, "orange → red ramp", "a colour ramp")],
          [{"label": "Emitters", "value": "Flash 2 · Sparks 14 · Puff 8\none Node3D root"},
           {"label": "Config test", "value": "108 settings\nread back, PASS"}],
          "B05")
result_beat("B05",
            "The first strip, a fixture over the real level, dark and light. The brief wanted the flash on the "
            "trigger frame. It arrives one frame late. The sparks fly as planned, but the puff is a red-brown disc, "
            "full size from the start, and it never grows. Hold that thought.",
            "media/B05.png",
            "r0 strips: frame 10 empty, flash first on frame 11; sparks spread by +5; the puff is ~0.5 m from frame "
            "11 and does not grow; nothing by +20 (read by Claude, TUNING.md).",
            "captures/impact_burst/r0*/strip.png (FIXTURE)")

code_beat("B06",
          "The only gameplay change. Inside fire, when the ray hits something with a hit method, one new line emits "
          "bullet hit with the point and the surface normal, before the victim takes damage. So even a zombie that "
          "dies on that hit gets its burst.",
          "game3d/player.gd", 258, 267, "One signal, one emit.",
          [(263, "the victim branch", "something with a hit method"),
           (266, "bullet_hit.emit(end, hit.normal)", "one new line emits"),
           (267, "damage after the emit", "before the victim takes damage")],
          [{"label": "Signal", "value": "bullet_hit(point, normal)\nplayer.gd:14"},
           {"label": "Not a hit", "value": "walls keep the old sparks;\nbarrel blasts never reach fire()"}],
          "B07")
result_beat("B07",
            "Scripted play, real fire input, four zombies. Sixteen hits, sixteen bursts, and with the trigger held "
            "they stack up: up to four alive at once, separate, not one smeared cloud. The puffs sit on top of the "
            "game's existing blood and hit flash.",
            "media/B07.mp4",
            "SCRIPTED PLAY, Input.action_press fire + mouse events: 26 shots, 16 victim hits, 16 bursts; peak 4 "
            "alive at frame 45 (logs/film_capture_burstplay.log; clip = frames 0-239).",
            "Godot 4.7.2 · 3840×2160 SubViewport · SCRIPTED PLAY (film_capture.gd burstplay)", hold_note=HOLD)

code_beat("B08",
          "The retrigger rule is overlap. Twelve bursts wait under the level root. Each hit takes the next free "
          "one, or if all twelve are busy, restarts the oldest. It moves the burst to the hit, turns its up axis "
          "to the normal, and restarts all three emitters.",
          "game3d/impact_fx.gd", 56, 69, "A pool of twelve.",
          [(57, "next free burst", "takes the next free"),
           (59, "pool full: the oldest", "restarts the oldest"),
           (65, "+Y = normal", "turns its up axis"),
           (67, "restart() ×3", "restarts all three")],
          [{"label": "Free means", "value": "longest lifetime (0.6 s)\nhas passed: its own clock"},
           {"label": "Parent", "value": "level root, not the victim"}],
          "B09")
result_beat("B09",
            "The test drives that with a real mouse event and the real fire action. One hit, one burst, at the hit "
            "point, facing the normal. Two hits nine frames apart: two live bursts. The victim freed on the killing "
            "hit: its burst runs to the end. The pool case needs thirteen fake signals, because real fire never "
            "fills it.",
            "media/B09.png",
            "test_impact_burst_state.gd @60: 34 PASS; A1-A4, overlap, freed victim, pool exhausted via 13 "
            "test-emitted signals (docs/evidence/a6/final).",
            "recorded test output")

still_beat("B10", "REVISION",
           "First tuning revision. The biggest gap was the puff that never grew. The one setting: keep scale on its "
           "material. The prediction, committed before the edit: it grows, but as small dots, too weak on the light "
           "floor. It did grow, to seven centimetres. Specks. So it was reverted. The student's verdict is still "
           "pending.",
           "media/B10.png", "r0 vs r1 dark strips (FIXTURE) + TUNING.md A-r1")

# --- Effect B -------------------------------------------------------------------------------------------------
code_beat("B11",
          "Effect B's smoke. Born in a small sphere at the chest, drifting up slowly with a little buoyancy. Then the "
          "feature Effect A doesn't use: turbulence, at the brief's strength of point six, and an influence of point "
          "zero three. That last value is a tuning change, and we'll see why.",
          "effects/wound_smoke.tscn", 46, 59, "Smoke: a sphere, buoyancy, turbulence.",
          [(46, "0.4 – 0.8 m/s, slow", "drifting up slowly"),
           (48, "gravity +0.3: buoyancy", "a little buoyancy"),
           (56, "turbulence on", "turbulence, at"),
           (57, "noise strength 0.6", "strength of point six"),
           (58, "influence 0.03 (tuning B-r2)", "an influence of")],
          [{"label": "Emission", "value": "amount 40, never changed\namount_ratio driven"},
           {"label": "Config test", "value": "39 settings, PASS"}],
          "B12")
result_beat("B12",
            "Its strips, measured against a run with no smoke at all, because by eye it barely showed. As built, a "
            "hundred and twenty-seven changed pixels on the light floor. After two revisions, five hundred and fifty "
            "eight, and wisps appear within half a second. Better, and still faint, and still lighter than what's "
            "behind it.",
            "media/B12.png",
            "r0 → r2 strips with diffs against a no-smoke control: frame 100 changed px 127/471 → 558/1050 "
            "(light/dark); wisps by +0.5 s in r2 (TUNING.md).",
            "captures/wound_smoke/r*/strip.png (FIXTURE) + diff counts")

code_beat("B13",
          "The driver turns health into smoke. At sixty or less, and alive, it sets the amount ratio: point two at "
          "sixty, rising to one at ten. Otherwise it stops the emitter. It never touches amount, which would rebuild "
          "the particle buffer and make the smoke pop.",
          "game3d/wound_smoke_driver.gd", 41, 54, "Health in, two properties out.",
          [(41, "clamp((60 − hp) / 50, 0.2, 1.0)", "point two at"),
           (45, "hp ≤ 60 and alive", "At sixty or less"),
           (49, "emitting on / off", "it stops the emitter"),
           (54, "death: off", "Otherwise")],
          [{"label": "Writes only", "value": "emitting, amount_ratio"},
           {"label": "Reads", "value": "health_changed, died"}],
          "B14")
result_beat("B14",
            "Scripted play. A real zombie swipe takes health to forty-six, and the smoke starts. Walk, and it trails "
            "behind as pale discs. Pause, and it freezes. A medkit lifts health to eighty-six: the emitter stops, and "
            "what's left thins out.",
            "media/B14.mp4",
            "SCRIPTED PLAY: hp 64 → 46 by a real swipe (frame 51), emitting true ratio 0.28; walk; paused frames "
            "~205-235; medkit hp 86 emitting false (logs/film_capture_smokeplay.log).",
            "Godot 4.7.2 · 3840×2160 SubViewport · SCRIPTED PLAY (film_capture.gd smokeplay)", hold_note=HOLD)

still_beat("B15", "REVISION",
           "Its tuning. Revision one widened the spread, predicting a cloud that leaves the player's silhouette. It "
           "failed. A throwaway run with turbulence off showed why: the default influence was pinning the wisps in "
           "place. Revision two cut the influence, and mostly held. The student's verdicts are pending.",
           "media/B15.png", "B-r1/B-r2 diffs + turbulence-off diagnostic (not kept) + TUNING.md")

# --- the process shader ------------------------------------------------------------------------------------------
code_beat("B16",
          "Godot writes the process shader itself. This is the one for the puff. Line one sixty-one multiplies the "
          "scale by the scale curve. Line one sixty-two multiplies the colour by the colour ramp. Those are the "
          "brief's curve and ramp, as shader code.",
          "shaders/particles_generated.gdshader", 159, 163, "The brief's curves, as shader code.",
          [(161, "scale curve 0.5 → 1.6", "Line one sixty-one"),
           (162, "colour ramp", "Line one sixty-two"),
           (163, "alpha curve 0.6 → 0", "as shader code")],
          [{"label": "Generated by", "value": "Godot 4.7.2 from a duplicate\nof the Puff's material"},
           {"label": "Saved by", "value": "tools/dump_particles_shader.gd"}],
          "B17")
result_beat("B17",
            "So why didn't the puff grow? The shader does write the scale into each particle. But the draw step, a "
            "billboard, throws it away unless keep scale is on. A probe measured it: the same quad at half scale, "
            "seventy-two pixels without it, thirty-six with.",
            "media/B17.png",
            "probe_particle_scale.gd (windowed): quad 1 m, scale 0.5 → 72 px with keep_scale false, 36 px true; "
            "generated lines 161/162/358 shown beside the brief settings.",
            "probe log + generated shader lines")

# --- tests, mistakes, contributions ------------------------------------------------------------------------------
still_beat("B18", "TESTS",
           "What the tests proved. Every setting in both tables, read back from the scenes. Rename a property to its "
           "Godot three name: the velocity silently falls to zero, the effect still fires, and only the test fails. "
           "Price: about two hundredths of a millisecond on the GPU, far inside both budgets. And no headless run "
           "can show you anything you'd see.",
           "media/B18.png", "final logs + gpu_price.log rendered as a card")

still_beat("B19", "TRACE",
           "Mistakes caught along the way. Claude Code's first state test treated emitting as alive, but a one-shot "
           "emitter switches that off two frames in. Headless mouse aim was stretched twenty times. A commit message "
           "miscounted a test. Uncertainty: every look claim here is Claude's. Next, the student plays it.",
           "media/B19.png", "text card from A6-LOG.md and git history",
           role_note="What went wrong: found by Claude Code's own tests, not by the student.")

still_beat("B20", "CREDITS",
           "Who wrote what. Claude wrote the brief, the predictions, the budgets and the tuning approvals. Claude "
           "Code wrote the effects, the code, the tests, the readings, the documents and this film. Godot generated "
           "the process shader. The student ran the kit, and every human check is still theirs to do. No external "
           "textures: the soft dots are gradients in the scenes.",
           "media/B20.png", "text card from SOURCES.md")

beat("B21", "VERDICT",
     "Implemented: a pooled impact burst on every bullet hit, and wound smoke driven by health, both tested "
     "through real play and far inside their GPU budgets. Limits: particle sizes don't change over life, the smoke "
     "reads lighter than intended, and the burst is a frame late. Human judgment: still to come, from the student.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "artifact-reveal",
      "remotion": {"pattern": "ClaudeVerdictArtifact", "props": {
          "artifactTitle": "Verdict", "artifactHeading": "Two effects, measured.", "brandLabel": "@NikBearBrown",
          "artifactLines": ["Implemented: impact burst, pool of 12, one burst per hit; 34 state checks.",
                            "Implemented: wound smoke from hp via amount_ratio, turbulence; 21 state checks.",
                            "Limits: no growth over life (billboard keep_scale); smoke reads light; 1-frame delay.",
                            "Human judgment: pending, from the student (HUMAN-CHECK-NOTES.md)."]}}})

beat("B22", "HANDOFF",
     "Your turn. Paste this: 'Use Walker on my DERELICT project. Turn on billboard keep scale for the puff and "
     "raise its scale to point five and point nine. Before you run anything, predict its size at frames twelve, "
     "fifteen and twenty of the strip, then capture it.' My prediction: twelve to twenty-three centimetres at birth, "
     "growing past forty. If it's smaller, find out why. Liam, in for Bear.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on",
      "remotion": {"pattern": "ClaudeComposerAsk", "props": {
          "greeting": "Your turn.", "topic": "GODOT · PARTICLES", "segment": "DERELICT",
          "command": "Use Walker on my DERELICT project. In godot/effects/impact_burst.tscn set the Puff material's "
                     "billboard_keep_scale to true and its scale_min/max to 0.5/0.9. Before you run anything, "
                     "predict the puff's size at strip frames 12, 15 and 20, then capture the strip.",
          "runningText": "paste this into Claude…", "folderLabel": "@NikBearBrown", "modelLabel": "Claude",
          "effortLabel": "High", "output": ["Two settings.", "One prediction.", "One strip to check it."],
          "animateTyping": True}}})

beat("B23", "OUTRO", "Liam, in for Bear.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "mascot-title",
      "remotion": {"pattern": "ClaudeTitleOutro", "props": {"title": TITLE, "slug": SLUG}}},
     audio_policy="silence", estimated_duration_s=7.0,
     role_note="Locked outro: @NikBearBrown, slug-seeded mascot, stock jingle only; no narration or game audio.")

sheet = {"metadata": {
    "title": TITLE, "slug": SLUG, "topic": "GODOT · PARTICLES", "kind": "gamedev", "mode": "walker",
    "brand": "claude-liam", "register": "Teardown", "engine": "kokoro", "voice": "am_onyx", "voice_kokoro": "am_onyx",
    "palette": "claude", "style_preset": "claude", "ground": "#FAF9F5", "aspect_ratio": "16:9", "fit": "pad",
    "captions": False, "greeting": "Ahoj, Liam",
    "greeting_note": "hello lexicon: Ahoj (Czech); previous reels used Kia ora, Jambo, Bula, Hej.",
    "persona": "Liam (in for Bear)", "presenter": "Liam (in for Bear)", "in_for_bear": True,
    "game": PROJECT, "game_code_revision": "f4af1c4",
    "note": "godot-gamedev walker film, Assignment 6, built by Claude Code. Captures: captures/routes/film_capture.gd "
            "and the repo's fixture strips. No game change, paid call, upload or publication."},
    "beats": beats}

files = {}


def assign(component, *paths):
    for p in paths:
        files.setdefault(p, []).append(component)


COMPONENTS = [
    ("impact_burst_effect", "Effect A scene: three GPUParticles3D (Flash, Sparks, Puff) under one Node3D, every "
     "setting from the brief, soft-dot GradientTexture2D in the scene; its config test and preview fixtures.",
     ["B03", "B04", "B05", "B10"],
     ["effects/impact_burst.tscn", "tests/test_impact_burst_config.gd", "previews/effect_preview.gd",
      "previews/impact_burst_preview.tscn", "previews/impact_burst_preview_light.tscn"]),
    ("impact_trigger", "bullet_hit signal and emit in player.gd's fire path; impact_fx.gd pool of 12 under the level "
     "root (overlap, oldest restarted), wired in game.gd; the state test with real input.",
     ["B02", "B06", "B07", "B08", "B09"],
     ["game3d/player.gd", "game3d/impact_fx.gd", "game3d/game.gd", "tests/test_impact_burst_state.gd"]),
    ("wound_smoke_effect", "Effect B scene: one GPUParticles3D with sphere emission, buoyancy and turbulence "
     "(influence tuned), config test and preview fixtures.", ["B11", "B12", "B15"],
     ["effects/wound_smoke.tscn", "tests/test_wound_smoke_config.gd", "previews/wound_smoke_preview.tscn",
      "previews/wound_smoke_preview_dark.tscn"]),
    ("wound_smoke_driver", "Presentation-only driver: health_changed/died in, emitting and amount_ratio out; the "
     "state test with real zombie damage, a medkit, pause and hide.", ["B02", "B13", "B14"],
     ["game3d/wound_smoke_driver.gd", "tests/test_wound_smoke_state.gd"]),
    ("process_shader", "Godot 4.7.2's generated ParticleProcessMaterial shader (Puff duplicate), the dump tool, and "
     "the probe showing billboard particles drop the process scale.", ["B03", "B16", "B17"],
     ["shaders/particles_generated.gdshader", "tools/dump_particles_shader.gd", "tools/probe_particle_scale.gd"]),
    ("price", "Headless CPU cost script with an empty-scene control, and the windowed GPU-counter script.",
     ["B18"], ["tests/cost_effects.gd", "tools/gpu_price.gd"]),
]
for cid, _, _, paths in COMPONENTS:
    assign(cid, *paths)

inventory = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob("*")
                   if p.is_file() and not any(x in (".godot", ".git") for x in p.relative_to(GAME).parts)
                   and p.suffix != ".uid")
SPECIAL = {
    "project.godot": "project config, unchanged by A6 (window 1280x720; renderer default Forward+; cited in B03)",
}


def reason(p):
    if p in SPECIAL:
        return SPECIAL[p]
    if p.startswith("game3d/") or p.startswith("assets/3d/characters"):
        return "3D game code/asset unchanged by A6 (A2 redo / A5); not part of the particle work"
    if p.startswith("tests/"):
        return "earlier test suite, unchanged by A6; its baseline counts are in TEST-REPORT.md"
    if p.startswith("shaders/") or p.startswith("materials/") or p.startswith("textures/") or p.startswith("scenes/"):
        return "A5 shader/material work, unchanged by A6 (godot/shaders/ A5 files never edited)"
    if p.startswith("tools/"):
        return "earlier capture/dump tool (A5), unchanged by A6"
    if p.startswith("assets/3d/"):
        return "A3 asset, unchanged by A6"
    return "2D slice or shared asset from A2, unchanged by A6"


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
