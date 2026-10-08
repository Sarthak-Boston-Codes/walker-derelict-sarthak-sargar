"""Run brutalist.art's own final_frame_check.analyze_frame on chosen beats of a cut,
optionally with a candidate contrast region, before committing to a 40-min final.

  python qc_probe.py CUT.mp4 OUTDIR [x0 y0 x1 y1] [--full-bleed]
"""
import json, math, subprocess, sys
from pathlib import Path

sys.path.insert(0, r"C:\Users\sarth\brutalist.art\runtime\qc")
sys.path.insert(0, r"C:\Users\sarth\brutalist.art\runtime\scripts")
import final_frame_check as g  # noqa: E402

FILM = Path(__file__).resolve().parent
cut, out = sys.argv[1], Path(sys.argv[2])
nums = [float(v) for v in sys.argv[3:7]] if len(sys.argv) >= 7 else None
full_bleed = "--full-bleed" in sys.argv
beats_arg = [a for a in sys.argv if a.startswith("--beats=")]
want = beats_arg[0].split("=", 1)[1].split(",") if beats_arg else None
regions = [{"label": "HUD readout", "box": nums}] if nums else None

sheet = json.loads((FILM / "beat_sheet.json").read_text(encoding="utf-8"))
t = 0.0
for b in sheet["beats"]:
    d = math.ceil((b.get("render_duration_s") or b.get("actual_duration_s") or b["estimated_duration_s"]) * 30 - 1e-8) / 30
    bid = b["beat_id"]
    if want is None or bid in want:
        for fr in (0.5, 0.85):
            png = out / f"{bid}_{int(fr * 100)}.png"
            subprocess.run(["ffmpeg", "-v", "error", "-y", "-ss", f"{t + d * fr:.3f}", "-i", cut, "-frames:v", "1", str(png)], check=True)
            defects, cover = g.analyze_frame(str(png), regions)
            if full_bleed:
                defects = [x for x in defects if x[1] != "edge-bleed"]
            print(f"{bid}_{int(fr * 100)}  cover {cover * 100:4.0f}%  " + ("; ".join(f"{s} {k}: {m}" for s, k, m in defects) or "clean"))
    t += d
