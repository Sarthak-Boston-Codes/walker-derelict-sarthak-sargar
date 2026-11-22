"""Conform the two play clips (B09, B11) to their beat lengths without retiming them
(Claude Code, after the A6 film's conform_clips.py): target = max(capture,
narration). Narration longer -> the last frame is held, labelled HOLD; shorter ->
nothing to do (compile.py pads audio). B09 also gets a labelled x4 zoom of the
HUD's keycard row, cut from the same frame (the icon is 96 px tall at 4K).
Then rerun build_sheet.py (the media hashes change).

  python conform_clips.py
"""
import json, math, subprocess
from pathlib import Path

FILM = Path(__file__).resolve().parent
FPS = 30
FONT = r"C\:/Windows/Fonts/segoeui.ttf"
CLIPS = {
    "B09": ("keyplay_raw.mp4", "SCRIPTED PLAY · real W key walks onto the keycard (placed 3 m away before filming) · Godot 4.7.2 capture",
            (30, 360, 660, 160)),
    "B11": ("reloadplay_raw.mp4", "SCRIPTED PLAY · real R, fire and Esc events, an interrupt in each phase · Godot 4.7.2 capture",
            None),
}


def dur(p):
    return float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                                 str(p)], capture_output=True, text=True).stdout)


def box(text, y, size=64, x="(w-text_w)/2"):
    return (f"drawtext=fontfile='{FONT}':text='{text}':x={x}:y={y}:fontsize={size}:fontcolor=white:"
            f"box=1:boxcolor=0xD97757@0.92:boxborderw=22")


sheet_path = FILM / "beat_sheet.json"
sheet = json.loads(sheet_path.read_text(encoding="utf-8")) if sheet_path.exists() else {"beats": []}
for bid, (raw_name, label, zoom) in CLIPS.items():
    raw = FILM / "captures" / raw_name
    out = FILM / "media" / f"{bid}.mp4"
    b = next((b for b in sheet["beats"] if b["beat_id"] == bid), {})
    cap = dur(raw)
    nar = b.get("actual_duration_s") or 0.0
    frames = math.ceil(max(cap, nar) * FPS)
    hold = frames - round(cap * FPS)
    chain = "[0:v]"
    pre = ""
    if hold > 0:
        pre = f"{chain}tpad=stop_mode=clone:stop={hold}[v0];"
        chain = "[v0]"
    if zoom:
        x, y, w, h = zoom
        pre += (f"{chain}split[a][b];[b]crop={w}:{h}:{x}:{y},scale={w * 4}:{h * 4}:flags=neighbor,"
                f"drawbox=x=0:y=0:w=iw:h=ih:color=0xFAF9F5:t=8[z];[a][z]overlay=x=(W-w)/2:y=1180,"
                + box("ZOOM x4 of the HUD keycard row (same frame)", "1100", 52) + "[v1];")
        chain = "[v1]"
    vf = pre + chain + box(label, "h-150")
    if hold > 0:
        vf += "," + box("HOLD", "120").replace("drawtext=", rf"drawtext=enable='gte(n\,{round(cap * FPS)})':")
    vf += "[out]"
    subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(raw), "-filter_complex", vf, "-map", "[out]",
                    "-frames:v", str(frames), "-c:v", "libx264", "-preset", "medium", "-crf", "14",
                    "-pix_fmt", "yuv420p", "-r", str(FPS), "-an", str(out)], check=True)
    print(f"{bid}: capture {cap:.2f}s, narration {nar:.2f}s -> {frames} frames ({max(hold, 0)} HOLD frames); {dur(out):.2f}s")
