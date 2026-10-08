"""Writes SCRIPT.md (the spoken narration, in order) from beat_sheet.json."""
import json
from pathlib import Path

FILM = Path(__file__).resolve().parent
sheet = json.loads((FILM / "beat_sheet.json").read_text(encoding="utf-8"))
out = [f"# SCRIPT — {sheet['metadata']['title']}", "",
       "Narrator: Liam (in for Bear), Kokoro `am_onyx`. Generated from beat_sheet.json; edit there, not here.", ""]
total = 0.0
for b in sheet["beats"]:
    shot = b["shot"]
    visual = (shot.get("remotion") or {}).get("pattern") or shot.get("evidence_media") or shot.get("type")
    text = b["narration_text"]
    total += b["estimated_duration_s"]
    out.append(f"**{b['beat_id']} · {b['act']}** · ~{b['estimated_duration_s']:.0f}s · {len(text.split())} words · _{visual}_")
    out.append("")
    if b.get("audio_policy") == "preserve":
        out.append("> *(no narration: the game's own audio plays: shot, collapse, music)*")
    elif b.get("audio_policy") == "silence":
        out.append(f"> *(card is silent apart from the stock jingle; sign-off recorded as: \"{text}\")*")
    else:
        out.append(f"> {text}")
    out.append("")
out.append(f"_Estimated total: {total:.0f} s ({total / 60:.1f} min) at 2.5 words/s, before measurement._")
(FILM / "SCRIPT.md").write_text("\n".join(out) + "\n", encoding="utf-8")
print("wrote SCRIPT.md")
