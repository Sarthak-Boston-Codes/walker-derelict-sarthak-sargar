# usage: python -I strip.py <frames_dir> <out.png> <cx> <cy> <half> <frames comma list> [label]
import sys
from PIL import Image, ImageDraw
d, out, cx, cy, half = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
frames = [int(x) for x in sys.argv[6].split(",")]
label = sys.argv[7] if len(sys.argv) > 7 else ""
scale = int(__import__("os").environ.get("STRIP_SCALE", "2"))
tiles = []
for f in frames:
    im = Image.open(f"{d}/frame{f:08d}.png").convert("RGB")
    t = im.crop((cx - half, cy - half, cx + half, cy + half)).resize((half * 2 * scale, half * 2 * scale), Image.NEAREST)
    dr = ImageDraw.Draw(t); dr.rectangle((0, 0, 92, 18), fill=(0, 0, 0)); dr.text((4, 3), f"frame {f}", fill=(255, 255, 255))
    tiles.append(t)
w = half * 2 * scale
sheet = Image.new("RGB", (w * len(tiles), w + 20), (20, 20, 20))
for i, t in enumerate(tiles):
    sheet.paste(t, (i * w, 20))
ImageDraw.Draw(sheet).text((4, 4), label, fill=(230, 230, 230))
sheet.save(out)
print("wrote", out, sheet.size)
