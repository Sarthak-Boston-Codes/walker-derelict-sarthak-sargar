"""B17 (CHAR-CELEBRATE trace board) and B18 (chroma_key.py code card), 3840x2160,
in the shared card style (cards.py), all ink inside brutalist.art's title-safe area.

B17: real images only: storyboard panel 7 and sheet pose 10 (cropped from the
SVG sheets rasterised by headless Chrome), the rejected thumbnail, the accepted
raw output. Prompts are quoted from SOURCES.md line 27.
B18: tools/chroma_key.py lines 25-38, read from the file (verbatim), numbered
25-38. A card, not GitHubCodeViewer (numbers from 1) and not the Godot
workbench (the file is not a Godot file).

  python make_trace_cards.py
"""
import re, subprocess
from pathlib import Path
from PIL import Image
from cards import card, footer, F, M, S, INK, PAGE, ACCENT, MUTED, LEFT, RIGHT, CONTENT_W, FOOTER_Y

ROUTES = Path(__file__).resolve().parent
FILM = ROUTES.parents[1]
REPO = FILM.parents[1]
MEDIA, TRACE = FILM / "media", FILM / "media" / "trace"
HS = next(Path(r"C:\Users\sarth\brutalist.art\runtime\remotion\node_modules\.remotion\chrome-headless-shell")
          .rglob("chrome-headless-shell.exe"))
PANEL, PANEL_HEAD, CODE_FG, CODE_NUM, CODE_KW, CODE_COM = (30, 34, 44), (44, 50, 63), (226, 226, 220), (120, 128, 145), (211, 140, 200), (125, 140, 120)


def rasterise(svg, out, w, h):
    uri = "file:///" + str(svg).replace("\\", "/").replace(" ", "%20")
    subprocess.run([str(HS), "--headless", "--no-first-run", "--hide-scrollbars",
                    f"--screenshot={out}", f"--window-size={w},{h}", uri], capture_output=True, timeout=60)
    return Image.open(out).convert("RGB")


def fit(img, w, h):
    img = img.convert("RGB")
    s = min(w / img.width, h / img.height)
    return img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)


def wrap(d, text, font, width):
    words, lines, cur = text.split(), [], ""
    for wd in words:
        trial = (cur + " " + wd).strip()
        if d.textlength(trial, font=font) <= width:
            cur = trial
        else:
            lines.append(cur); cur = wd
    return lines + [cur]


# --- B17 trace board --------------------------------------------------------------
sb = rasterise(REPO / "design/storyboard/sheet.svg", TRACE / "storyboard_sheet.png", 1500, 760)
cs = rasterise(REPO / "design/character/sheet.svg", TRACE / "character_sheet.png", 1540, 700)
panel7 = sb.crop((740, 380, 1081, 681))
pose10 = cs.crop((1220, 360, 1501, 641))
rejected = Image.open(TRACE / "celebrate_attempt1_rejected_thumb.jpg")
raw = Image.open(TRACE / "celebrate_raw_greenscreen.jpg")
row27 = (REPO / "SOURCES.md").read_text(encoding="utf-8").splitlines()[26]
assert row27.startswith("| CHAR-CELEBRATE"), row27
prompt1 = re.search(r'First attempt: "([^"]+)"', row27).group(1)
prompt2 = re.search(r'Re-prompted: "([^"]+)"', row27).group(1)

img, d = card("CHAR-CELEBRATE, end to end.")
gap = 110
colw = (CONTENT_W - 2 * gap) // 3
xs = [LEFT + i * (colw + gap) for i in range(3)]
for x, head in zip(xs, ["1 · Asked for", "2 · First prompt → rejected", "3 · Correction → accepted"]):
    d.text((x, 430), head, font=F(76), fill=ACCENT if "rejected" in head else INK)
IMG_TOP, IMG_H = 580, 700

half = (colw - 30) // 2
a = fit(panel7, half, 460); b = fit(pose10, half, 460)
img.paste(a, (xs[0], IMG_TOP)); img.paste(b, (xs[0] + half + 30, IMG_TOP))
cap_y = IMG_TOP + max(a.height, b.height) + 20
d.text((xs[0], cap_y), "Storyboard panel 7", font=S(44), fill=INK)
d.text((xs[0] + half + 30, cap_y), "Sheet pose 10", font=S(44), fill=INK)
for i, line in enumerate(wrap(d, "\u201cA clear, calm signal the session ended successfully, readable even muted.\u201d"
                                 " (STORYBOARD.md panel 7)", F(58), colw)):
    d.text((xs[0], cap_y + 100 + i * 76), line, font=F(58), fill=INK)

r = fit(rejected, colw, IMG_H); img.paste(r, (xs[1], IMG_TOP))
d.rectangle([xs[1], IMG_TOP, xs[1] + r.width, IMG_TOP + r.height], outline=ACCENT, width=10)
tag = F(76)
d.rectangle([xs[1], IMG_TOP, xs[1] + d.textlength("REJECTED", font=tag) + 60, IMG_TOP + 104], fill=ACCENT)
d.text((xs[1] + 30, IMG_TOP + 8), "REJECTED", font=tag, fill=PAGE)
yy = IMG_TOP + r.height + 50
for i, line in enumerate(wrap(d, f"\u201c{prompt1}\u201d", M(50), colw)):
    d.text((xs[1], yy + i * 64), line, font=M(50), fill=INK)
d.text((xs[1], yy + 160), "came back with blood drops and a dropped weapon", font=S(44), fill=MUTED)

g = fit(raw, colw, IMG_H); img.paste(g, (xs[2], IMG_TOP))
yy = IMG_TOP + g.height + 50
lines = wrap(d, f"\u201c{prompt2}\u201d", M(50), colw)
for i, line in enumerate(lines):
    d.text((xs[2], yy + i * 64), line, font=M(50), fill=INK)
d.text((xs[2], yy + len(lines) * 64 + 40), "raw output, solid green, before keying", font=S(44), fill=MUTED)
for x in (xs[0] + colw + 5, xs[1] + colw + 5):  # arrows drawn last so no image covers them
    d.text((x, IMG_TOP + r.height // 2 - 100), "→", font=F(120), fill=MUTED)
footer(d, "STORYBOARD.md · CHARACTER-SHEET.md · prompts: SOURCES.md line 27 (student's asset log) · "
          "design/character/rejected/ · Gemini download")
img.save(MEDIA / "B17.png")

# --- B18 code card -----------------------------------------------------------------
src = (REPO / "tools/chroma_key.py").read_text(encoding="utf-8").splitlines()
code = src[24:38]
assert code[0].startswith("def key_out") and code[-1].strip().startswith("return"), code
img, d = card("Keying the green out.")
x0, y0, x1, y1 = LEFT, 400, RIGHT, FOOTER_Y - 80
d.rounded_rectangle([x0, y0, x1, y1], radius=24, fill=PANEL)
d.rounded_rectangle([x0, y0, x1, y0 + 120], radius=24, fill=PANEL_HEAD)
d.rectangle([x0, y0 + 90, x1, y0 + 120], fill=PANEL_HEAD)
d.text((x0 + 50, y0 + 30), "tools/chroma_key.py  ·  lines 25–38", font=M(56), fill=CODE_FG)
note = "repo tool, outside godot/ · verbatim · not covered by verify_gamedev.py"
d.text((x1 - 50 - d.textlength(note, font=S(42)), y0 + 38), note, font=S(42), fill=(150, 185, 230))
KW = r"\b(def|return|for|in|if|else|import|from|None)\b"
for i, line in enumerate(code):
    y = y0 + 180 + i * 90
    d.text((x0 + 50, y), f"{25 + i:>3}", font=M(58), fill=CODE_NUM)
    x = x0 + 220
    comment = line.lstrip().startswith("#")
    for part in re.split(KW, line):
        if not part:
            continue
        colour = CODE_COM if comment else (CODE_KW if re.fullmatch(KW, part) else CODE_FG)
        d.text((x, y), part, font=M(58), fill=colour)
        x += d.textlength(part, font=M(58))
    assert x <= x1 - 40, f"code line {25 + i} overflows the panel"
footer(d, "tools/chroma_key.py lines 25–38 · displayed verbatim (sha256 in FACTCHECK.md)")
img.save(MEDIA / "B18.png")
print("wrote media/B17.png, media/B18.png, trace/storyboard_sheet.png, trace/character_sheet.png")
