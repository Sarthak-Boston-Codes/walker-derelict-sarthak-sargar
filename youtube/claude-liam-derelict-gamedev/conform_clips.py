"""Conform each gameplay result clip to its beat's exact length, without
retiming the captured action (capture contract).

  target = max(action [+ labelled replay], measured narration)
  - narration shorter -> narration mp3 padded with trailing silence to target
  - narration longer  -> labelled HOLD (last frame) appended to the video
B07 also gets a labelled 0.5x REPLAY after the real-speed action (its
narration names events the 1.3 s action has already finished).
B12 (audio_policy: preserve) is copied untouched: its clock is the clip.

Outputs media/Bxx.mp4 at exactly round(target*30) frames, updates
beat_sheet.json (actual_duration_s, narration_padded_to) and MEDIA-LEDGER.json.

  python conform_clips.py
"""
import hashlib, json, math, shutil, subprocess, tempfile
from pathlib import Path

FILM = Path(__file__).resolve().parent
MEDIA, ACTION = FILM / "media", FILM / "media" / "action"
FPS = 30
FONT = "C\\:/Windows/Fonts/consola.ttf"
REPLAY = {"B07": 0.5}
BEATS = ["B07", "B09", "B11", "B14", "B21"]
# HUD backing (author-approved option A): inside the HUD readout box, every pixel
# that is not near-white HUD text is darkened to 30% brightness, so the debug text
# reads against the bright floor art. Text pixels (min channel >= 200) are untouched.
# Same box is declared to final_frame_check as the beats' contrast region.
HUD_BOX = (0.012, 0.035, 0.30, 0.195)
HUD_DARKEN = 0.30


def hud_backing():
    x0, y0, x1, y1 = HUD_BOX
    inside = f"between(X,W*{x0},W*{x1})*between(Y,H*{y0},H*{y1})*lt(min(min(r(X,Y),g(X,Y)),b(X,Y)),200)"
    ch = lambda c: f"if({inside},{c}(X,Y)*{HUD_DARKEN},{c}(X,Y))"
    return f"format=rgb24,geq=r='{ch('r')}':g='{ch('g')}':b='{ch('b')}',format=yuv420p"


def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()


def dur(p):
    return float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                                 str(p)], capture_output=True, text=True).stdout)


def ff(*args):
    subprocess.run(["ffmpeg", "-v", "error", "-y", *args], check=True)


def label(text):
    # Top-centre: the top-left holds the HUD readout, which is on-screen evidence.
    return (f"drawtext=fontfile='{FONT}':text='{text}':x=(w-text_w)/2:y=40:fontsize=54:fontcolor=white:"
            f"box=1:boxcolor=0xD97757@0.92:boxborderw=18")


VENC = ["-c:v", "libx264", "-preset", "medium", "-crf", "12", "-pix_fmt", "yuv420p", "-r", str(FPS), "-an"]

sheet_path = FILM / "beat_sheet.json"
sheet = json.loads(sheet_path.read_text(encoding="utf-8"))
beats = {b["beat_id"]: b for b in sheet["beats"]}
ledger_path = FILM / "MEDIA-LEDGER.json"
ledger = json.loads(ledger_path.read_text(encoding="utf-8"))
ledger["media"] = [m for m in ledger["media"] if not (m["path"].startswith("media/B") and m["path"].endswith(".mp4"))]
report = []

for bid in BEATS:
    b = beats[bid]
    src = ACTION / f"{bid}.mp4"
    action = dur(src)
    # Narration length is the voiced length before any earlier padding.
    narr = b.get("narration_voiced_s") or b["actual_duration_s"]
    b["narration_voiced_s"] = narr
    with tempfile.TemporaryDirectory(prefix=".conform-", dir=MEDIA) as tmp:
        tmp = Path(tmp)
        # Backing applied once to the action; replay and hold are cut from it.
        backed = tmp / "backed.mp4"
        ff("-i", str(src), "-vf", f"fps=30,{hud_backing()}", *VENC, str(backed))
        src = backed
        parts = [tmp / "a.mp4"]
        ff("-i", str(src), "-vf", "fps=30", *VENC, str(parts[0]))
        built = action
        if bid in REPLAY:
            k = REPLAY[bid]
            parts.append(tmp / "replay.mp4")
            ff("-i", str(src), "-vf", f"fps=30,setpts=PTS/{k},{label(f'REPLAY {k}x')}", *VENC, str(parts[-1]))
            built += action / k
        target = max(built, narr)
        hold = target - built
        if hold > 1 / FPS:
            parts.append(tmp / "hold.mp4")
            ff("-sseof", "-0.05", "-i", str(src), "-frames:v", "1", str(tmp / "last.png"))
            ff("-loop", "1", "-i", str(tmp / "last.png"), "-vf", f"fps=30,{label('HOLD')}",
               "-t", f"{hold:.4f}", *VENC, str(parts[-1]))
        lst = tmp / "list.txt"
        lst.write_text("".join(f"file '{p.as_posix()}'\n" for p in parts))
        # compile.py renders ceil(duration * fps) frames; match it so nothing is retimed.
        frames = math.ceil(target * FPS - 1e-8)
        ff("-f", "concat", "-safe", "0", "-i", str(lst), "-vf", "tpad=stop_mode=clone:stop_duration=1",
           "-frames:v", str(frames), *VENC, str(MEDIA / f"{bid}.mp4"))
    target = frames / FPS
    # Narration shorter than the action: pad the mp3 with silence (never retime video).
    if narr < target - 0.005:
        mp3 = FILM / b["audio_file"]
        voiced = FILM / "mp3" / f"voiced-{bid}.mp3"
        if not voiced.exists():
            shutil.copy2(mp3, voiced)
        ff("-i", str(voiced), "-af", f"apad=whole_dur={target:.4f}", "-c:a", "libmp3lame", "-q:a", "2", str(mp3))
        b["narration_padded_to"] = round(target, 3)
    b["actual_duration_s"] = round(max(target, dur(FILM / b["audio_file"])), 3)
    b["shot"]["conform"] = {"action_s": round(action, 3), "replay": REPLAY.get(bid),
                            "hold_s": round(max(0.0, target - built), 3), "frames": frames}
    out = MEDIA / f"{bid}.mp4"
    ledger["media"].append({"path": f"media/{bid}.mp4", "sha256": sha(out), "beat": bid,
                            "hud_backing": {"box": list(HUD_BOX), "darken": HUD_DARKEN},
                            "source": f"media/action/{bid}.mp4 at capture speed, HUD backing"
                                      + (f" + REPLAY {REPLAY[bid]}x (labelled)" if bid in REPLAY else "")
                                      + (" + HOLD (labelled)" if target - built > 1 / FPS else ""),
                            "duration_s": round(dur(out), 3), "retimed_action": False})
    report.append(f"{bid}: action {action:.2f}s"
                  + (f" + replay {action / REPLAY[bid]:.2f}s" if bid in REPLAY else "")
                  + f" + hold {max(0.0, target - built):.2f}s = {target:.3f}s ({frames} frames); "
                  f"narration {narr:.2f}s" + (f" -> padded to {target:.2f}s" if narr < target - 0.005 else ""))

# B12: preserve beat, the action's own clock and audio. Video stream-copied (timing
# untouched); audio gets one fixed -10 dB gain, because the raw game mix measured
# ~16 dB louder than the narration around it (review cut: -11.3 vs -27 dB RMS).
# Gain only: it lowers the level but cannot undo clipping baked into the source SFX.
B12_GAIN_DB = -10
ff("-i", str(ACTION / "B12.mp4"), "-c:v", "copy", "-af", f"volume={B12_GAIN_DB}dB",
   "-c:a", "aac", "-b:a", "256k", str(MEDIA / "B12.mp4"))
ledger["media"].append({"path": "media/B12.mp4", "sha256": sha(MEDIA / "B12.mp4"), "beat": "B12",
                        "source": f"media/action/B12.mp4: video stream-copied; audio {B12_GAIN_DB} dB fixed gain "
                                  "(level only; preserve beat; game audio kept)",
                        "duration_s": round(dur(MEDIA / "B12.mp4"), 3), "retimed_action": False,
                        "audio_gain_db": B12_GAIN_DB})
beats["B12"]["actual_duration_s"] = round(dur(MEDIA / "B12.mp4"), 3)
report.append(f"B12: preserve, video stream-copied, audio {B12_GAIN_DB} dB, {beats['B12']['actual_duration_s']:.3f}s")

sheet_path.write_text(json.dumps(sheet, indent=2, ensure_ascii=False), encoding="utf-8")
ledger_path.write_text(json.dumps(ledger, indent=2), encoding="utf-8")
print("\n".join(report))
