"""Inspect rendered scenes: duration vs beat, and labelled frame sheets.

  python inspect_scenes.py OUTDIR
"""
import json, math, subprocess, sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

FILM = Path(__file__).resolve().parent
OUT = Path(sys.argv[1])
sheet = json.loads((FILM / "beat_sheet.json").read_text(encoding="utf-8"))
font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 20)


def probe(p, entry):
    return subprocess.run(["ffprobe", "-v", "error", "-select_streams", "v:0", "-show_entries", entry,
                           "-of", "csv=p=0", str(p)], capture_output=True, text=True).stdout.strip()


def frame(p, t, w=640):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-ss", f"{t:.2f}", "-i", str(p), "-frames:v", "1",
                          "-vf", f"scale={w}:-2", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                         capture_output=True).stdout
    return Image.frombytes("RGB", (w, len(raw) // (w * 3)), raw)


rows = []
print(f"{'beat':5} {'pattern':24} {'clip s':>7} {'beat s':>7} {'WxH':>10}  status")
for b in sheet["beats"]:
    pat = (b["shot"].get("remotion") or {}).get("pattern")
    if not pat:
        continue
    mp4 = FILM / "media" / f"{b['beat_id']}.mp4"
    d = float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                              str(mp4)], capture_output=True, text=True).stdout)
    need = b.get("actual_duration_s") or b["estimated_duration_s"]
    wh = probe(mp4, "stream=width,height").replace(",", "x")
    ok = abs(d - need) <= 1 / 30 + 0.02
    print(f"{b['beat_id']:5} {pat:24} {d:7.2f} {need:7.2f} {wh:>10}  {'ok' if ok else 'MISMATCH'}")
    times = [0.15 * d, 0.5 * d, max(0.0, d - 0.3)]
    tiles = []
    for t in times:
        img = frame(mp4, t)
        ImageDraw.Draw(img).text((8, img.height - 26), f"{b['beat_id']} {t:5.1f}s", font=font, fill=(255, 220, 0))
        tiles.append(img)
    rows.append(tiles)

w, h = rows[0][0].size
for start in range(0, len(rows), 5):
    chunk = rows[start:start + 5]
    sheet_img = Image.new("RGB", (w * 3, h * len(chunk)), (0, 0, 0))
    for r, tiles in enumerate(chunk):
        for c, t in enumerate(tiles):
            sheet_img.paste(t, (c * w, r * h))
    sheet_img.save(OUT / f"scenes_{start // 5}.png")
print("sheets:", [f"scenes_{i}.png" for i in range(math.ceil(len(rows) / 5))])
