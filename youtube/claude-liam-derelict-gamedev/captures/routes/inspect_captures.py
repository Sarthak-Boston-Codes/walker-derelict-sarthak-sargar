"""Contact sheets (labelled frames at chosen times) + 100 ms loudness envelopes for the captures."""
import subprocess, sys
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw, ImageFont

CAP = Path(__file__).resolve().parents[1]
OUT = Path(sys.argv[1]) if len(sys.argv) > 1 else CAP
TIMES = {
    "RUN_A_clear": [0.3, 1.2, 2.0, 2.25, 2.4, 3.5, 7.0, 10.9, 13.5],
    "RUN_B_grab": [1.0, 3.5, 4.3, 4.9, 5.6, 7.5],
    "RUN_C_mute": [0.5, 1.5, 2.65, 3.8, 4.5],
}
font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 18)

def frame(mp4, t):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-ss", f"{t}", "-i", str(mp4), "-frames:v", "1",
                          "-vf", "scale=426:240", "-f", "rawvideo", "-pix_fmt", "rgb24", "-"],
                         capture_output=True).stdout
    return Image.frombytes("RGB", (426, 240), raw)

def envelope(mp4):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(mp4), "-vn", "-ac", "1", "-ar", "48000",
                          "-f", "s16le", "-"], capture_output=True).stdout
    x = np.frombuffer(raw, np.int16).astype(float) / 32768
    n = 4800
    return [20 * np.log10(max(np.sqrt((x[i:i + n] ** 2).mean()), 1e-6)) for i in range(0, len(x), n)]

for name, times in TIMES.items():
    mp4 = CAP / f"{name}.mp4"
    cols = 3
    rows = (len(times) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * 426, rows * 240), (0, 0, 0))
    for i, t in enumerate(times):
        img = frame(mp4, t)
        d = ImageDraw.Draw(img)
        d.rectangle([0, 214, 90, 240], fill=(0, 0, 0))
        d.text((6, 216), f"{t:5.2f}s", font=font, fill=(255, 255, 0))
        sheet.paste(img, ((i % cols) * 426, (i // cols) * 240))
    sheet.save(OUT / f"{name}_contact.png")
    env = envelope(mp4)
    print(f"{name}: {len(env) / 10:.1f}s")
    for start in range(0, len(env), 30):
        chunk = env[start:start + 30]
        print(f"  {start / 10:5.1f}s+ " + " ".join(f"{v:4.0f}" for v in chunk))
