"""Step 1 media: CELEBRATE trace files, per-beat clip trims, test logs, ledger.

  python make_media.py SCRATCH_DIR
"""
import hashlib, json, re, shutil, subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

GODOT = r"C:\Users\sarth\GotDot\Godot_v4.7.2-stable_win64.exe"
ROUTES = Path(__file__).resolve().parent
FILM = ROUTES.parents[1]
REPO = FILM.parents[1]
CAP, MEDIA = FILM / "captures", FILM / "media"
TRACE, LOGS = MEDIA / "trace", MEDIA / "logs"
SCRATCH = Path(sys.argv[1])
DOWNLOADS = Path(r"C:\Users\sarth\Downloads")
font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 22)


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def git_head():
    return subprocess.run(["git", "-C", str(REPO), "rev-parse", "--short", "HEAD"],
                          capture_output=True, text=True).stdout.strip()


ledger = {"schema": "derelict-film-media-v1", "repo_head_at_build": git_head(),
          "game_code_revision": "f88f58d", "captures": [], "media": []}

# --- captures ------------------------------------------------------------------
for name in ["RUN_A_clear", "RUN_B_grab", "RUN_C_mute"]:
    ledger["captures"].append({
        "id": name, "raw": f"captures/{name}.avi", "raw_sha256": sha(CAP / f"{name}.avi"),
        "mp4": f"captures/{name}.mp4", "mp4_sha256": sha(CAP / f"{name}.mp4"),
        "route_log": f"captures/{name}.route.log",
        "method": "Godot 4.7.2 Movie Maker (--write-movie --fixed-fps 30), input-only route "
                  "captures/routes/route.gd; MJPEG+PCM 48 kHz -> H.264 crf12 + AAC 256k"})

# --- per-beat trims: whole actions, original timing, frame-accurate re-encode ----
TRIMS = {  # beat: (capture, start_s, end_s, what the interval contains)
    "B07": ("RUN_A_clear", 1.50, 2.80, "aim at zombie, ready cue, fire, follow-through"),
    # Starts 0.27 s before contact so "Contact." lands on it (step 3 timing check).
    "B09": ("RUN_B_grab", 4.00, 7.30, "contact, HURT+arrow, GRABBED, RECOVER, walk away"),
    "B11": ("RUN_A_clear", 2.10, 3.70, "shot lands, hit flash, ZOMBIE-DOWN"),
    "B12": ("RUN_A_clear", 2.00, 6.00, "AUDIBLE BEAT: shot, collapse SFX, music bed (no narration)"),
    "B14": ("RUN_C_mute", 0.50, 7.60, "M mutes music, N mutes SFX, silent kill, unmute, audible shot"),
    "B21": ("RUN_A_clear", 9.00, 13.80, "final approach, CHAR-CELEBRATE, SFX-CLEAR, music fade to silence"),
}
# Raw action trims; conform_clips.py builds the final media/Bxx.mp4 from these.
(MEDIA / "action").mkdir(exist_ok=True)
for beat, (cap, a, b, what) in TRIMS.items():
    out = MEDIA / "action" / f"{beat}.mp4"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(CAP / f"{cap}.mp4"), "-ss", f"{a:.3f}",
                    "-to", f"{b:.3f}", "-c:v", "libx264", "-preset", "medium", "-crf", "12",
                    "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "256k", str(out)], check=True)
    dur = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                                "-of", "csv=p=0", str(out)], capture_output=True, text=True).stdout)
    ledger["media"].append({"path": f"media/action/{beat}.mp4", "sha256": sha(out), "beat": beat,
                            "source": cap, "interval_s": [a, b], "duration_s": round(dur, 3),
                            "contains": what, "retimed": False})

# --- CELEBRATE trace ---------------------------------------------------------------
trace_files = {
    "storyboard_sheet.svg": REPO / "design/storyboard/sheet.svg",
    "character_sheet.svg": REPO / "design/character/sheet.svg",
    "celebrate_attempt1_rejected_thumb.jpg": REPO / "design/character/rejected/celebrate-attempt1-blood-dropped-gun.jpg",
    "celebrate_raw_greenscreen.jpg": DOWNLOADS / "Gemini_Generated_Image_enj39menj39menj3.jpg",
    "celebrate_keyed_master.png": REPO / "design/character/keyed/char_celebrate.png",
    "celebrate_game_0p12.png": REPO / "godot/art/char_celebrate.png",
}
for dst, src in trace_files.items():
    shutil.copy2(src, TRACE / dst)
    rel = str(src.relative_to(REPO)) if REPO in src.parents else f"Downloads/{src.name} (original Gemini output)"
    ledger["media"].append({"path": f"media/trace/{dst}", "sha256": sha(TRACE / dst), "beat": "B17/B19",
                            "source": rel.replace("\\", "/")})

src_md = (REPO / "SOURCES.md").read_text(encoding="utf-8").splitlines()
rows = [(i + 1, l) for i, l in enumerate(src_md) if "CHAR-CELEBRATE" in l]
(TRACE / "celebrate_prompts.txt").write_text(
    f"SOURCES.md sha256 {sha(REPO / 'SOURCES.md')}\n" + "\n".join(f"L{n}: {l}" for n, l in rows) + "\n",
    encoding="utf-8")
ledger["media"].append({"path": "media/trace/celebrate_prompts.txt", "sha256": sha(TRACE / "celebrate_prompts.txt"),
                        "beat": "B17", "source": f"SOURCES.md lines {[n for n, _ in rows]}"})

# B19: raw -> keyed (on magenta) -> game PNG (1x and 4x nearest)
raw = Image.open(TRACE / "celebrate_raw_greenscreen.jpg").convert("RGBA")
keyed = Image.open(TRACE / "celebrate_keyed_master.png")
game = Image.open(TRACE / "celebrate_game_0p12.png")
# Native 3840x2160 card (shared style in cards.py): raw and keyed downscaled from
# 1408x768; the 169x92 game sprite at 6x nearest so its real pixels stay visible.
from cards import card, footer, S, INK, MUTED, LEFT, CONTENT_W
img, d = card("Raw → keyed → game sprite.")
colw = (CONTENT_W - 2 * 90) // 3  # three columns inside title-safe
panels = [("Raw Gemini output", "solid green, as downloaded", raw.convert("RGB").resize((colw, round(768 * colw / 1408)), Image.LANCZOS)),
          ("chroma_key.py → real alpha", "shown on magenta: any leftover green would show",
           Image.alpha_composite(Image.new("RGBA", keyed.size, (255, 0, 255, 255)), keyed).convert("RGB")
           .resize((colw, round(768 * colw / 1408)), Image.LANCZOS)),
          (f"--scale 0.12 → {game.width}×{game.height}", "the in-game sprite, 6× nearest-neighbour",
           Image.alpha_composite(Image.new("RGBA", game.size, (58, 60, 59, 255)), game).convert("RGB")
           .resize((game.width * 6, game.height * 6), Image.NEAREST))]
for i, (head, sub, p) in enumerate(panels):
    x = LEFT + i * (colw + 90)
    d.text((x, 420), head, font=S(66), fill=INK)
    d.text((x, 520), sub, font=S(46), fill=MUTED)
    img.paste(p, (x + (colw - p.width) // 2, 640))
    if i < 2:
        d.text((x + colw + 12, 640 + 260), "→", font=S(90), fill=MUTED)
footer(d, "media/trace/: celebrate_raw_greenscreen.jpg · celebrate_keyed_master.png · celebrate_game_0p12.png (pixels unedited)")
img.save(MEDIA / "B19.png")
ledger["media"].append({"path": "media/B19.png", "sha256": sha(MEDIA / "B19.png"), "beat": "B19",
                        "source": "composed from media/trace/ raw, keyed master and game PNG (no edits to pixels)"})

# --- B05 / B16 stills (made by make_stills.py) -----------------------------------
for p, beat, src in [("B05.png", "B05", "isolated copies: ART paths blanked vs working tree (== f88f58d game code)"),
                     ("B16_after_mirror_tilt.png", "B16", "facing_grid_c.gd on isolated copy of working tree (6 facing checks PASS)"),
                     ("B16_before_7fc6a99.png", "B16", "facing_grid_free.gd on git archive of 7fc6a99 (free rotation, rotated art)")]:
    ledger["media"].append({"path": f"media/{p}", "sha256": sha(MEDIA / p), "beat": beat, "source": src})

# --- B23 test logs on isolated copies ------------------------------------------------
def test_log(project, out):
    r = subprocess.run([GODOT, "--headless", "--path", str(project), "res://tests/trigger_count_test.tscn"],
                       capture_output=True, text=True, encoding="utf-8", errors="replace")
    text = f"$ godot --headless --path godot res://tests/trigger_count_test.tscn\n{r.stdout.strip()}\n[exit code {r.returncode}]\n"
    out.write_text(text, encoding="utf-8")
    return r.returncode

clean = SCRATCH / "iso_real"
code = test_log(clean, LOGS / "trigger_count_pass.log")
broken = SCRATCH / "iso_guards_broken"
if broken.exists():
    # The imported .godot cache has paths past MAX_PATH; use the \\?\ prefix,
    # and fail loudly rather than silently leaving a stale copy behind.
    shutil.rmtree("\\\\?\\" + str(broken.resolve()))
# No .godot cache: its long filenames exceed Windows MAX_PATH; re-import instead.
shutil.copytree(clean, broken, ignore=shutil.ignore_patterns(".godot"))
subprocess.run([GODOT, "--headless", "--path", str(broken), "--import"], capture_output=True)
MUTS = {"scenes/player.gd": [("if _fire_requested and _state_time >= aim_windup:",
                              'if (_fire_requested or Input.is_action_pressed("fire")) and _state_time >= aim_windup:'),
                             ("if _invuln_left > 0.0 or state in [State.HURT, State.GRABBED_FAIL, State.RECOVER, State.CELEBRATE]:",
                              "if state == State.CELEBRATE:")],
        "scenes/zombie.gd": [("\tif state == State.DOWN or _shot:\n\t\treturn\n\t_shot = true", "\t_shot = true")],
        "scenes/exit_marker.gd": [("if _cleared or not body.has_method", "if not body.has_method")]}
for f, reps in MUTS.items():
    t = (broken / f).read_text(encoding="utf-8")
    for old, new in reps:
        assert t.count(old) == 1, (f, old)
        t = t.replace(old, new)
    (broken / f).write_text(t, encoding="utf-8")
code_b = test_log(broken, LOGS / "trigger_count_guards_broken.log")
for p, beat, src in [("logs/trigger_count_pass.log", "B23", f"isolated copy of working tree, exit {code}"),
                     ("logs/trigger_count_guards_broken.log", "B23",
                      f"isolated copy with 4 anti-double-trigger guards removed (see captures/routes/make_media.py), exit {code_b}")]:
    ledger["media"].append({"path": f"media/{p}", "sha256": sha(MEDIA / p), "beat": beat, "source": src})

# --- composites (B16 before|after, B23 logs) and trace cards (B17, B18) ----------------
subprocess.run([sys.executable, str(ROUTES / "make_composites.py")], check=True)
subprocess.run([sys.executable, str(ROUTES / "make_trace_cards.py")], check=True)
for p, beat, src in [("B16.png", "B16", "make_composites.py: B16_before_7fc6a99.png | B16_after_mirror_tilt.png, labelled, pixels unedited"),
                     ("B23.png", "B23", "make_composites.py: logs/trigger_count_pass.log | logs/trigger_count_guards_broken.log, verbatim text"),
                     ("B17.png", "B17", "make_trace_cards.py: panel 7 + pose 10 crops, rejected thumb, raw output; prompts from SOURCES.md L27"),
                     ("B18.png", "B18", "make_trace_cards.py: tools/chroma_key.py lines 25-38 verbatim, numbered 25-38"),
                     ("trace/storyboard_sheet.png", "B17", "design/storyboard/sheet.svg rasterised by chrome-headless-shell 1500x760"),
                     ("trace/character_sheet.png", "B17", "design/character/sheet.svg rasterised by chrome-headless-shell 1540x700")]:
    ledger["media"].append({"path": f"media/{p}", "sha256": sha(MEDIA / p), "beat": beat, "source": src})

(FILM / "MEDIA-LEDGER.json").write_text(json.dumps(ledger, indent=2), encoding="utf-8")
print(f"test exit codes: clean={code} guards_broken={code_b}")
print(f"ledger: {len(ledger['captures'])} captures, {len(ledger['media'])} media files")
for m in ledger["media"]:
    print(f"  {m['path']:48s} {m['sha256'][:12]}  {m.get('duration_s', '')}")
