"""Conform each capture clip to its beat's exact length without retiming it
(capture contract, as in the first DERELICT film).

  target = max(capture, measured narration)
  - narration shorter -> narration mp3 padded with trailing silence to target
  - narration longer  -> labelled HOLD (last frame) appended to the video

Outputs media/Bxx.mp4 at exactly ceil(target*30) frames (what compile.py renders),
updates beat_sheet.json and captures/MEDIA-LEDGER.json. Rerun build_sheet.py
afterwards (result media hashes change).

  python conform_clips.py
"""
import hashlib, json, math, shutil, subprocess, tempfile
from pathlib import Path

FILM = Path(__file__).resolve().parent
MEDIA, ACTION = FILM / "media", FILM / "media" / "action"
FPS = 30
FONT = "C\\:/Windows/Fonts/consola.ttf"
BEATS = ["B11", "B19"]
VENC = ["-c:v", "libx264", "-preset", "medium", "-crf", "12", "-pix_fmt", "yuv420p", "-r", str(FPS), "-an"]


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def dur(p):
    return float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                                 str(p)], capture_output=True, text=True).stdout)


def ff(*args):
    subprocess.run(["ffmpeg", "-v", "error", "-y", *args], check=True)


FRAME_BOX = (542, 380, 2756, 1550)  # x, y, w, h of the video inside media/frames/Bxx_frame.png (make_cards.py)


def label(text):
    # Inside the top of the video box, clear of the card title.
    return (f"drawtext=fontfile='{FONT}':text='{text}':x=(w-text_w)/2:y={FRAME_BOX[1] + 40}:fontsize=80:"
            f"fontcolor=white:box=1:boxcolor=0xD97757@0.92:boxborderw=24")


def framed(src, bid, out):
    """The capture, scaled (not cropped or retimed) into the card frame's video box."""
    x, y, w, h = FRAME_BOX
    ff("-loop", "1", "-i", str(MEDIA / "frames" / f"{bid}_frame.png"), "-i", str(src), "-filter_complex",
       f"[1:v]scale={w}:{h}:flags=lanczos[v];[0:v][v]overlay={x}:{y}:shortest=1,fps={FPS}", *VENC, str(out))


sheet_path = FILM / "beat_sheet.json"
sheet = json.loads(sheet_path.read_text(encoding="utf-8"))
beats = {b["beat_id"]: b for b in sheet["beats"]}
ledger_path = FILM / "captures" / "MEDIA-LEDGER.json"
ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
ledger["conformed"] = {}
report = []

for bid in BEATS:
    b = beats[bid]
    src = ACTION / f"{bid}.mp4"
    action = dur(src)
    narr = b.get("narration_voiced_s") or b["actual_duration_s"]
    b["narration_voiced_s"] = narr
    target = max(action, narr)
    frames = math.ceil(target * FPS - 1e-8)
    hold = frames / FPS - action
    with tempfile.TemporaryDirectory(prefix=".conform-", dir=MEDIA) as tmp:
        tmp = Path(tmp)
        framed(src, bid, tmp / "framed.mp4")
        src = tmp / "framed.mp4"
        parts = [src]
        if hold > 1 / FPS:
            ff("-sseof", "-0.05", "-i", str(src), "-frames:v", "1", str(tmp / "last.png"))
            ff("-loop", "1", "-i", str(tmp / "last.png"), "-vf", f"fps={FPS},{label('HOLD')}",
               "-t", f"{hold:.4f}", *VENC, str(tmp / "hold.mp4"))
            parts.append(tmp / "hold.mp4")
        lst = tmp / "list.txt"
        lst.write_text("".join(f"file '{p.as_posix()}'\n" for p in parts))
        ff("-f", "concat", "-safe", "0", "-i", str(lst), "-vf", "tpad=stop_mode=clone:stop_duration=1",
           "-frames:v", str(frames), *VENC, str(MEDIA / f"{bid}.mp4"))
    target = frames / FPS
    if narr < target - 0.005:
        mp3 = FILM / b["audio_file"]
        voiced = FILM / "mp3" / f"voiced-{bid}.mp3"
        if not voiced.exists():
            shutil.copy2(mp3, voiced)
        ff("-i", str(voiced), "-af", f"apad=whole_dur={target:.4f}", "-c:a", "libmp3lame", "-q:a", "2", str(mp3))
        b["narration_padded_to"] = round(target, 3)
    b["actual_duration_s"] = round(max(target, dur(FILM / b["audio_file"])), 3)
    held = max(0.0, hold) if hold > 1 / FPS else 0.0
    b["shot"]["conform"] = {"action_s": round(action, 3), "hold_s": round(held, 3), "frames": frames}
    out = MEDIA / f"{bid}.mp4"
    ledger["conformed"][bid] = {"path": f"media/{bid}.mp4", "sha256": sha(out),
                                "source": f"media/action/{bid}.mp4 at capture speed, scaled into media/frames/{bid}_frame.png"
                                          + (" + HOLD (labelled)" if held else ""),
                                "duration_s": round(dur(out), 3), "retimed_action": False}
    report.append(f"{bid}: capture {action:.2f}s + hold {held:.2f}s = {target:.3f}s ({frames} frames); "
                  f"narration {narr:.2f}s" + (f" -> padded to {target:.2f}s" if narr < target - 0.005 else ""))

sheet_path.write_text(json.dumps(sheet, indent=2, ensure_ascii=False), encoding="utf-8")
ledger_path.write_text(json.dumps(ledger, indent=2), encoding="utf-8")
print("\n".join(report))
