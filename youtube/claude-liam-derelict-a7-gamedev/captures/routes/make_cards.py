"""The A7 film's 3840x2160 stills (shared card style, cards.py, copied from the
A6 film; helpers copied from the A6 make_cards.py). Written by Claude Code.
Every image on a card is a real capture, the committed sheet or a committed strip
sheet, pasted unaltered apart from scaling/cropping (crops are labelled). Output
lines are copied verbatim from the named log; code lines are read from their file.

  python captures/routes/make_cards.py      -> media/Bxx.png
"""
import json, re
from pathlib import Path
from PIL import Image
from cards import card, footer, F, M, S, W, H, LEFT, RIGHT, CONTENT_W, INK, PAGE, ACCENT, MUTED

ROUTES = Path(__file__).resolve().parent
FILM = ROUTES.parents[1]
REPO = FILM.parents[1]
GAME = REPO / "godot"
FRAMES = FILM / "captures" / "frames"
MEDIA = FILM / "media"
LOGS = FILM / "logs"
EVID = REPO / "docs" / "evidence" / "a7"
STRIPS = REPO / "captures"
TOP_Y = 420
PANEL = (244, 242, 236)
HOT = (250, 226, 214)
CAP = "Godot 4.7.2 · Forward+ · 3840×2160 SubViewport capture"
FIX = "FIXTURE capture · Movie Maker 1280×720 @30 fps · run by Claude Code · read by Claude"


def fit(img, w, h):
    s = min(w / img.width, h / img.height)
    return img.resize((round(img.width * s), round(img.height * s)), Image.LANCZOS)


def paste(img, d, im, x, y, w, h, caption=None):
    p = fit(im.convert("RGB"), w, h)
    px = x + (w - p.width) // 2
    img.paste(p, (px, y))
    d.rectangle([px, y, px + p.width, y + p.height], outline=INK, width=4)
    if caption:
        d.text((px, y + p.height + 20), caption, font=S(42), fill=MUTED)
    return px, y, p.width, p.height


def wrap(d, text, font, width):
    out = []
    for para in text.split("\n"):
        line = ""
        for word in para.split(" "):
            t = (line + " " + word).strip()
            if d.textlength(t, font=font) <= width:
                line = t
            else:
                out.append(line)
                line = word
        out.append(line)
    return out


def block(d, x, y, text, font, width, fill=INK, gap=1.35):
    for line in wrap(d, text, font, width):
        d.text((x, y), line, font=font, fill=fill)
        y += round(font.size * gap)
    return y


def code(d, x, y, lines, font, gap=1.4, hot=()):
    for i, line in enumerate(lines):
        if i in hot:
            d.rectangle([x - 16, y - 8, x + d.textlength(line, font=font) + 16, y + font.size + 8], fill=HOT)
        d.text((x, y), line, font=font, fill=ACCENT if i in hot else INK)
        y += round(font.size * gap)
    return y


def save(img, bid):
    MEDIA.mkdir(parents=True, exist_ok=True)
    img.save(MEDIA / f"{bid}.png")
    print(bid, img.size)


def log_lines(path, keep):
    return [l for l in Path(path).read_text(encoding="utf-8").splitlines() if keep(l)]


def strip(img, d, rel, y, label, h=520):
    """A committed strip sheet (its own burnt-in header names the run)."""
    im = Image.open(STRIPS / rel)
    p = fit(im.convert("RGB"), CONTENT_W, h)
    img.paste(p, (LEFT, y))
    d.rectangle([LEFT, y, LEFT + p.width, y + p.height], outline=INK, width=4)
    d.text((LEFT, y + p.height + 14), label, font=S(40), fill=MUTED)
    return y + p.height + 80


def mono_lines(d, x, y, lines, size=46, gap=1.32, hot=lambda l: False):
    f = M(size)
    for l in lines:
        d.text((x, y), l, font=f, fill=ACCENT if hot(l) else INK)
        y += round(size * gap)
    return y



KP = FRAMES / "keyplay"
RP = FRAMES / "reloadplay"
FINAL = EVID / "final"

# --- B02: the game, the two clips ------------------------------------------------------------
img, d = card("Two clips, two jobs.")
w = (CONTENT_W - 80) // 2
paste(img, d, Image.open(KP / "f00060.jpg"), LEFT, TOP_Y, w, 1000,
      "1 · keycard spin, beside ◆ KEYCARD, top-left (keyplay frame 60)")
paste(img, d, Image.open(RP / "f00040.jpg"), LEFT + w + 80, TOP_Y, w, 1000,
      "2 · pistol reload, bottom-right, magazine dropping (reloadplay frame 40)")
block(d, LEFT, 1540, "1: route 1, Sprite2D KeycardIcon + AnimationPlayer frame track · 8 cells @ 12 fps · LOOP_LINEAR "
      "(the cycle).  2: route 3, Node2D cutout rig PistolRig (Body, Slide, Mag) · 24 fps · 1.25 s = RELOAD_TIME · "
      "LOOP_NONE (commits).  Both played only by HudAnim.", F(58), CONTENT_W)
footer(d, "SCRIPTED PLAY, real input · " + CAP + " · film_capture.gd · logs/film_capture_{keyplay,reloadplay}.log")
save(img, "B02")

# --- B05: the sheet, its slicing, the strip ----------------------------------------------------------
img, d = card("The sheet, sliced, then drawn.")
sheet = Image.open(GAME / "art/keycard_sheet.png").convert("RGBA")
bg = Image.new("RGBA", sheet.size, (40, 40, 40, 255))
bg.alpha_composite(sheet)
big = bg.convert("RGB").resize((sheet.width * 6, sheet.height * 6), Image.NEAREST)
img.paste(big, (LEFT, 360))
d.rectangle([LEFT, 360, LEFT + big.width, 360 + big.height], outline=INK, width=4)
for k in range(8):
    x = LEFT + k * 64 * 6
    d.line([x, 360, x, 360 + big.height], fill=ACCENT, width=4)
    d.text((x + 12, 360 + big.height + 14), f"frame {k} · {45 * k}°", font=S(40), fill=MUTED)
block(d, LEFT, 360 + big.height + 90, "keycard_sheet.png: 512 × 64 px, generated by tools/make_keycard_sheet.py "
      "(Pillow). Sprite2D hframes 8, vframes 1: frame k is the 64 × 64 cell at x = 64k. Width scales as |cos θ|; back face on cells 3–5.",
      F(52), CONTENT_W)
y = strip(img, d, "keycard_spin/r0-light-strip.png", 1000, "r0 light: first frame of each cell, then 36 = after the wrap · read by Claude", h=400)
block(d, LEFT, y, "Drawn in order 0 → 7, then cell 0 again on frame 36: no repeat across the wrap. Bounding-box centre "
      "within 0.5 px in every cell (registration).", F(56), CONTENT_W)
footer(d, "godot/art/keycard_sheet.png (×6, nearest, on grey) · " + FIX + " · TUNING.md")
save(img, "B05")

# --- B07: the phase table beside the key times and the strip --------------------------------------------
img, d = card("Feel, written in frames.")
rows = [("phase", "frames @24", "time", "keys (reload.tres)", "drawn @30 (strip)"),
        ("startup", "0–11", "0–0.500 s", "f6 0.25 tilt −0.21 · f12 0.5 mag 64", "frame 26: mag out, tilted"),
        ("active", "12–23", "0.500–1.000 s", "f18 0.75 seated · f21 0.875 rack −24", "frame 39: slide back −18.8"),
        ("recovery", "24–29", "1.000–1.250 s", "f24 1.0 slide home · f30 1.25 level", "frame 48: rest (HOLD)")]
y = 360
for i, r in enumerate(rows):
    for j, c in enumerate(r):
        d.text((LEFT + [0, 420, 820, 1300, 2500][j], y), c, font=(S(46) if i == 0 else S(50)), fill=MUTED if i == 0 else INK)
    y += 84
y = strip(img, d, "pistol_reload/r2-light-strip.png", y + 40, "r2 light: frames 10, 24–26, 39–41, 47–48, 50 (R seen on frame 10) · read by Claude", h=470)
block(d, LEFT, y, "Every boundary is drawn one capture frame after the brief's list (26, not 25): the clip holds position 0 "
      "for one tick after play(). The two clocks, measured.", F(54), CONTENT_W)
footer(d, "CHANGE-BRIEF.md phase table · godot/animations/pistol_reload.tres · " + FIX)
save(img, "B07")

# --- B13: the two clocks -----------------------------------------------------------------------------------
img, d = card("Two clocks, one frame apart.")
y = 360
for fps in (60, 30):
    ls = log_lines(FINAL / f"test_two_clocks_{fps}fps.log" if fps == 60 else EVID / "two_clocks" / "test_two_clocks_30fps.log",
                   lambda l: l.startswith(("  process delta", "  reload  t(false)", "  1 ", "  2 ", "  largest", "  brief's")))
    ls = [l if len(l) < 120 else l[:117] + "…" for l in ls]
    y = mono_lines(d, LEFT, y, ls, size=40, hot=lambda l: l.startswith("  largest")) + 40
block(d, LEFT, y + 10, "The game ends the reload on tick 75 (60 fps) or 38 (30 fps). An unstopped copy of the clip ends one "
      "tick later, on every reload: 0.0167 s and 0.0333 s. The brief predicted under one frame; it is exactly one.",
      F(56), CONTENT_W)
footer(d, "Recorded output, verbatim (long lines cut with …) · docs/evidence/a7/two_clocks/ · test_two_clocks.gd")
save(img, "B13")

# --- B14: tuning ---------------------------------------------------------------------------------------------
img, d = card("Tuning: one change, one prediction, each.")
y = strip(img, d, "pistol_reload/r0-light-strip.png", 340, "r0: as built · magazine runs off the window at 24–26; hint text crosses the grip", h=330)
y = strip(img, d, "pistol_reload/r1-light-strip.png", y - 20, "r1: RIG_OFFSET y −110 → −190 · whole magazine on screen · kept", h=330)
y = strip(img, d, "pistol_reload/r2-light-strip.png", y - 20, "r2: slide rack f21 −14 → −24 px · frame 39 rack reads · kept", h=330)
block(d, LEFT, y - 20, "Each prediction committed before its edit; approved by Claude, pre-authorised in A7-RUNBOOK.md. "
      "Student's verdicts: pending, not yet performed.", F(50), CONTENT_W)
footer(d, FIX + " · TUNING.md reload r0–r2 · brief revision 2026-11-20 (r2)")
save(img, "B14")

# --- B15: tests, mutations, limits ---------------------------------------------------------------------------
img, d = card("What the tests proved.")
rows = [("Read-backs", "32 / 57 PASS lines", "tracks resolve; key times, step, loop mode; frames in the sheet; length = RELOAD_TIME"),
        ("Structure", "51", "the tables match the brief; one writer; autoplay empty; PAUSABLE; PROCESS_IDLE"),
        ("State", "34", "real R / Esc / fire; real zombie swipe; pause freezes clip and timer"),
        ("Edges", "98", "fire, R, death at ticks 29–31, 59–61, 74–76"),
        ("Pins", "19 = 19", "before wiring and after: state order, 0.15 s shots, 75-frame reload, refill"),
        ("Mutations 1–3", "exit 1 ×3", "track property renamed · LOOP_NONE · frame key 8"),
        ("Mutation 4", "exit 0", "delete .godot + reimport: clips are .tres text, nothing to reimport"),
        ("Earlier suites", "baseline", "27 ok · PASS · 3 · 5 · 36 ×3 · 75 · 1 · 109 · 35 · 40 · 22")]
y = 360
for a, b, c in rows:
    d.text((LEFT, y), a, font=S(50), fill=INK)
    d.text((LEFT + 560, y), b, font=M(48), fill=ACCENT)
    y = block(d, LEFT + 1160, y, c, S(46), CONTENT_W - 1160) + 26
block(d, LEFT, y + 20, "Not provable headless: how either clip looks, whether the phases feel distinct, whether the icon "
      "catches the eye. That is the student's check.", F(54), CONTENT_W)
footer(d, "docs/evidence/a7/final/*.log · docs/evidence/a7/mutations/README.md")
save(img, "B15")

# --- B16: mistakes, uncertainty, next --------------------------------------------------------------------------
img, d = card("Mistakes caught, and what's still unknown.")
items = ["The brief put the card's back face on cells 4–7; a turning card shows it on 3–5. Fixed by a dated revision.",
         "The first strips put the rig over black void: the floor under a bottom-right HUD element is south-east of the player.",
         "Claude Code's own test bugs: a lambda assigning a captured local; a check broken by the clip's one-tick hold.",
         "Two commit messages miscounted test lines (20 for 19, 50 for 51); corrected in A7-LOG.",
         "The two-clocks prediction missed: one frame, not under one.",
         "Uncertain: every look claim is Claude's. Next: the student plays it, with an interrupt in every phase."]
y = 380
for t in items:
    d.text((LEFT, y), "•", font=F(64), fill=ACCENT)
    y = block(d, LEFT + 70, y, t, F(54), CONTENT_W - 70) + 34
footer(d, "A7-LOG.md · git history · CHANGE-BRIEF.md revisions · HUMAN-CHECK-NOTES.md")
save(img, "B16")

# --- B17: credits -----------------------------------------------------------------------------------------------
img, d = card("Who wrote what.")
items = [("Claude", "the brief, its predictions, the phase table, the cycle spec and every approval"),
         ("Claude Code", "the sheet generator, the clips, the rig, HudAnim, tests, pins, previews, captures, strip readings, documents and this film"),
         ("The sheet", "generated by tools/make_keycard_sheet.py on 2026-11-20; no third-party art, no licence"),
         ("The student", "ran the kit and handed the approvals to Claude; every human check and tuning verdict pending"),
         ("Revision shown", "game source 0d8710e · branch a7-animation · Godot 4.7.2, Forward+")]
y = 400
for a, b in items:
    d.text((LEFT, y), a, font=S(56), fill=ACCENT)
    y = block(d, LEFT + 820, y, b, F(58), CONTENT_W - 820) + 50
footer(d, "SOURCES.md (A7 section) · ATTRIBUTION.md · TEST-REPORT.md")
save(img, "B17")
