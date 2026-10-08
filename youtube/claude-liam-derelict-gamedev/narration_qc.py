"""Narration QC + B01 lead silence.

lead_silence_s is required by ai-explainer for B01 but nothing in the runtime
applies it, so it is baked into the mp3 here (once; idempotent via a marker in
the sheet) and the measured duration is updated.

  python narration_qc.py
"""
import json, subprocess
from pathlib import Path
import numpy as np

FILM = Path(__file__).resolve().parent
SHEET = FILM / "beat_sheet.json"
sheet = json.loads(SHEET.read_text(encoding="utf-8"))


def probe(p):
    return float(subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                                 str(p)], capture_output=True, text=True).stdout)


def pcm(p):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", str(p), "-ac", "1", "-ar", "24000", "-f", "s16le", "-"],
                         capture_output=True).stdout
    return np.frombuffer(raw, np.int16).astype(float) / 32768


changed = False
for b in sheet["beats"]:
    lead = b.get("lead_silence_s")
    if lead and b.get("audio_file") and b.get("lead_silence_baked") != lead:
        mp3 = FILM / b["audio_file"]
        tmp = mp3.with_suffix(".lead.mp3")
        ms = int(lead * 1000)
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", str(mp3), "-af", f"adelay={ms}:all=1",
                        "-c:a", "libmp3lame", "-q:a", "2", str(tmp)], check=True)
        tmp.replace(mp3)
        b["actual_duration_s"] = round(probe(mp3), 2)
        b["lead_silence_baked"] = lead
        changed = True
        print(f"{b['beat_id']}: baked {lead}s lead silence -> {b['actual_duration_s']}s")
if changed:
    SHEET.write_text(json.dumps(sheet, indent=2, ensure_ascii=False), encoding="utf-8")
    timings = FILM / "mp3" / "timings.json"
    t = json.loads(timings.read_text())
    t.update({b["beat_id"]: b["actual_duration_s"] for b in sheet["beats"] if b.get("audio_file")})
    timings.write_text(json.dumps(t, indent=2))

print(f"\n{'beat':5} {'dur':>6} {'words':>5} {'w/s':>5} {'peak dB':>8} {'rms dB':>7} {'lead s':>6} {'tail s':>6}  flags")
total = 0.0
for b in sheet["beats"]:
    if not b.get("audio_file"):
        continue
    x = pcm(FILM / b["audio_file"])
    dur = b["actual_duration_s"]
    total += dur
    words = len(b["narration_text"].split())
    speech = np.abs(x) > 10 ** (-40 / 20)
    idx = np.nonzero(speech)[0]
    lead = idx[0] / 24000 if len(idx) else dur
    tail = (len(x) - idx[-1]) / 24000 if len(idx) else dur
    peak = 20 * np.log10(np.abs(x).max())
    rms = 20 * np.log10(np.sqrt((x ** 2).mean()))
    spoken = dur - (b.get("lead_silence_baked") or 0)
    wps = words / spoken
    flags = []
    if peak > -0.3: flags.append("CLIP?")
    if wps < 2.0 or wps > 3.6: flags.append("RATE?")
    if tail > 1.0: flags.append("LONG TAIL")
    if lead > 0.5 and not b.get("lead_silence_baked"): flags.append("LONG LEAD")
    print(f"{b['beat_id']:5} {dur:6.2f} {words:5d} {wps:5.2f} {peak:8.1f} {rms:7.1f} {lead:6.2f} {tail:6.2f}  {' '.join(flags)}")
print(f"\nnarrated total {total:.1f}s; plus B12 4.0s + B26 7.0s = {total + 11:.1f}s ({(total + 11) / 60:.1f} min)")
