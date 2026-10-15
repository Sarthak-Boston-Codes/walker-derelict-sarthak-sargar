"""The A3 film's 3840x2160 stills (shared card style, cards.py). Every image on
a card is a real file, pasted unaltered apart from scaling/cropping (crops are
labelled); every text block is quoted from a named source.

  python make_cards.py          -> media/Bxx.png

  B04  author's Blender screenshot + the six BLENDER-NOTES.md parts
  B05  crate: prompt -> get_scene_info -> MCP look
  B06  colour fix: before / after + the conversion code (session log)
  B07  barrel   B08  medkit (first build)
  B09  GLB inspection log
  B13  test PASS log     B16  hand-edit FAIL log (demonstration)
  B14  hand-edit staged reconstruction (before / after)
  B18  camera + cross: b74d239 vs HEAD, 4K captures + 3x crops
  B20  what Claude got wrong (text)
"""
from pathlib import Path
from PIL import Image, ImageDraw
from cards import card, footer, F, M, S, W, H, LEFT, RIGHT, CONTENT_W, INK, PAGE, ACCENT, MUTED

ROUTES = Path(__file__).resolve().parent
FILM = ROUTES.parents[1]
REPO = FILM.parents[1]
MEDIA = FILM / "media"
STILLS = REPO / "youtube" / "claude-liam-derelict-gamedev" / "media" / "a3-stills"
SESSION = "Claude Code session, 2026-10-15"
TOP_Y, BOTTOM_Y = 420, 1900  # content band between the title and the footer


def fit(img, w, h):
    s = min(w / img.width, h / img.height)
    return img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)


def paste(img, d, im, x, y, w, h, caption=None, border=True):
    p = fit(im.convert("RGB"), w, h)
    px, py = x + (w - p.width) // 2, y
    img.paste(p, (px, py))
    if border:
        d.rectangle([px, py, px + p.width, py + p.height], outline=INK, width=4)
    if caption:
        d.text((px, py + p.height + 24), caption, font=S(44), fill=MUTED)
    return px, py, p.width, p.height


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


def code(d, x, y, text, font, fill=INK, gap=1.35):
    """Lines drawn as-is: indentation kept, never re-wrapped (verbatim code/output)."""
    for line in text.split("\n"):
        d.text((x, y), line, font=font, fill=fill)
        y += round(font.size * gap)
    return y


def heading(d, x, y, text):
    d.text((x, y), text, font=S(52), fill=ACCENT)
    return y + 84


def save(img, bid):
    MEDIA.mkdir(parents=True, exist_ok=True)
    img.save(MEDIA / f"{bid}.png")
    print(bid, img.size)


def log_text(name, skip=("#",)):
    return [l for l in (FILM / "logs" / name).read_text(encoding="utf-8").splitlines() if not l.startswith(skip)]


def log_card(bid, title, name, foot, highlight=None, note=None):
    img, d = card(title)
    lines = log_text(name)
    font = M(54)
    y = TOP_Y + 40
    d.rectangle([LEFT, TOP_Y, RIGHT, TOP_Y + 80 + len(lines) * 92], fill=(244, 242, 236), outline=INK, width=3)
    for l in lines:
        hot = highlight and highlight in l
        if hot:
            d.rectangle([LEFT + 10, y - 12, RIGHT - 10, y + 72], fill=(250, 226, 214))
        d.text((LEFT + 40, y), l, font=font, fill=ACCENT if hot else INK)
        y += 92
    if note:
        block(d, LEFT, y + 120, note, F(70), CONTENT_W)
    footer(d, foot)
    save(img, bid)


# --- B04: the author's own Blender session, six parts ---------------------------------
img, d = card("Six parts of Blender.")
shot = Image.open(REPO / "design" / "blender" / "my_session.png")
x, y, w, h = paste(img, d, shot, LEFT, TOP_Y, 2420, 1380, "Author's own screenshot · design/blender/my_session.png")
k = w / shot.width
MARKS = [(1, "3D viewport", (560, 720)), (2, "Toolbar", (37, 290)), (3, "Outliner", (1700, 158)),
         (4, "Properties editor", (1720, 470)), (5, "Sidebar (N panel)", (1395, 300)), (6, "Mode selector", (128, 77))]
for n, _, (sx, sy) in MARKS:
    cx, cy = x + round(sx * k), y + round(sy * k)
    d.ellipse([cx - 40, cy - 40, cx + 40, cy + 40], fill=ACCENT, outline=PAGE, width=6)
    d.text((cx - d.textlength(str(n), font=S(52)) / 2, cy - 36), str(n), font=S(52), fill=PAGE)
ly = TOP_Y + 20
for n, name, _ in MARKS:
    d.ellipse([2780, ly + 4, 2852, ly + 76], fill=ACCENT)
    d.text((2816 - d.textlength(str(n), font=S(48)) / 2, ly + 6), str(n), font=S(48), fill=PAGE)
    d.text((2890, ly), name, font=F(76), fill=INK)
    ly += 210
footer(d, "Part names from BLENDER-NOTES.md, the author's own words")
save(img, "B04")

# --- B05: crate, prompt -> build -> check ---------------------------------------------
img, d = card("Prompt, build, check.")
col = (CONTENT_W - 120) // 3
x0, x1, x2 = LEFT, LEFT + col + 60, LEFT + 2 * (col + 60)
heading(d, x0, TOP_Y, "1 · The prompt (author)")
block(d, x0, TOP_Y + 100,
      "“Task: build only this asset: supply crate, exactly as the brief specifies (0.5x0.5x0.5m, origin at "
      "base centre, wood-brown body with dark-gray straps, ≤100 triangles). Start from an empty scene with "
      "metric units; Blender is Z-up.”", F(62), col)
heading(d, x1, TOP_Y, "2 · get_scene_info after the join")
block(d, x1, TOP_Y + 100,
      "SupplyCrate | mesh\nat (0.0, 0.0, 0.0)\nrot (0, 0, 0)\nscale (1.0, 1.0, 1.0)\nsize 0.5x0.5x0.5\non ground\n"
      "18 quads · 36 triangles\n0 non-manifold", M(54), col)
heading(d, x2, TOP_Y, "3 · MCP look, Material Preview")
paste(img, d, Image.open(STILLS / "blender_01_crate_before_srgb_fix.png"), x2, TOP_Y + 100, col, 1050,
      "a3-stills/blender_01")
footer(d, f"Prompt and tool output quoted from the {SESSION}")
save(img, "B05")

# --- B06: colour fix ------------------------------------------------------------------
img, d = card("Same numbers, wrong space.")
paste(img, d, Image.open(STILLS / "blender_01_crate_before_srgb_fix.png"), LEFT, TOP_Y, 820, 820,
      "Before: entered as linear")
paste(img, d, Image.open(STILLS / "blender_02_crate_after_srgb_fix.png"), LEFT + 880, TOP_Y, 820, 820,
      "After: converted sRGB → linear")
cx = LEFT + 1780
heading(d, LEFT, 1350, "The conversion, as sent to Blender")
d.rectangle([LEFT, 1440, RIGHT, 1720], fill=(244, 242, 236), outline=INK, width=3)
code(d, LEFT + 40, 1480, "def srgb_to_linear(c):\n"
     "    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4", M(64))
heading(d, cx, TOP_Y, "Blender's output")
code(d, cx, TOP_Y + 100, "M_Crate_Wood sRGB (0.4, 0.24, 0.12)\n  -> linear (0.1329, 0.047, 0.0134)\n"
     "M_Crate_Strap sRGB (0.08, 0.08, 0.08)\n  -> linear (0.0072, 0.0072, 0.0072)\n"
     "round-trip back to sRGB: exact", M(50))
block(d, cx, TOP_Y + 620, "The brief's numbers are colour-picker values. Base Color expects linear light, so "
      "the same three numbers read far lighter.", F(62), RIGHT - cx)
footer(d, f"Code and output quoted from the {SESSION} (not a repo file) · a3-stills/blender_01, _02")
save(img, "B06")

# --- B07 / B08: barrel, medkit --------------------------------------------------------
for bid, title, still, facts, src in [
    ("B07", "Rusted barrel.", "blender_03_barrel.png",
     ["12 sides (brief: 8–12)", "0.6 m wide × 0.9 m tall", "Origin at the base centre", "44 / 200 triangles",
      "Rust sRGB (0.52, 0.28, 0.15)", "Colour: Claude's pick,\napproved by the author"], "a3-stills/blender_03"),
    ("B08", "Medkit, first build.", "blender_04_medkit_original_cross.png",
     ["Case 0.30 × 0.20 × 0.12 m", "Lid inset 1 cm per side", "Cross 0.12 × 0.04 × 0.01 m", "0.3 × 0.2 × 0.15 m overall",
      "48 / 150 triangles", "Cream + red: Claude's pick,\napproved by the author"], "a3-stills/blender_04")]:
    img, d = card(title)
    paste(img, d, Image.open(STILLS / still), LEFT, TOP_Y, 1900, 1380, src + " · MCP look, Material Preview")
    fy = TOP_Y + 20
    for f in facts:
        fy = block(d, 2300, fy, f, F(76), RIGHT - 2300) + 50
    footer(d, "Values: get_scene_info and CHANGE-BRIEF.md Revisions, 2026-10-15")
    save(img, bid)

# --- B09: GLB inspection --------------------------------------------------------------
img, d = card("What the files actually say.")
lines = log_text("glb_inspect.log", skip=("#", "$"))
y = TOP_Y
for l in lines:
    l = l.replace("metallic=0.30000001192092896", "metallic=0.3")
    hot = l.startswith("==")
    d.text((LEFT, y), l.strip(), font=M(44 if not hot else 50), fill=ACCENT if hot else INK)
    y += 84 if not hot else 92
footer(d, "logs/glb_inspect.log · python inspect_glb.py on godot/assets/3d/*.glb (metallic 0.30000001 shown as 0.3)")
save(img, "B09")

# --- B13 / B16: test logs -------------------------------------------------------------
log_card("B13", "All three pass.", "showcase_pass.log",
         "logs/showcase_pass.log · showcase_3d_test on an isolated copy of HEAD · exit code 0",
         note="Per asset: rotation 0, scale 1, base on the floor within 1 mm, size within 1 mm of the brief, "
              "triangles within budget. That's predicted failure cases 1 to 3.")
log_card("B16", "Demonstration: the hand-edit fails.", "showcase_handedit_fail.log",
         "DEMONSTRATION · isolated copy, medkit.glb exported at scale 1.95508 (not applied) · exit code 1",
         highlight="Medkit",
         note="The SCALE column reads 1.00: that's the instance node. The 1.955 sits on the imported mesh "
              "node, and the test checks it there. The SIZE column is where it shows.")

# --- B14: hand-edit staged reconstruction ---------------------------------------------
img, d = card("The hand-edit, staged again.")
d.rectangle([LEFT, TOP_Y - 30, RIGHT, TOP_Y + 70], fill=ACCENT)
d.text((LEFT + 30, TOP_Y - 22), "STAGED RECONSTRUCTION — not a capture of the original moment", font=S(56), fill=PAGE)
half = (CONTENT_W - 100) // 2
for i, (path, cap, crop) in enumerate([
        (REPO / "design" / "blender" / "my_session.png", "Before · my_session.png · Scale 1.000", (560, 280, 1917, 700)),
        (STILLS / "blender_07_handedit_after.png", "After · staged S-key resize · Scale 1.897", (560, 120, 1917, 700))]):
    im = Image.open(path).convert("RGB").crop(crop)
    paste(img, d, im, LEFT + i * (half + 100), TOP_Y + 130, half, 900, cap + " (cropped)")
block(d, LEFT, 1560, "The original edit, logged in FRICTIONAL.md: scale 1 → 1.95508 on every axis, location "
      "unchanged, mesh untouched. The staged value here is 1.897, so the narration uses the logged one.",
      F(66), CONTENT_W)
footer(d, "Author's screenshots · labels per a3-stills/PROVENANCE.md")
save(img, "B14")

# --- B18: camera and cross, b74d239 vs HEAD -------------------------------------------
def red_box(im):
    px = im.load()
    xs, ys = [], []
    for yy in range(0, im.height, 2):
        for xx in range(0, im.width, 2):
            r, g, b = px[xx, yy][:3]
            if r > 150 and g < 60 and b < 60:
                xs.append(xx); ys.append(yy)
    return min(xs), min(ys), max(xs), max(ys)


img, d = card("One problem, two fixes.")
half = (CONTENT_W - 100) // 2
for i, (name, cap) in enumerate([("b18_before_b74d239.png", "b74d239 · camera −20° · cross 0.12 × 0.04 m"),
                                  ("b18_after_head.png", "HEAD · camera −35° · cross 0.14 × 0.045 m")]):
    full = Image.open(FILM / "captures" / name).convert("RGB")
    x = LEFT + i * (half + 100)
    px, py, pw, ph = paste(img, d, full, x, TOP_Y, half, 700, cap)
    x0, y0, x1, y1 = red_box(full)
    cxm, cym = (x0 + x1) // 2, (y0 + y1) // 2
    cw, ch = 300, 180
    crop = full.crop((cxm - cw // 2, cym - ch // 2, cxm + cw // 2, cym + ch // 2))
    k = pw / full.width
    d.rectangle([px + (cxm - cw // 2) * k, py + (cym - ch // 2) * k, px + (cxm + cw // 2) * k,
                 py + (cym + ch // 2) * k], outline=ACCENT, width=5)
    z = crop.resize((800, 480), Image.LANCZOS)
    zx, zy = x + (half - 800) // 2, py + ph + 110
    img.paste(z, (zx, zy))
    d.rectangle([zx, zy, zx + 800, zy + 480], outline=ACCENT, width=5)
    d.text((zx, zy + 496), "Boxed area, enlarged (crop of the same capture)", font=S(44), fill=MUTED)
footer(d, "New 4K captures (3840×2160) of each revision's own scene camera · captures/b18_*.png")
save(img, "B18")

# --- B20: what Claude got wrong -------------------------------------------------------
img, d = card("What Claude got wrong.")
y = TOP_Y + 20
for head, body in [
        ("1 · The camera pointed at the sky.",
         "Its first transform was written with the rows in the wrong order. Caught and fixed before any commit, "
         "and before any passing screenshot."),
        ("2 · The cross was too small to read.",
         "Found after the showcase was first committed. Enlarging the cross alone barely helped; it took the "
         "camera too. The fix landed in its own later commit, 343a90c.")]:
    d.text((LEFT, y), head, font=F(96), fill=INK)
    y = block(d, LEFT, y + 150, body, F(70), CONTENT_W, fill=MUTED) + 140
footer(d, "TEST-REPORT.md, “What Claude got wrong” · no image of the sky-camera frame survives")
save(img, "B20")

# --- B11 / B19 frames: the 4K captures are composited onto these in conform_clips.py ----
# Video box (4K px): FRAME_BOX = (x, y, w, h); keep in sync with conform_clips.py.
FRAME_BOX = (542, 380, 2756, 1550)
for bid, title, foot in [
        ("B11", "Running in Godot.", "Godot 4.7.2 · 3840×2160 capture · the scene's own camera · media/action/B11.mp4"),
        ("B19", "Walk-around: behind and below.",
         "CAPTURE CAMERA added for the film (showcase_capture.gd), not the scene's camera · media/action/B19.mp4")]:
    img, d = card(title)
    x, y, w, h = FRAME_BOX
    d.rectangle([x - 4, y - 4, x + w + 4, y + h + 4], outline=INK, width=4)
    footer(d, foot)
    (MEDIA / "frames").mkdir(parents=True, exist_ok=True)
    img.save(MEDIA / "frames" / f"{bid}_frame.png")
    print(bid, "frame")
