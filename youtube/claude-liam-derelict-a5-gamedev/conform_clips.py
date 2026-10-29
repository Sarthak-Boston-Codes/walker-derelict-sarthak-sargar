"""Conform the play clip (B07) to its beat length without retiming it (Claude Code,
after the A3 film's conform_clips.py): target = max(capture, narration).
Narration longer -> the last frame is held, labelled HOLD; shorter -> nothing to do
(compile.py pads audio). Then rerun build_sheet.py (the media hash changes).

  python conform_clips.py
"""
import json, math, subprocess
from pathlib import Path

FILM = Path(__file__).resolve().parent
FPS = 30
FONT = r"C\:/Windows/Fonts/segoeui.ttf"
LABEL = "SCRIPTED PLAY · real fire and reload input · Godot 4.7.2 capture"
RAW = FILM / "captures" / "playclip_raw.mp4"
OUT = FILM / "media" / "B07.mp4"


def dur(p):
    return float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                                 str(p)], capture_output=True, text=True).stdout)


def box(text, y):
    return (f"drawtext=fontfile='{FONT}':text='{text}':x=(w-text_w)/2:y={y}:fontsize=64:fontcolor=white:"
            f"box=1:boxcolor=0xD97757@0.92:boxborderw=22")


sheet = json.loads((FILM / "beat_sheet.json").read_text(encoding="utf-8"))
b = next(b for b in sheet["beats"] if b["beat_id"] == "B07")
cap, nar = dur(RAW), b["actual_duration_s"]
frames = math.ceil(max(cap, nar) * FPS)
hold = frames - round(cap * FPS)
vf = box(LABEL, "h-150")
if hold > 0:
    vf = (f"tpad=stop_mode=clone:stop={hold},{vf},"
          + box("HOLD", "120").replace("drawtext=", rf"drawtext=enable='gte(n\,{round(cap * FPS)})':"))
subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(RAW), "-vf", vf, "-frames:v", str(frames), "-c:v",
                "libx264", "-preset", "medium", "-crf", "14", "-pix_fmt", "yuv420p", "-r", str(FPS), "-an",
                str(OUT)], check=True)
print(f"B07: capture {cap:.2f}s, narration {nar:.2f}s -> {frames} frames ({hold} HOLD frames); {dur(OUT):.2f}s")
