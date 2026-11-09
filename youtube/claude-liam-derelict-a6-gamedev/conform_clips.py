"""Conform the two play clips (B07, B14) to their beat lengths without retiming them
(Claude Code, after the A5 film's conform_clips.py): target = max(capture,
narration). Narration longer -> the last frame is held, labelled HOLD; shorter ->
nothing to do (compile.py pads audio). Before narration is measured the clip is
just labelled. Then rerun build_sheet.py (the media hashes change).

  python conform_clips.py
"""
import json, math, subprocess
from pathlib import Path

FILM = Path(__file__).resolve().parent
FPS = 30
FONT = r"C\:/Windows/Fonts/segoeui.ttf"
CLIPS = {
    "B07": ("burstplay_raw.mp4", "SCRIPTED PLAY · real fire input and mouse aim · Godot 4.7.2 capture"),
    "B14": ("smokeplay_raw.mp4", "SCRIPTED PLAY · real zombie swipe, move, pause, medkit · Godot 4.7.2 capture"),
}


def dur(p):
    return float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                                 str(p)], capture_output=True, text=True).stdout)


def box(text, y):
    return (f"drawtext=fontfile='{FONT}':text='{text}':x=(w-text_w)/2:y={y}:fontsize=64:fontcolor=white:"
            f"box=1:boxcolor=0xD97757@0.92:boxborderw=22")


sheet_path = FILM / "beat_sheet.json"
sheet = json.loads(sheet_path.read_text(encoding="utf-8")) if sheet_path.exists() else {"beats": []}
for bid, (raw_name, label) in CLIPS.items():
    raw = FILM / "captures" / raw_name
    out = FILM / "media" / f"{bid}.mp4"
    b = next((b for b in sheet["beats"] if b["beat_id"] == bid), {})
    cap = dur(raw)
    nar = b.get("actual_duration_s") or 0.0
    frames = math.ceil(max(cap, nar) * FPS)
    hold = frames - round(cap * FPS)
    vf = box(label, "h-150")
    if hold > 0:
        vf = (f"tpad=stop_mode=clone:stop={hold},{vf},"
              + box("HOLD", "120").replace("drawtext=", rf"drawtext=enable='gte(n\,{round(cap * FPS)})':"))
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(raw), "-vf", vf, "-frames:v", str(frames), "-c:v",
                    "libx264", "-preset", "medium", "-crf", "14", "-pix_fmt", "yuv420p", "-r", str(FPS), "-an",
                    str(out)], check=True)
    print(f"{bid}: capture {cap:.2f}s, narration {nar:.2f}s -> {frames} frames ({max(hold, 0)} HOLD frames); {dur(out):.2f}s")
