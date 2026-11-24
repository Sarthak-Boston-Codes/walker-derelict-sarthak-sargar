"""Build every visual for the A8 pitch film (written by Claude Code).

  python make_pitch.py            (run from anywhere; paths are relative to this file)

Writes media/B01..B13 as .png (cards) or .mp4 (framed captures). Each beat
carries its label on screen: "real capture", "scripted capture", "fixture",
"constructed on screen" or "generated". No Remotion, no instructor name,
handle or outro. Durations come from beat_sheet.json (actual_duration_s,
written by Kokoro), so run generate_audio_kokoro.py first.

Captures are reused, never retimed: when the narration is longer than the
clip, the last frame is held and labelled HOLD.
All ink stays inside brutalist.art's title-safe area (final_frame_check.py,
x 192-3648, y 108-2052 at 4K).
"""
import json, math, subprocess
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
REPO = HERE.parent
MEDIA = HERE / "media"; MEDIA.mkdir(exist_ok=True)
WORK = HERE / "clips" / "_pitch"; WORK.mkdir(parents=True, exist_ok=True)
CAP = HERE / "captures"
FPS = 30

W, H = 3840, 2160
L, R = 230, W - 230
TOP = 150
LABEL_Y = 1945
PAGE = (22, 24, 27)
INK = (236, 232, 222)
MUTED = (150, 148, 140)
AMBER = (242, 182, 48)
RED = (226, 78, 64)
GREEN = (104, 196, 120)
PANEL = (40, 43, 48)
FONTS = Path(r"C:\Users\sarth\brutalist.art\runtime\fonts")
_serif = next(FONTS.rglob("EBGaramond-Regular.ttf"))
_sans = next(FONTS.rglob("Inter*.ttf"))
F = lambda s: ImageFont.truetype(str(_serif), s)
S = lambda s: ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", s)
SB = lambda s: ImageFont.truetype("C:/Windows/Fonts/segoeuib.ttf", s)
M = lambda s: ImageFont.truetype("C:/Windows/Fonts/consola.ttf", s)


def card(title=None):
    img = Image.new("RGB", (W, H), PAGE)
    d = ImageDraw.Draw(img)
    if title:
        d.text((L, TOP), title, font=F(120), fill=INK)
    return img, d


def label(d, text, right=None):
    d.text((L, LABEL_Y), text, font=S(46), fill=MUTED)
    if right:
        d.text((R - d.textlength(right, font=S(46)), LABEL_Y), right, font=S(46), fill=MUTED)


def wrap(d, text, font, width):
    words, lines, cur = text.split(), [], ""
    for w in words:
        t = (cur + " " + w).strip()
        if d.textlength(t, font=font) <= width:
            cur = t
        else:
            lines.append(cur); cur = w
    if cur:
        lines.append(cur)
    return lines


def para(d, xy, text, font, width, fill=INK, gap=1.25):
    x, y = xy
    for line in wrap(d, text, font, width):
        d.text((x, y), line, font=font, fill=fill)
        y += int(font.size * gap)
    return y


def box(d, x0, y0, x1, y1, head, body, colour, head_size=78, body_size=58):
    d.rounded_rectangle((x0, y0, x1, y1), radius=36, fill=PANEL, outline=colour, width=8)
    d.text((x0 + 60, y0 + 50), head, font=SB(head_size), fill=colour)
    y = y0 + 60 + int(head_size * 1.5)
    for item in body:
        y = para(d, (x0 + 60, y), item, S(body_size), x1 - x0 - 120) + 24
    return y


def player(d, cx, cy, r=60):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(90, 140, 200), outline=INK, width=6)


def zombie(d, cx, cy, r=52):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(110, 150, 100), outline=(40, 60, 40), width=6)


def cone(img, apex, angle_deg, length, spread, colour=(255, 236, 170), alpha=90):
    over = Image.new("RGBA", img.size, (0, 0, 0, 0))
    od = ImageDraw.Draw(over)
    ax, ay = apex
    a0, a1 = math.radians(angle_deg - spread), math.radians(angle_deg + spread)
    pts = [apex] + [(ax + length * math.cos(a0 + (a1 - a0) * i / 20),
                     ay + length * math.sin(a0 + (a1 - a0) * i / 20)) for i in range(21)]
    od.polygon(pts, fill=colour + (alpha,))
    img.paste(Image.alpha_composite(img.convert("RGBA"), over).convert("RGB"))


def burst(d, cx, cy, r=46):
    for k in range(10):
        a = k * math.pi / 5
        d.line((cx, cy, cx + r * 1.8 * math.cos(a), cy + r * 1.8 * math.sin(a)), fill=AMBER, width=8)
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=(255, 240, 210))


def save(img, bid):
    img.save(MEDIA / f"{bid}.png")
    print("card", bid)


def text_png(path, text, size=56, fg=PAGE, bg=AMBER):
    f = SB(size)
    tmp = ImageDraw.Draw(Image.new("RGB", (10, 10)))
    w = int(tmp.textlength(text, font=f)) + 60
    im = Image.new("RGB", (w, int(size * 1.7)), bg)
    ImageDraw.Draw(im).text((30, int(size * 0.25)), text, font=f, fill=fg)
    im.save(path)
    return path


def dur(p):
    return float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration",
                                 "-of", "csv=p=0", str(p)], capture_output=True, text=True).stdout)


sheet = json.loads((HERE / "beat_sheet.json").read_text(encoding="utf-8"))
beat = {b["beat_id"]: b for b in sheet["beats"]}


def framed_video(bid, bg_png, clips, rect):
    """Overlay one or more captures, played back to back at real speed, into rect
    (x, y, w, h) on a card. Narration longer than the clips -> last frame held, HOLD shown."""
    x, y, w, h = rect
    total_cap = sum(dur(c) for c in clips)
    need = beat[bid]["actual_duration_s"]
    frames = math.ceil(max(need, total_cap) * FPS)
    hold_from = sum(round(dur(c) * FPS) for c in clips)
    hold_png = text_png(WORK / f"hold-{bid}.png", "HOLD: last frame held")
    ins = ["-loop", "1", "-framerate", str(FPS), "-i", str(bg_png)]
    for c in clips:
        ins += ["-i", str(c)]
    ins += ["-loop", "1", "-framerate", str(FPS), "-i", str(hold_png)]
    n = len(clips)
    fc = "".join(f"[{i + 1}:v]fps={FPS},scale={w}:{h},setsar=1[c{i}];" for i in range(n))
    fc += "".join(f"[c{i}]" for i in range(n)) + f"concat=n={n}:v=1:a=0[cat];"
    fc += f"[cat]tpad=stop_mode=clone:stop={max(0, frames - hold_from) + 2}[f];"
    fc += f"[0:v][f]overlay={x}:{y}:shortest=0[v1];"
    fc += (f"[v1][{n + 1}:v]overlay={x + w - 40}-w:{y + 40}:"
           f"enable='gte(n\\,{hold_from})'[out]")
    subprocess.run(["ffmpeg", "-v", "error", "-y"] + ins + ["-filter_complex", fc, "-map", "[out]",
                    "-frames:v", str(frames), "-r", str(FPS), "-c:v", "libx264", "-preset", "medium",
                    "-crf", "14", "-pix_fmt", "yuv420p", str(MEDIA / f"{bid}.mp4")], check=True)
    print(f"video {bid}: {frames} frames, capture {total_cap:.2f}s, narration {need:.2f}s, "
          f"hold {max(0, frames - hold_from)} frames")


# ── B01 title ────────────────────────────────────────────────────────────────
img, d = card()
cone(img, (2780, 1180), -35, 720, 22)
d = ImageDraw.Draw(img)
player(d, 2780, 1180, 80)
zombie(d, 3300, 860, 70); zombie(d, 3200, 700, 60)
d.text((L, 420), "DERELICT", font=SB(300), fill=AMBER)
d.text((L + 10, 820), "Final project pitch", font=F(130), fill=INK)
d.text((L + 10, 1040), "Sarthak Sargar", font=S(96), fill=INK)
d.text((L + 10, 1200), "Gameplay programmer  ·  Tools programmer", font=S(80), fill=MUTED)
label(d, "constructed on screen", "CSYE 7270 · Assignment 8")
save(img, "B01")

# ── B02 what it is: two scripted captures, framed ───────────────────────────
VX, VY, VW, VH = 512, 330, 2816, 1584
img, d = card("What it is")
d.rectangle((VX - 8, VY - 8, VX + VW + 8, VY + VH + 8), outline=MUTED, width=8)
label(d, "SCRIPTED CAPTURE · real fire input, zombies placed by the script (A6 film, game f4af1c4) · "
         "then real R, fire and Esc (A7 film, game 0d8710e)")
img.save(WORK / "bg-B02.png")
framed_video("B02", WORK / "bg-B02.png", [CAP / "burstplay_raw.mp4", CAP / "reloadplay_raw.mp4"],
             (VX, VY, VW, VH))

# ── B03 why care: a drawing + a scripted capture ────────────────────────────
img, d = card("Why care")
# drawing, left: the player's run in the dark (constructed on screen)
d.rounded_rectangle((L, 420, 1600, 1800), radius=30, fill=(12, 13, 15), outline=MUTED, width=6)
cone(img, (560, 1450), -40, 980, 20)
d = ImageDraw.Draw(img)
player(d, 560, 1450)
zombie(d, 1260, 760); burst(d, 1210, 800)
for k, (sx, sy) in enumerate([(500, 1560), (450, 1620), (540, 1660)]):
    d.ellipse((sx - 40 - 8 * k, sy - 40 - 8 * k, sx + 40 + 8 * k, sy + 40 + 8 * k), outline=(170, 170, 170), width=5)
d.text((330, 470), "AMMO  4 / 60", font=SB(70), fill=RED)
d.rounded_rectangle((1190, 1560, 1520, 1740), radius=20, outline=AMBER, width=6)
d.text((1230, 1610), "RELOAD", font=SB(60), fill=AMBER)
d.text((L, 1830), "constructed on screen: burst, wound smoke, low ammo, reload", font=S(44), fill=MUTED)
VX3, VY3, VW3, VH3 = 1720, 520, 1888, 1062
d.rectangle((VX3 - 8, VY3 - 8, VX3 + VW3 + 8, VY3 + VH3 + 8), outline=MUTED, width=8)
para(d, (VX3, VY3 + VH3 + 40), "SCRIPTED CAPTURE · real zombie swipes, real walk, game pause, real medkit · "
     "A6 film, game f4af1c4", S(44), VW3, fill=MUTED)
img.save(WORK / "bg-B03.png")
framed_video("B03", WORK / "bg-B03.png", [CAP / "smokeplay_raw.mp4"], (VX3, VY3, VW3, VH3))

# ── B04 different ────────────────────────────────────────────────────────────
img, d = card("Different from what exists")
# drawing: one big map vs four small rooms
d.rounded_rectangle((L, 420, 1700, 1500), radius=30, outline=MUTED, width=8)
for i in range(7):
    for j in range(5):
        d.rectangle((L + 60 + i * 200, 480 + j * 200, L + 200 + i * 200, 620 + j * 200), outline=(80, 80, 80), width=4)
d.text((L, 1540), "Call of Duty: zombies mode", font=SB(70), fill=INK)
d.text((L, 1640), "played by me · far bigger", font=S(58), fill=MUTED)
gx, gy = 2140, 640
for i, (dx, dy) in enumerate([(0, 0), (440, 0), (0, 440), (440, 440)]):
    d.rectangle((gx + dx, gy + dy, gx + dx + 400, gy + dy + 400), outline=AMBER, width=10)
player(d, gx + 200, gy + 640, 46)
d.text((1960, 1540), "DERELICT", font=SB(70), fill=AMBER)
d.text((1960, 1640), "single-player · top-down · four rooms", font=S(58), fill=INK)
d.text((1960, 1730), "tests anyone can rerun (from tag a5)", font=S(58), fill=INK)
d.rounded_rectangle((3140, 640, R, 1480), radius=24, fill=PANEL)
para(d, (3190, 690), "“I have played GTA (all of them till gta 4) and also Call of Duty!”", F(64), 370)
d.text((3190, 1380), "my words", font=S(44), fill=MUTED)
label(d, "constructed on screen · not bigger, not better: smaller and checkable")
save(img, "B04")

# ── B05 who opens it, first sixty seconds (WILL) ─────────────────────────────
img, d = card("Who opens it: the first sixty seconds")
d.text((L, 330), "lead engineer · hiring manager · recruiter", font=S(64), fill=MUTED)
steps = [("unzip", ""), ("run the .exe", ""), ("press Start", ""), ("shooting", "< 60 s (target)")]
y0 = 700
d.line((L + 100, y0 + 160, R - 100, y0 + 160), fill=MUTED, width=8)
for i, (name, t) in enumerate(steps):
    cx = L + 250 + i * 930
    d.ellipse((cx - 150, y0 + 10, cx + 150, y0 + 310), fill=PANEL, outline=AMBER, width=10)
    if i == 0:
        d.rectangle((cx - 80, y0 + 110, cx + 80, y0 + 230), outline=INK, width=8)
        d.line((cx - 80, y0 + 110, cx - 20, y0 + 80), fill=INK, width=8)
    elif i == 1:
        d.rectangle((cx - 90, y0 + 90, cx + 90, y0 + 230), outline=INK, width=8)
        d.line((cx - 90, y0 + 120, cx + 90, y0 + 120), fill=INK, width=8)
    elif i == 2:
        d.rounded_rectangle((cx - 100, y0 + 120, cx + 100, y0 + 200), radius=20, fill=AMBER)
    else:
        player(d, cx - 40, y0 + 200, 40); burst(d, cx + 70, y0 + 100, 26)
    d.text((cx - d.textlength(name, font=SB(66)) / 2, y0 + 360), name, font=SB(66), fill=INK)
    d.text((cx - d.textlength(t, font=S(56)) / 2, y0 + 460), t, font=S(56), fill=MUTED)
d.text((L, 1360), "tools reader:  README  →  one test command", font=M(72), fill=INK)
d.rounded_rectangle((L, 1560, R, 1840), radius=30, outline=RED, width=10)
d.text((L + 80, 1620), "WILL — no export exists yet; nothing here has been timed", font=SB(90), fill=RED)
label(d, "constructed on screen")
save(img, "B05")

# ── B06 what it proves: five skill areas, tag + real count ───────────────────
img, d = card("What it proves, by tag")
tiles = [
    ("Shaders & materials", "a5", ["low_ammo_test: 35 PASS at 30 / 60 / 144 fps", "test_materials: 74 PASS"]),
    ("Particle effects", "a6", ["impact burst config: 108 PASS", "wound smoke config: 39 PASS"]),
    ("Animation & state", "a7", ["read-backs: 32 + 57 PASS", "structure 51 · state 34 · edges 98"]),
    ("Profiling", "a6", ["GPU +0.018 / +0.023 ms", "budgets 0.30 / 0.20 ms", "RTX 4050 Laptop GPU"]),
    ("Verification", "a5–a7", ["mutations that had to fail: 3 + 4 + 3, each exit 1", "pins: 19 PASS, unchanged"]),
]
tw, th, gapx = 1080, 760, 80
for k, (name, tag, lines) in enumerate(tiles):
    col, row = k % 3, k // 3
    x0 = L + col * (tw + gapx) + (0 if row == 0 else (tw + gapx) // 2)
    y0 = 360 + row * (th + 60)
    d.rounded_rectangle((x0, y0, x0 + tw, y0 + th), radius=30, fill=PANEL, outline=AMBER, width=6)
    d.text((x0 + 50, y0 + 40), name, font=SB(72), fill=INK)
    d.rounded_rectangle((x0 + 50, y0 + 160, x0 + 50 + d.textlength("tag " + tag, font=SB(60)) + 60, y0 + 260),
                        radius=18, fill=AMBER)
    d.text((x0 + 80, y0 + 170), "tag " + tag, font=SB(60), fill=PAGE)
    y = y0 + 320
    for ln in lines:
        y = para(d, (x0 + 50, y), ln, S(54), tw - 100) + 14
label(d, "constructed on screen · counts from TEST-REPORT.md at each tag (PASS lines)")
save(img, "B06")

# ── B07 a real test run, built from real log lines ───────────────────────────
log = REPO / "docs/evidence/a7/final/test_pistol_reload_edges_60fps.log"
raw = log.read_text(encoding="utf-8").splitlines()
want = [0, 4, 23, 48, 63, 99, 100, 101, 103]   # 0-based line numbers, copied verbatim
lines = [raw[i] for i in want]
n_pass = sum(1 for x in raw if x.startswith("PASS"))
n_fail = sum(1 for x in raw if x.startswith("FAIL"))
img, d = card("A real test run")
d.rounded_rectangle((L, 360, R, 1760), radius=24, fill=(8, 9, 10), outline=MUTED, width=4)
d.text((L + 60, 400), "$ bash scripts/run-test.sh test_pistol_reload_edges.gd 60", font=M(60), fill=AMBER)
y = 520
for i, ln in enumerate(lines):
    if i in (2, 5):
        d.text((L + 60, y), "…", font=M(56), fill=MUTED); y += 90
    col = GREEN if ln.startswith("PASS") else INK
    for part in wrap(d, ln, M(54), R - L - 120):
        d.text((L + 60, y), part, font=M(54), fill=col); y += 80
d.text((L, 1800), f"{n_pass} PASS · {n_fail} FAIL", font=SB(80), fill=GREEN)
label(d, "constructed on screen from real log lines · docs/evidence/a7/final/test_pistol_reload_edges_60fps.log (commit 887266f, 2026-11-20)")
save(img, "B07")

# ── B08 what a reviewer can and cannot conclude ──────────────────────────────
img, d = card("What a reviewer can conclude")
box(d, L, 380, 1880, 1820, "Can", ["I can specify, direct, verify and measure game systems with an AI agent.",
                                   "Every layer from a5 on has a brief, tests and a log."], GREEN, 96, 80)
box(d, 1960, 380, R, 1820, "Cannot", ["That I hand-wrote the shaders, effects or animation: Claude wrote them under my direction.",
                                      "That the effects and animation look right in play: my checks are pending."], RED, 96, 80)
label(d, "constructed on screen · HUMAN-CHECK-NOTES.md: A6 and A7 rows read “pending: not yet performed by the student”")
save(img, "B08")

# ── B09 in, out, first ───────────────────────────────────────────────────────
img, d = card("In, out, and what comes first")
bw = (R - L - 120) // 3
box(d, L, 380, L + bw, 1820, "In", ["one run, title → end screen", "Windows export", "the layers built so far",
                                    "my own checks, in my words", "known issues fixed or written down"], GREEN, 96, 72)
box(d, L + bw + 60, 380, L + 2 * bw + 60, 1820, "Out", ["multiplayer", "saving", "more than four rooms",
                                                         "new enemy types", "a web build"], RED, 96, 72)
box(d, L + 2 * bw + 120, 380, R, 1820, "First", ["the Windows export, from the .exe to the end screen",
                                                  "its SHA-256 recorded", "a scripted run against it", "my own playtest"], AMBER, 96, 72)
label(d, "constructed on screen · all of this is WILL")
save(img, "B09")

# ── B10 the risk, with the real A6 strips ────────────────────────────────────
img, d = card("What could sink it")
for k, (rel, cap, colour) in enumerate([
        ("captures/impact_burst/r0-light/strip.png", "r0: the puff is full size on its first frame and never grows", RED),
        ("captures/impact_burst/r1-light/strip.png", "r1, billboard_keep_scale on: it shrinks to a dot — reverted", MUTED)]):
    s = Image.open(REPO / rel).convert("RGB")
    sw = R - L
    s = s.resize((sw, int(s.height * sw / s.width)), Image.LANCZOS)
    y = 400 + k * 780
    img.paste(s, (L, y))
    d.text((L, y + s.height + 30), cap, font=S(62), fill=colour)
label(d, "FIXTURE captures · Movie Maker 30 fps, preview seed 12345 · tag a6 (commits fe6044a, 0788794)")
save(img, "B10")

# ── B11 why this project ─────────────────────────────────────────────────────
img, d = card("Why this project")
box(d, L, 380, 2300, 1820, "New to me", ["Godot shaders and materials (a5)", "particle effects and profiling (a6)",
                                         "animation and state (a7)", "testing: pins, read-backs, mutations",
                                         "directing an AI agent with scoped tools"], AMBER, 96, 80)
box(d, 2380, 380, R, 1820, "Already had", ["playing games like this: GTA up to 4, Call of Duty",
                                           "not measured, so not claimed"], MUTED, 96, 80)
label(d, "constructed on screen · mostly learning")
save(img, "B11")

# ── B12 exists today vs will exist ───────────────────────────────────────────
img, d = card("Exists today · Will exist")
box(d, L, 380, 1880, 1820, "Exists today", ["core loop: menu, four rooms, two zombie types, waves, win and death  [a2-redo]",
                                            "three Blender props  [a3]", "low-ammo shader, materials  [a5]",
                                            "impact burst, wound smoke, costs  [a6]", "keycard spin, pistol reload  [a7]",
                                            "test and capture toolkit  [a5–a7]"], GREEN, 90, 66)
box(d, 1960, 380, R, 1820, "Will exist", ["a Windows export, with its SHA-256", "a scripted run against the export",
                                          "my own playtest and checks, in my words", "the effect fixes, recaptured and judged",
                                          "a README a stranger can follow"], AMBER, 90, 66)
label(d, "constructed on screen")
save(img, "B12")

# ── B13 plain end card ───────────────────────────────────────────────────────
img, d = card()
d.text((L, 520), "DERELICT", font=SB(260), fill=AMBER)
d.text((L + 10, 900), "Sarthak Sargar · final project pitch", font=S(90), fill=INK)
d.text((L + 10, 1180), "github.com/Sarthak-Boston-Codes/walker-derelict-sarthak-sargar", font=M(78), fill=INK)
d.text((L + 10, 1320), "tag a8 · folder pitch/", font=M(78), fill=MUTED)
cone(img, (3200, 1600), -60, 520, 18)
d = ImageDraw.Draw(img)
player(d, 3200, 1600, 70)
label(d, "constructed on screen", "narration: Kokoro am_onyx (generated)")
save(img, "B13")
