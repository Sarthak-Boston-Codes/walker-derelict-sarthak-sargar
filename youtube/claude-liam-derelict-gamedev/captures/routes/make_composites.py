"""B16 (before | after facing grids) and B23 (recorded test logs): native
3840x2160 cards in the shared style (cards.py), all ink inside title-safe.
Source render pixels are not edited; only scaled, placed and labelled."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont
from cards import card, footer, S, INK, ACCENT, MUTED, LEFT, CONTENT_W, FOOTER_Y

MEDIA = Path(__file__).resolve().parents[2] / "media"
OK, BAD = (60, 120, 60), (176, 52, 40)

# --- B16: before (commit 7fc6a99, free rotation) | after (mirror + capped tilt) ---
before = Image.open(MEDIA / "B16_before_7fc6a99.png").convert("RGB")
after = Image.open(MEDIA / "B16_after_mirror_tilt.png").convert("RGB")
img, d = card("Free rotation, then mirror + tilt.")
gap, top = 140, 560
avail_h = FOOTER_Y - 80 - top
# One shared height that fits both side by side inside the content width.
hgt = min(avail_h, int((CONTENT_W - gap) / (before.width / before.height + after.width / after.height)))
a = before.resize((round(before.width * hgt / before.height), hgt), Image.LANCZOS)
b = after.resize((round(after.width * hgt / after.height), hgt), Image.LANCZOS)
x0 = LEFT + (CONTENT_W - (a.width + gap + b.width)) // 2
for x, panel, head, sub in [(x0, a, "Before · commit 7fc6a99", "free rotation; rows = old formula, formula + 180°"),
                            (x0 + a.width + gap, b, "After · facing.gd", "mirror by aim side, tilt ≤ 30°")]:
    d.text((x, top - 150), head, font=S(62), fill=ACCENT if x == x0 else INK)
    d.text((x, top - 70), sub, font=S(44), fill=MUTED)
    img.paste(panel, (x, top))
footer(d, "media/B16_before_7fc6a99.png (git archive 7fc6a99) · media/B16_after_mirror_tilt.png (6 facing checks PASS)")
img.save(MEDIA / "B16.png")


# --- B23: the two recorded logs, stacked, verbatim -----------------------------------------
def log_panel(path, title, colour, width):
    lines = [l for l in (MEDIA / "logs" / path).read_text(encoding="utf-8").splitlines() if l.strip()]
    lines = [l for l in lines if not l.startswith("Godot Engine")]
    big = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 40)
    lh = 50
    panel = Image.new("RGB", (width, 90 + lh * len(lines)), (30, 30, 30))
    pd = ImageDraw.Draw(panel)
    pd.text((30, 22), title, font=S(48), fill=colour)
    for i, line in enumerate(lines):
        fill = BAD if "FAIL" in line else (OK if line.rstrip().endswith("ok") or line.startswith("ok") or "PASS" in line else (220, 220, 220))
        pd.text((30, 90 + i * lh), line, font=big, fill=fill)
    return panel


p = log_panel("trigger_count_pass.log", "Recorded run: isolated copy of the game", (140, 200, 140), CONTENT_W)
q = log_panel("trigger_count_guards_broken.log", "Recorded run: copy with the 4 anti-double-trigger guards removed",
              ACCENT, CONTENT_W)
img, d = card("The test, run twice.")
img.paste(p, (LEFT, 380))
img.paste(q, (LEFT, 380 + p.height + 40))
footer(d, "media/logs/trigger_count_pass.log · media/logs/trigger_count_guards_broken.log (verbatim)")
img.save(MEDIA / "B23.png")
print("B16.png", img.size, "| B23 log panels end at y =", 380 + p.height + 40 + q.height, "(footer at", FOOTER_Y, ")")
