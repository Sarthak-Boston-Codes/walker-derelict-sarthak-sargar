"""The A5 film's 3840x2160 stills (shared card style, cards.py, copied from the
A3 film). Every image on a card is a real capture, pasted unaltered apart from
scaling/cropping (crops are labelled). Every number is parsed from a named log
line; every code line is read from the file it names.

  python captures/routes/make_cards.py      -> media/Bxx.png

Captures: godot/tools/a5_capture.gd (MODE ammo/hint/sweep/twomat) and
captures/routes/film_capture.gd (playclip, floor), frames under
captures/frames/ (git-ignored; regenerate with those scripts).
"""
import json, re
from pathlib import Path
from PIL import Image
from cards import card, footer, F, M, S, W, H, LEFT, RIGHT, CONTENT_W, INK, PAGE, ACCENT, MUTED

ROUTES = Path(__file__).resolve().parent
FILM = ROUTES.parents[1]
REPO = FILM.parents[1]
GAME = REPO / "godot"
FRAMES = FILM / "captures" / "frames"
MEDIA = FILM / "media"
LOGS = FILM / "logs"
TOP_Y = 420
PANEL = (244, 242, 236)
HOT = (250, 226, 214)
CAP = "Godot 4.7.2 · Forward+ · 3840×2160 SubViewport capture"


def fit(img, w, h):
    s = min(w / img.width, h / img.height)
    return img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)


def paste(img, d, im, x, y, w, h, caption=None):
    p = fit(im.convert("RGB"), w, h)
    px = x + (w - p.width) // 2
    img.paste(p, (px, y))
    d.rectangle([px, y, px + p.width, y + p.height], outline=INK, width=4)
    if caption:
        d.text((px, y + p.height + 20), caption, font=S(42), fill=MUTED)
    return px, y, p.width, p.height


def wrap(d, text, font, width):
    out = []
    for para in text.split("\n"):
        line = ""
        for word in para.split(" "):
            t = (line + " " + word).strip()
            if d.textlength(t, font=font) <= width:
                line = t
            else:
                out.append(line)
                line = word
        out.append(line)
    return out


def block(d, x, y, text, font, width, fill=INK, gap=1.35):
    for line in wrap(d, text, font, width):
        d.text((x, y), line, font=font, fill=fill)
        y += round(font.size * gap)
    return y


def code(d, x, y, lines, font, gap=1.4, hot=()):
    for i, line in enumerate(lines):
        if i in hot:
            d.rectangle([x - 16, y - 8, x + d.textlength(line, font=font) + 16, y + font.size + 8], fill=HOT)
        d.text((x, y), line, font=font, fill=ACCENT if i in hot else INK)
        y += round(font.size * gap)
    return y


def save(img, bid):
    MEDIA.mkdir(parents=True, exist_ok=True)
    img.save(MEDIA / f"{bid}.png")
    print(bid, img.size)


def measures(log):
    out = []
    for l in (LOGS / log).read_text(encoding="utf-8").splitlines():
        if l.startswith("MEASURE "):
            out.append(json.loads(l[8:]))
    return out


def src_lines(path, a, b):
    return (GAME / path).read_text(encoding="utf-8").splitlines()[a - 1:b]


def log_lines(log, keep):
    return [l for l in (LOGS / log).read_text(encoding="utf-8").splitlines() if keep(l)]


# --- B02: the game, the state, the textured object --------------------------------------
img, d = card("Low ammo, in the game.")
w = (CONTENT_W - 80) // 2
paste(img, d, Image.open(FRAMES / "playclip" / "f00000.jpg"), LEFT, TOP_Y, w, 1200,
      "Frame 0: mag 15 · low_ammo 0.0000")
paste(img, d, Image.open(FRAMES / "playclip" / "f00090.jpg"), LEFT + w + 80, TOP_Y, w, 1200,
      "Frame 90: mag 5 · low_ammo 1.0000")
block(d, LEFT, 1530, "State: player.mag <= 5 (player.gd:37, reported by ammo_changed, player.gd:9). Object: the HUD "
      "ammo label (hud.gd:88). Textured object: the factory floor.", F(64), CONTENT_W)
footer(d, "SCRIPTED PLAY, real fire input · " + CAP + " · film_capture.gd playclip · per-frame values from logs/film_capture_playclip.log")
save(img, "B02")

# --- B05: four controlled values -------------------------------------------------------------
img, d = card("Four controlled values.")
px = {m["low_ammo"]: m for m in measures("capture_ammo_fixed.log") if m["what"] == "ammo_pixels"}
PRED = {0.0: "(242, 193, 78)", 0.5: "(248–249, 120–121, 63)", 1.0: "(255, 48, 48)", 2.0: "not predicted (hint_range question)"}
cw, ch = 1640, 420
for i, v in enumerate([0.0, 0.5, 1.0, 2.0]):
    x = LEFT + (i % 2) * (cw + 120)
    y = TOP_Y + (i // 2) * 760
    paste(img, d, Image.open(FRAMES / "ammo_fixed" / f"ammo_{v:.1f}_label.png"), x, y, cw, ch)
    a, b = tuple(px[v]["A_rgb"]), tuple(px[v]["B_rgb"])
    d.text((x, y + ch + 30), f"low_ammo = {v}", font=S(56), fill=ACCENT)
    d.text((x, y + ch + 110), f"A {a}  ·  B {b}", font=M(50), fill=INK)
    d.text((x, y + ch + 180), f"predicted {PRED[v]}", font=S(44), fill=MUTED)
footer(d, "Driver paused; low_ammo set by the capture script · label crops · " + CAP + " · logs/capture_ammo_fixed.log")
save(img, "B05")

# --- B08: what the timing test proved ---------------------------------------------------------
img, d = card("Same game time at every frame rate.")
RULES = [("R1/R3 fade-in", "R1 fade-in 0 → 1", "0.25"), ("R2/R3 fade-out", "R2 fade-out 1 → 0", "0.50"),
         ("R4 extend", "R4 retrigger, extend", "(1 − v) × 0.25"), ("R5 at time_scale", "R5 time_scale 0.5 (real s)", "0.50"),
         ("R6 fade-in", "R6 paused, then resumed", "0.25"), ("R7 from", "R7 ends mid fade-in *", "v × 0.5")]
got = {}
for fps in (30, 60, 144):
    for l in log_lines(f"final_low_ammo_test_{fps}fps.log", lambda l: l.startswith("PASS ")):
        for key, _, _ in RULES:
            if l[5:].startswith(key):
                t = re.search(r"(?:took|in) ([0-9.]+) s", l)
                got[(key, fps)] = t.group(1) if t else "?"
    got[("total", fps)] = log_lines(f"final_low_ammo_test_{fps}fps.log", lambda l: l.startswith(("PASS:", "FAIL:")))[0]
cols = [LEFT, LEFT + 1250, LEFT + 1950, LEFT + 2450, LEFT + 2950]
y = TOP_Y + 20
for x, h in zip(cols, ["rule", "want (s)", "30 fps", "60 fps", "144 fps"]):
    d.text((x, y), h, font=S(58), fill=ACCENT)
y += 110
for key, label, want_s in RULES:
    d.text((cols[0], y), label, font=F(66), fill=INK)
    d.text((cols[1], y + 8), want_s, font=M(56), fill=MUTED)
    for x, fps in zip(cols[2:], (30, 60, 144)):
        d.text((x, y + 8), got[(key, fps)], font=M(60), fill=INK)
    y += 125
d.text((cols[0], y + 10), "result", font=F(66), fill=INK)
for x, fps in zip(cols[2:], (30, 60, 144)):
    d.text((x, y + 18), got[("total", fps)].replace(" failure(s)", " fail"), font=M(52), fill=ACCENT)
block(d, LEFT, y + 170, "Tolerance: one frame period (1/30, 1/60, 1/144 s). Real fire and reload input; "
      "* R7 uses a test-emitted ammo_changed, because no real input can end the state inside the 0.25 s fade.",
      F(54), CONTENT_W, fill=MUTED)
footer(d, "scripts/run-test.sh low_ammo_test.gd 30 | 60 | 144 · headless · logs/final_low_ammo_test_*fps.log (35 PASS each)")
save(img, "B08")

# --- B10: hint experiment --------------------------------------------------------------------
img, d = card("Same file, two hints.")
x0, y0, pw, ph = paste(img, d, Image.open(FRAMES / "hint" / "hint_experiment.png"), LEFT, TOP_Y, 2000, 1125,
                       "hint_experiment.tscn · unshaded quads · Linear tonemap, exposure 1.0")
bands = {m["quad"]: m["bands_64_128_192"] for m in measures("capture_hint.log")}
tx = LEFT + 2120
d.text((tx, TOP_Y), "band in file → measured", font=S(52), fill=ACCENT)
y = TOP_Y + 110
for q, name, pred in [("QuadSourceColor", "source_color", [64, 128, 192]), ("QuadNoHint", "no hint", [137, 188, 225])]:
    d.text((tx, y), name, font=S(54), fill=INK)
    y += 90
    for band, m, p in zip([64, 128, 192], bands[q], pred):
        d.text((tx + 30, y), f"{band:>3} → {m[0]:>3}   (predicted {p})", font=M(50), fill=INK)
        y += 74
    y += 60
block(d, tx, y + 10, "Top: decoded from sRGB, then encoded for display: the two cancel. Bottom: raw numbers treated "
      "as linear, encoded once: brighter.", F(56), RIGHT - tx)
footer(d, CAP + " · band centres sampled by godot/tools/a5_capture.gd hint · logs/capture_hint.log")
save(img, "B10")

# --- B12: the textured floor -------------------------------------------------------------------
img, d = card("Dry floor, wet Boiler Room.")
w = (CONTENT_W - 80) // 2
paste(img, d, Image.open(FRAMES / "floor" / "floor_doorway.png"), LEFT, TOP_Y, w, 1150,
      "In game: STAGED (player placed by script at the doorway)")
paste(img, d, Image.open(FRAMES / "twomat" / "twomat_baseline.png"), LEFT + w + 80, TOP_Y, w, 1150,
      "material_lab.tscn: dry (left) · wet (right)")
block(d, LEFT, 1500, "From the game camera the wet floor is hard to tell apart; the lab, under one 45° light, shows "
      "the darker, glossier tile. Judging the in-game look is a human check still pending.", F(60), CONTENT_W)
footer(d, CAP + " · film_capture.gd floor · a5_capture.gd twomat (baseline)")
save(img, "B12")

# --- B13: interface sweep -------------------------------------------------------------------------
img, d = card("Every uniform, min to max.")
paste(img, d, Image.open(REPO / "docs" / "evidence" / "captures" / "sweep_sheet.png"), LEFT, TOP_Y - 20, 1700, 1380,
      "16 captures, dry tile varied (left tile)")
sw = {(m["uniform"], m["setting"].split("(")[0]): m for m in measures("capture_sweep.log")}
tx = LEFT + 1800
d.text((tx, TOP_Y), "mean luma of the dry tile (0–255)", font=S(48), fill=ACCENT)
y = TOP_Y + 90
for u, keys in [("albedo_tint", ["black", "white"]), ("uv_scale", ["min", "default", "max"]),
                ("roughness_scale", ["min", "default"]), ("normal_strength", ["min", "default", "max"]),
                ("wetness", ["min", "max"]), ("wet_darkening", ["min", "default", "max"])]:
    vals = "  ".join(f"{k} {sw[(u, k)]['mean_luma']}" for k in keys)
    d.text((tx, y), u, font=M(44), fill=INK)
    d.text((tx + 40, y + 60), vals, font=M(40), fill=INK)
    y += 140
d.rectangle([tx - 16, y + 10, RIGHT, y + 240], fill=HOT)
block(d, tx, y + 30, "Breaks the look: wet_darkening 1.0 at full wetness → 1.2, a black mirror. Only uv_scale 0.05 "
      "shows readable detail.", F(52), RIGHT - tx - 20, fill=ACCENT)
footer(d, "SCRIPTED SWEEP · inspected by Claude, not yet by the student · " + CAP + " · logs/capture_sweep.log")
save(img, "B13")

# --- B15: two materials, one shader ----------------------------------------------------------------
img, d = card("Two materials, one shader.")
tm = {m["step"]: m for m in measures("capture_twomat.log") if m["what"] == "twomat"}
steps = [("baseline", "baseline"), ("shader_line_edited", "one shader line edited"),
         ("dry_value_edited", "one value in dry edited"), ("dry_value_reverted", "reverted")]
cw = (CONTENT_W - 3 * 60) // 4
for i, (k, label) in enumerate(steps):
    x = LEFT + i * (cw + 60)
    paste(img, d, Image.open(FRAMES / "twomat" / f"twomat_{k}.png"), x, TOP_Y, cw, 600)
    d.text((x, TOP_Y + 500), label, font=S(48), fill=ACCENT)
    d.text((x, TOP_Y + 580), f"dry G {tm[k]['dry']['mean_rgb'][1]}", font=M(46), fill=INK)
    d.text((x, TOP_Y + 650), f"wet G {tm[k]['wet']['mean_rgb'][1]}", font=M(46), fill=INK)
block(d, LEFT, TOP_Y + 820, "Editing the shared shader's ALBEDO line changed both tiles. Editing albedo_tint on the dry "
      "material changed only dry. Each revert returned the exact baseline numbers.", F(64), CONTENT_W)
code(d, LEFT, TOP_Y + 1130, ["edited line (in memory, Shader.code):",
                              "\tALBEDO = base * (1.0 - wetness * wet_darkening) * vec3(1.0, 0.35, 0.35);"
                              .replace("\t", "    ")], M(46))
footer(d, "Edits made in memory by a5_capture.gd twomat; the files on disk were not touched · " + CAP + " · logs/capture_twomat.log")
save(img, "B15")

# --- B17: generated shader beside its equivalent -------------------------------------------------
img, d = card("Godot's shader, beside ours.")
half = (CONTENT_W - 100) // 2
d.text((LEFT, TOP_Y), "standard_generated.gdshader (written by Godot)", font=S(48), fill=ACCENT)
d.text((LEFT + half + 100, TOP_Y), "concrete_surface.gdshader", font=S(48), fill=ACCENT)
g = {n: src_lines("shaders/standard_generated.gdshader", n, n)[0].strip() for n in (7, 19, 34, 46)}
c = {n: src_lines("shaders/concrete_surface.gdshader", n, n)[0].strip() for n in (9, 13, 32, 36)}
y = TOP_Y + 110
for gn, cn, note in [(7, 9, "colour: source_color"), (34, 32, "sample albedo"),
                     (19, 13, "data: no source_color"), (46, 36, "sample normal")]:
    d.text((LEFT, y), note, font=S(40), fill=MUTED)
    block(d, LEFT, y + 56, f"{gn}  {g[gn]}", M(44), half, gap=1.3)
    block(d, LEFT + half + 100, y + 56, f"{cn}  {c[cn]}", M(44), half, gap=1.3)
    y += 250
d.rectangle([LEFT, y + 10, RIGHT, y + 230], fill=PANEL, outline=INK, width=3)
out = log_lines("dump_standard_shader.log", lambda l: l.startswith(("generated", "wrote")))
code(d, LEFT + 40, y + 40, out, M(48))
footer(d, "Engine output: windowed run of godot/tools/dump_standard_shader.gd · logs/dump_standard_shader.log")
save(img, "B17")

# --- B18: tests, mutations, limits --------------------------------------------------------------
img, d = card("Three mutations, three failures.")
rows = [
    ("(a) delete one ';' in low_ammo.gdshader", "mutation_a_semicolon_revised.log", ("SHADER ERROR", "FAIL:")),
    ("(b) rename low_ammo in the shader only", "mutation_b_rename_revised.log", ("FAIL ",)),
    ("(c) remove source_color from albedo_tex", "mutation_c_source_color.log", ("FAIL",)),
]
y = TOP_Y
for title, log, keys in rows:
    d.text((LEFT, y), title + "  →  exit 1", font=S(54), fill=ACCENT)
    y += 84
    seen = []
    for l in log_lines(log, lambda l: l.startswith(keys)):
        if l not in seen:
            seen.append(l)
    for l in seen[:4]:
        d.text((LEFT + 40, y), l[:110], font=M(46), fill=INK)
        y += 64
    y += 40
block(d, LEFT, y + 10, "Under (b) every timing rule still passed: set_shader_parameter accepts a name the shader never "
      "declared. No headless run can show colour, gloss or readability; those need eyes.", F(58), CONTENT_W)
footer(d, "scripts/run-test.sh · headless · logs/mutation_*.log")
save(img, "B18")

# --- B19: the revision shown ---------------------------------------------------------------------
img, d = card("The mistake a capture caught.")
w = (CONTENT_W - 80) // 2
paste(img, d, Image.open(FRAMES / "ammo" / "ammo_1.0_label.png"), LEFT, TOP_Y, w, 520,
      "Before: low_ammo 1.0 · shadow turned red (af736a7)")
paste(img, d, Image.open(FRAMES / "ammo_fixed" / "ammo_1.0_label.png"), LEFT + w + 80, TOP_Y, w, 520,
      "After: shadow stays black (a8f1bc2)")
sh = {(log, m["low_ammo"]): m["mean_rgb"] for log in ("capture_ammo.log", "capture_ammo_fixed.log")
      for m in measures(log) if m["what"] == "ammo_shadow"}
d.text((LEFT, TOP_Y + 640), f"shadow pixels at 1.0: {tuple(sh[('capture_ammo.log', 1.0)])}  →  "
       f"{tuple(sh[('capture_ammo_fixed.log', 1.0)])}", font=M(50), fill=INK)
code(d, LEFT, TOP_Y + 780, [l.replace("\t", "    ") for l in src_lines("shaders/low_ammo.gdshader", 12, 13)], M(52), hot=(0, 1))
block(d, LEFT, TOP_Y + 1010, "CHANGE-BRIEF.md revision, committed first (e434f65): “The tint is applied only where the "
      "drawn colour is not black, so the shadow keeps its colour and the glyphs are unchanged from the predictions.”",
      F(58), CONTENT_W)
footer(d, "Inspected by Claude; not yet by the student · " + CAP + " · logs/capture_ammo.log, logs/capture_ammo_fixed.log")
save(img, "B19")

# --- B20: other mistakes, uncertainty, next step ---------------------------------------------------
img, d = card("Mistakes, doubts, next step.")
y = TOP_Y
for head, text in [
    ("Caught", "The kit's normal-map check read the GL map as DirectX: its sign was reversed (1.30 vs 0.70), and it "
               "barely separated the two until the maps were downsampled to 256 px (0.33 vs 1.67). Claude Code "
               "committed that fix under the message “as copied”, then redid it as two honest commits. Its own "
               "capture script hung once: a reload press timed after the frame never registered."),
    ("Uncertain", "Every look claim here is Claude's inspection. The student's checks are pending. R7 is driven by a "
                  "test-emitted signal, because no real input can end the state inside a 0.25 s fade."),
    ("Next", "The student plays it and fills in HUMAN-CHECK-NOTES.md; a bigger uv_scale or a larger texture so the "
             "floor reads from the game camera."),
]:
    d.text((LEFT, y), head, font=S(56), fill=ACCENT)
    y = block(d, LEFT, y + 80, text, F(58), CONTENT_W) + 50
footer(d, "Sources: A5-LOG.md, TEST-REPORT.md, git log main..a5")
save(img, "B20")

# --- B21: who did what, and where it came from -------------------------------------------------------
img, d = card("Who wrote what.")
y = TOP_Y
for head, text in [
    ("Claude (chat)", "the three shaders, the colour line, the predictions and brief answers, the kit's checks."),
    ("Claude Code", "the driver, tests, materials, scenes, capture tools, documents, the shadow fix, this film."),
    ("Godot", "standard_generated.gdshader, generated from a StandardMaterial3D."),
    ("The student", "chose the state and the six design decisions by accepting Claude's defaults. Wrote no shader "
                    "code. The TA allowed AI-written work for A5 verbally, on condition the student understands it; "
                    "written confirmation is pending."),
    ("Textures", "Poly Haven · Concrete Floor Worn 001 · Dimitrios Savva, Rico Cilliers · CC0 · checked 2026-10-29."),
]:
    d.text((LEFT, y), head, font=S(56), fill=ACCENT)
    y = block(d, LEFT + 560, y + 4, text, F(58), CONTENT_W - 560) + 40
footer(d, "Sources: SOURCES.md, ATTRIBUTION.md, CHANGE-BRIEF.md")
save(img, "B21")
