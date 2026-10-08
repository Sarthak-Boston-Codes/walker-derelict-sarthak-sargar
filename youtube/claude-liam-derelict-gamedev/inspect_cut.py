"""Inspect a compiled cut: streams, per-beat timeline, per-beat loudness, B12 vs capture.

  python inspect_cut.py CUT.mp4
"""
import json, math, subprocess, sys
from pathlib import Path
import numpy as np

FILM = Path(__file__).resolve().parent
cut = Path(sys.argv[1])
sheet = json.loads((FILM / "beat_sheet.json").read_text(encoding="utf-8"))
FPS = 30

probe = json.loads(subprocess.run(["ffprobe", "-v", "error", "-show_streams", "-show_format", "-of", "json", str(cut)],
                                  capture_output=True, text=True).stdout)
for s in probe["streams"]:
    print(f"stream {s['codec_type']:5} {s['codec_name']:5} "
          + (f"{s['width']}x{s['height']} {s['r_frame_rate']}" if s["codec_type"] == "video" else f"{s['sample_rate']} Hz {s['channels']}ch"))
print(f"duration {float(probe['format']['duration']):.3f}s")


def pcm(path, sr=48000):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(path), "-vn", "-ac", "1", "-ar", str(sr), "-f", "s16le", "-"],
                         capture_output=True).stdout
    return np.frombuffer(raw, np.int16).astype(float) / 32768


x = pcm(cut)
db = lambda v: 20 * math.log10(max(v, 1e-6))
t = 0.0
print(f"\n{'beat':5} {'start':>7} {'dur':>6} {'rms dB':>7} {'peak dB':>8}  audio source")
for b in sheet["beats"]:
    d = math.ceil((b.get("render_duration_s") or b.get("actual_duration_s") or b["estimated_duration_s"]) * FPS - 1e-8) / FPS
    seg = x[int(t * 48000):int((t + d) * 48000)]
    src = ("GAME AUDIO (preserve)" if b.get("audio_policy") == "preserve"
           else "silence" if b.get("audio_policy") == "silence" else "narration")
    print(f"{b['beat_id']:5} {t:7.2f} {d:6.2f} {db(np.sqrt((seg ** 2).mean())):7.1f} {db(np.abs(seg).max()):8.1f}  {src}")
    if b["beat_id"] == "B12":
        b12 = (t, d, seg)
    t += d
print(f"timeline sum {t:.3f}s")

start, d, seg = b12
ref = pcm(FILM / "media" / "B12.mp4")[:len(seg)]
n = 4800
e_cut = [db(np.sqrt((seg[i:i + n] ** 2).mean())) for i in range(0, len(seg) - n + 1, n)]
e_ref = [db(np.sqrt((ref[i:i + n] ** 2).mean())) for i in range(0, len(ref) - n + 1, n)]
diff = max(abs(a - b) for a, b in zip(e_cut, e_ref))
corr = float(np.corrcoef(seg[:len(ref)], ref)[0, 1])
print(f"\nB12 in cut at {start:.2f}-{start + d:.2f}s: 100 ms envelope vs media/B12.mp4: max diff {diff:.2f} dB, "
      f"sample correlation {corr:.3f}")
print("  cut  " + " ".join(f"{v:4.0f}" for v in e_cut))
print("  clip " + " ".join(f"{v:4.0f}" for v in e_ref))
