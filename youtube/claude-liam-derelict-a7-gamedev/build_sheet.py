"""Builds beat_sheet.json + gamedev-evidence.json for the DERELICT A7 (two animations)
film. Written by Claude Code, adapted from the A6 film's build_sheet.py.

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
SLUG = "claude-liam-derelict-a7-gamedev"
TITLE = "DERELICT: Two Animations, Frame by Frame"
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
     "Kamusta. This is Liam, in for Bear. DERELICT is a top-down 3D zombie shooter in Godot. This time it gained two "
     "animations on its HUD: a keycard that spins once you carry it, and a pistol that visibly reloads. Here's how "
     "each was specified, keyed, wired, tuned and checked.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on",
      "remotion": {"pattern": "ClaudeComposerAsk", "props": {
          "greeting": "Kamusta, Liam", "topic": "GODOT · ANIMATION", "segment": "DERELICT",
          "command": "Please use Walker to convert my game design document about DERELICT's keycard and reload "
                     "feedback into two Godot animations, a looping sprite cycle and a committing rig clip, with one "
                     "node in charge of each and a test for every key.",
          "runningText": "reading CHANGE-BRIEF.md, Assignment 7…",
          "folderLabel": "@NikBearBrown", "modelLabel": "Claude", "effortLabel": "High",
          "output": ["A cycle that loops.", "An action that commits.", "One authority."]}}},
     role_note="COLD OPEN: reconstructed Walker prompt (labelled in FACTCHECK.md), not a recording.")

beat("B01", "BLUF",
     "Two clips, built and pinned. Read back key by key, played through real input, and drawn frame by frame. A "
     "person still has to judge the feel, and they haven't yet. Up front: Claude wrote the brief, and Claude Code "
     "wrote everything else, including this film.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on-correct",
      "remotion": {"pattern": "BrutalistHesitantWriter", "props": {
          "text": "Two clips, built and finished.\nRead back key by key,\ndrawn frame by frame.",
          "triggerWords": "finished", "replacementWords": "pinned",
          "contextTitle": "DERELICT · ANIMATION", "brandLabel": "@NikBearBrown",
          "fontSize": 92, "lineSpacing": 1.5, "align": "center", "seed": "derelict-a7-gamedev",
          "mistakeRate": 2, "hesitateWithin": 0, "hesitateBetween": 1,
          "ink": "#3D3929", "accent": "#D97757", "bg": "#FAF9F5"}}},
     lead_silence_s=0.8, estimated_duration_s=13.0,
     role_note="Misconception corrected: done once it's 'finished' -> done once its behaviour is 'pinned'.")

still_beat("B02", "SETUP",
           "Clip one, the cycle: a keycard icon, a sprite stepping through eight cells at twelve frames a second, "
           "looping for as long as you carry the card. Clip two, the committing action: a cutout pistol rig at twenty "
           "four frames a second, playing once per reload, exactly one point two five seconds, the game's own "
           "reload time.",
           "media/B02.png", "SCRIPTED PLAY frames (film_capture.gd keyplay, reloadplay) + CHANGE-BRIEF refs")

tree_beat("B03", "ANSWERS",
          "So what is a clip? An animation resource: a length, a loop mode, and tracks. Each track names one node "
          "and one property, and holds keys: a time, a value, and a transition into the next key. An animation "
          "player reads it on every process tick and writes those properties. Nothing else about it is magic.",
          "Clip → tracks → keys.", "animations/keycard_spin.tres · animations/pistol_reload.tres",
          ["Clip     → keycard_spin.tres:10-12  length 0.6667, loop_mode 1 (linear), step 1/12",
           "Track    → keycard_spin.tres:16  NodePath(\"KeycardIcon:frame\")",
           "Keys     → keycard_spin.tres:20-23  times k/12, values 0…7, update 1 (discrete)",
           "Player   → keycard_icon.tscn  AnimationPlayer, callback PROCESS_IDLE, PAUSABLE"],
          "Lines read from the files",
          [{"label": "Routes", "value": "1: Sprite2D frame track\n3: Node2D cutout rig"},
           {"label": "Godot", "value": "4.7.2, Forward+"}])

# --- clip 1: the cycle -------------------------------------------------------------------------
code_beat("B04",
          "The keycard spin, as resource text. Eight keys, one twelfth of a second apart, values zero to seven, on "
          "the sprite's frame property. Discrete updates, so the frame never blends between cells. Loop mode linear, "
          "and the length is eight twelfths, so the last key is one interval short of the end.",
          "animations/keycard_spin.tres", 11, 23, "The cycle: eight keys on one track.",
          [(16, "KeycardIcon:frame", "the sprite's frame property"),
           (20, "times k/12", "one twelfth of a second apart"),
           (22, "update 1: discrete", "Discrete updates"),
           (11, "loop_mode 1: linear", "Loop mode linear"),
           (20, "last key 7/12, length 8/12", "the length is eight twelfths")],
          [{"label": "Length (line 10)", "value": "0.6666667 s = 8/12;\nlast key to end = 1/12 s"},
           {"label": "Read-back", "value": "32 PASS lines"}],
          "B05")
result_beat("B05",
            "The sheet comes from a script, not an artist: eight cells, sixty-four pixels square, a card turning in "
            "forty-five degree steps. The sprite slices it with h frames eight. In the strip each cell appears in "
            "order, and after cell seven comes cell zero, not a repeat. The card stays centred to half a pixel.",
            "media/B05.png",
            "keycard_sheet.png (8 x 64 px cells, tools/make_keycard_sheet.py); r0 strips light/dark: cells 0-7 then "
            "0 at frame 36, no repeat; bounding-box centre within 0.5 px (read by Claude, TUNING.md).",
            "godot/art/keycard_sheet.png + captures/keycard_spin/r0-*-strip.png (FIXTURE)")

# --- clip 2: the committing action ----------------------------------------------------------------
code_beat("B06",
          "Designing feel in frames means writing the timing down before the art. The brief's phase table: startup, "
          "frames zero to eleven; active, twelve to twenty three; recovery, twenty four to twenty nine. Each frame "
          "is one twenty fourth of a second, so frame twelve is half a second, here, where the magazine is all the "
          "way out.",
          "animations/pistol_reload.tres", 19, 32, "The reload: keys from the phase table.",
          [(19, "length 1.25 = RELOAD_TIME", "Designing feel"),
           (21, "step 1/24", "one twenty fourth"),
           (29, "f0 · f6 · f12 · f18 · f30", "startup"),
           (30, "ease-in, then ease-out", "recovery"),
           (32, "f12: magazine out, 64 px", "all the")],
          [{"label": "Phases", "value": "startup f0-11 · active f12-23\nrecovery f24-29 · end f30"},
           {"label": "Read-back", "value": "57 PASS lines; length\nread from player.gd"}],
          "B07")
result_beat("B07",
            "Here's the table beside the drawn frames, captured at thirty frames a second. The gun tilts and the "
            "magazine drops through startup. At half a second it's fully out. Through the active frames it's seated "
            "and the slide racks back. In recovery the gun levels. Each boundary lands one capture frame late. More "
            "on that in a moment.",
            "media/B07.png",
            "r2 dark/light strips: frame 26 (0.5 s) magazine 64 px out, tilt -0.21; frame 39 slide -18.8 px; frame 48 "
            "rest; every boundary one capture frame after the brief's list (read by Claude, TUNING.md).",
            "captures/pistol_reload/r2-*-strip.png (FIXTURE) + phase table")

# --- one authority -----------------------------------------------------------------------------------
code_beat("B08",
          "One authority means exactly one node decides what each animated node is doing. Here it's Hud Anim, and "
          "these two tables are all it knows. Hold, reload, dead for the rig. Hidden, then spinning, for the "
          "keycard. Every transition the brief lists, and nothing else.",
          "game3d/hud_anim.gd", 18, 28, "One authority: two state tables.",
          [(20, "HOLD: reload_started to RELOAD", "Hold, reload, dead"),
           (21, "RELOAD plays 'reload'", "for the rig"),
           (26, "HIDDEN to SPINNING", "Hidden, then spinning"),
           (27, "SPINNING plays 'spin'", "keycard. Every"),
           (22, "DEAD: no way out", "nothing else")],
          [{"label": "Reads", "value": "reload_changed, died,\nthe HUD keycard label"},
           {"label": "Structure test", "value": "51 PASS lines: one\nwriter, no autoplay"}],
          "B09")
result_beat("B09",
            "Scripted play with a real key press: walk north onto the keycard. The pickup picks it up, the HUD's "
            "label appears, Hud Anim sees it and starts the spin. It loops from then on. Nothing else in the game "
            "touches that sprite.",
            "media/B09.mp4",
            "SCRIPTED PLAY keyplay: player placed 3 m south of the keycard before filming (disclosed), W key walks "
            "onto it; keycard picked up, icon SPINNING (logs/film_capture_keyplay.log).",
            "Godot 4.7.2 · 3840x2160 SubViewport · SCRIPTED PLAY (film_capture.gd keyplay)", hold_note=HOLD)

code_beat("B10",
          "How a transition happens. An event the current state doesn't list is simply ignored. That's why a second "
          "reload press can't restart the clip. Entering a state either plays its clip from the start, or snaps the "
          "rig to the reset pose.",
          "game3d/hud_anim.gd", 99, 112, "Events in, play or rest out.",
          [(100, "look the event up", "the current state"),
           (101, "not listed: ignored", "simply ignored"),
           (111, "enter: play the clip from 0, or RESET (lines 113-118)", "plays its clip"),
           (106, "the icon's table works the same way", "the reset pose")],
          [{"label": "Writes only", "value": "play(), stop(), seek()\nand the icon's visible"},
           {"label": "Edge test", "value": "98 PASS lines at\nticks 29-31, 59-61, 74-76"}],
          "B11")
result_beat("B11",
            "Real reloads, an interrupt in each phase. Fire during startup: nothing. Reload again during the active "
            "frames: the clip carries on. Fire held through recovery: the shot comes the moment the reload ends. "
            "And pause: the rig freezes with the game's timer, then carries on.",
            "media/B11.mp4",
            "SCRIPTED PLAY reloadplay: real R, fire and Escape events; startup fire ignored, active R no restart, "
            "recovery fire gives the first shot on reload end, pause freezes clip and timer "
            "(logs/film_capture_reloadplay.log).",
            "Godot 4.7.2 · 3840x2160 SubViewport · SCRIPTED PLAY (film_capture.gd reloadplay)", hold_note=HOLD)

# --- the two clocks ------------------------------------------------------------------------------------
code_beat("B12",
          "The two clocks. The game's clock: reload time left, counted down in the player's process function, "
          "finishing the reload when it reaches zero. The clip's clock: the animation player, on the same process "
          "tick. The brief predicted they'd disagree by less than one frame.",
          "game3d/player.gd", 193, 198, "Clock one: the game's reload timer.",
          [(195, "reloading?", "reload time left"),
           (196, "_reload_left -= delta", "counted down"),
           (198, "_finish_reload()", "finishing the reload")],
          [{"label": "Clock two", "value": "AnimationPlayer,\nPROCESS_IDLE"},
           {"label": "Both", "value": "the process tick"}],
          "B13")
result_beat("B13",
            "Measured over five reloads at each rate. The game finishes on tick seventy five; the clip would finish on "
            "seventy six. Exactly one frame, every time, at sixty and at thirty frames a second, because the clip "
            "doesn't advance on the tick after it starts. Not under one frame. The prediction missed, and it's "
            "recorded.",
            "media/B13.png",
            "test_two_clocks.gd @60/@30: reload ends tick 75/38, unstopped clip finishes 76/39; largest disagreement "
            "0.0167 s / 0.0333 s, exactly one frame (docs/evidence/a7/two_clocks).",
            "recorded test output")

# --- tuning, tests, mistakes, credits ---------------------------------------------------------------------
still_beat("B14", "REVISION",
           "Tuning, one change at a time, each predicted before the edit. Revision one: the dropped magazine ran off "
           "the bottom of the window, so the rig moved up eighty pixels. Kept. Revision two: the slide's rack was too "
           "small to read, fourteen pixels became twenty four. Kept. The student's verdicts are pending.",
           "media/B14.png", "r0 vs r1 vs r2 light strips (FIXTURE) + TUNING.md")

still_beat("B15", "TESTS",
           "What the tests proved: every track resolves, every key time, step and loop mode is pinned, and the "
           "player's own timings didn't move. Break a track's property name, drop the loop, key cell eight: each "
           "test fails. Delete the import cache: nothing changes, because these clips are text. And no headless run "
           "shows you how any of it looks.",
           "media/B15.png", "final logs + mutation README rendered as a card")

still_beat("B16", "TRACE",
           "Mistakes caught. The brief put the card's back face on the wrong cells. The first strips put the rig "
           "over black void. Claude Code's own tests had bugs, and two commit messages miscounted. Uncertainty: "
           "every look claim here is Claude's. Next: the student plays it, with an interrupt in every phase.",
           "media/B16.png", "text card from A7-LOG.md and git history",
           role_note="What went wrong: found by Claude Code's own runs and reviews, not by the student.")

still_beat("B17", "CREDITS",
           "Who wrote what. Claude wrote the brief, the phase table, the cycle spec and the approvals. Claude Code "
           "wrote the sheet generator, the clips, the rig, Hud Anim, the tests, the readings, the documents and this "
           "film. The sheet is generated by code: no licence. The student ran the kit, and every human check is still "
           "theirs.",
           "media/B17.png", "text card from SOURCES.md")

beat("B18", "VERDICT",
     "Implemented: a looping keycard cycle and a committing reload rig, both under one authority, both read back key "
     "by key and played through real input. Limits: the clip trails the game by one frame, and the keycard is "
     "small. Human judgment: still to come, from the student.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "artifact-reveal",
      "remotion": {"pattern": "ClaudeVerdictArtifact", "props": {
          "artifactTitle": "Verdict", "artifactHeading": "Two clips, pinned.", "brandLabel": "@NikBearBrown",
          "artifactLines": ["Implemented: keycard spin, 8 cells @12 fps, LOOP_LINEAR; 32 read-back checks.",
                            "Implemented: reload rig @24 fps, 1.25 s = RELOAD_TIME, LOOP_NONE; 98 edge checks.",
                            "Limits: the clip trails the game's timer by exactly one frame; small icon.",
                            "Human judgment: pending, from the student (HUMAN-CHECK-NOTES.md)."]}}})

beat("B19", "HANDOFF",
     "Your turn. Paste this: 'Use Walker on my DERELICT project. Make the reload clip start on the frame the reload "
     "starts. Before you change anything, predict the two clocks test's result at sixty and thirty frames a second, "
     "then run it.' My prediction: zero ticks apart. If it isn't, find out why. Liam, in for Bear.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "type-on",
      "remotion": {"pattern": "ClaudeComposerAsk", "props": {
          "greeting": "Your turn.", "topic": "GODOT · ANIMATION", "segment": "DERELICT",
          "command": "Use Walker on my DERELICT project. Make the pistol reload clip advance on the same tick the "
                     "reload starts. Before changing anything, predict test_two_clocks.gd's largest disagreement at "
                     "60 and 30 fps, then run it and the edge test.",
          "runningText": "paste this into Claude…", "folderLabel": "@NikBearBrown", "modelLabel": "Claude",
          "effortLabel": "High", "output": ["One change.", "One prediction.", "Two tests to check it."],
          "animateTyping": True}}})

beat("B20", "OUTRO", "Liam, in for Bear.",
     {"type": "GRAPHIC", "class": "SHOW", "source": "remotion", "motion": "mascot-title",
      "remotion": {"pattern": "ClaudeTitleOutro", "props": {"title": TITLE, "slug": SLUG}}},
     audio_policy="silence", estimated_duration_s=7.0,
     role_note="Locked outro: @NikBearBrown, slug-seeded mascot, stock jingle only; no narration or game audio.")

sheet = {"metadata": {
    "title": TITLE, "slug": SLUG, "topic": "GODOT · ANIMATION", "kind": "gamedev", "mode": "walker",
    "brand": "claude-liam", "register": "Teardown", "engine": "kokoro", "voice": "am_onyx", "voice_kokoro": "am_onyx",
    "palette": "claude", "style_preset": "claude", "ground": "#FAF9F5", "aspect_ratio": "16:9", "fit": "pad",
    "captions": False, "greeting": "Kamusta, Liam",
    "greeting_note": "hello lexicon: Kamusta (Filipino); previous reels used Ahoj, Kia ora, Jambo, Bula, Hej.",
    "persona": "Liam (in for Bear)", "presenter": "Liam (in for Bear)", "in_for_bear": True,
    "game": PROJECT, "game_code_revision": "0d8710e",
    "note": "godot-gamedev walker film, Assignment 7, built by Claude Code. Captures: captures/routes/film_capture.gd "
            "(keyplay, reloadplay) and the repo's fixture strips. No game change, paid call, upload or publication."},
    "beats": beats}

files = {}


def assign(component, *paths):
    for p in paths:
        files.setdefault(p, []).append(component)


COMPONENTS = [
    ("keycard_spin", "Clip 1, the cycle: Sprite2D KeycardIcon + AnimationPlayer frame track, keycard_spin.tres "
     "(8 keys at k/12, discrete, LOOP_LINEAR), the generated 8-cell sheet; its read-back and preview fixtures.",
     ["B02", "B03", "B04", "B05"],
     ["animations/keycard_spin.tres", "game3d/keycard_icon.tscn", "art/keycard_sheet.png", "art/keycard_sheet.png.import",
      "tests/test_keycard_spin_readback.gd", "tests/anim_readback_lib.gd", "previews/keycard_spin_preview.tscn",
      "previews/keycard_spin_preview_dark.tscn"]),
    ("pistol_reload", "Clip 2, the committing action: Node2D cutout rig (Body/Slide/Mag, Polygon2D parts, RESET), "
     "pistol_reload.tres keyed from the phase table (24 fps, 1.25 s, LOOP_NONE); read-back, edge test, previews.",
     ["B02", "B06", "B07", "B14"],
     ["animations/pistol_reload.tres", "game3d/pistol_rig.tscn", "tests/test_pistol_reload_readback.gd",
      "tests/test_pistol_reload_edges.gd", "previews/hud_anim_preview.gd", "previews/pistol_reload_preview.tscn",
      "previews/pistol_reload_preview_light.tscn"]),
    ("hud_anim_authority", "HudAnim, the one authority: two state tables, signal handlers, play/stop/RESET; "
     "attached in game.gd; the structure and state tests.", ["B08", "B09", "B10", "B11"],
     ["game3d/hud_anim.gd", "game3d/game.gd", "tests/test_hud_anim_structure.gd", "tests/test_hud_anim_state.gd"]),
    ("game_clock", "The player's reload state machine (unchanged): _reload_left on the process tick, the fire lock, "
     "reload_changed/died; the pins taken before wiring and the two-clocks measurement.", ["B12", "B13", "B15"],
     ["game3d/player.gd", "tests/test_pins_player.gd", "tests/test_two_clocks.gd"]),
    ("hud", "The HUD (unchanged in A7): PROCESS_MODE_ALWAYS, the keycard label HudAnim reads.", ["B08"],
     ["game3d/hud.gd"]),
]
for cid, _, _, paths in COMPONENTS:
    assign(cid, *paths)

inventory = sorted(p.relative_to(GAME).as_posix() for p in GAME.rglob("*")
                   if p.is_file() and not any(x in (".godot", ".git") for x in p.relative_to(GAME).parts)
                   and p.suffix != ".uid")
SPECIAL = {
    "project.godot": "project config, unchanged by A7 (window 1280x720; renderer default Forward+; input map R/fire/Escape)",
}


def reason(p):
    if p in SPECIAL:
        return SPECIAL[p]
    if p.startswith("game3d/") or p.startswith("assets/3d/characters"):
        return "3D game code/asset unchanged by A7 (A2 redo / A5); not part of the animation work"
    if p.startswith("tests/"):
        return "earlier test suite, unchanged by A7; its baseline counts are in TEST-REPORT.md"
    if p.startswith("effects/") or p.startswith("previews/"):
        return "A6 particle effect or its preview fixture, unchanged by A7"
    if p.startswith("shaders/") or p.startswith("materials/") or p.startswith("textures/") or p.startswith("scenes/"):
        return "A5 shader/material work, unchanged by A7 (godot/shaders/ A5 files never edited)"
    if p.startswith("tools/"):
        return "earlier capture/dump tool (A5/A6), unchanged by A7"
    if p.startswith("assets/3d/"):
        return "A3 asset, unchanged by A7"
    return "2D slice or shared asset from A2, unchanged by A7"


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
