"""The A6 film's 3840x2160 stills (shared card style, cards.py, copied from the
A5 film; helpers copied from the A5 make_cards.py). Written by Claude Code.
Every image on a card is a real capture or a committed strip sheet, pasted
unaltered apart from scaling/cropping (crops are labelled). Output lines are
copied verbatim from the named log; every code line is read from its file.

  python captures/routes/make_cards.py      -> media/Bxx.png

Captures: captures/routes/film_capture.gd (burstplay, smokeplay; frames under
captures/frames/, git-ignored) and the repo's committed fixture strips
captures/{impact_burst,wound_smoke}/r*/strip.png.
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
EVID = REPO / "docs" / "evidence" / "a6"
STRIPS = REPO / "captures"
TOP_Y = 420
PANEL = (244, 242, 236)
HOT = (250, 226, 214)
CAP = "Godot 4.7.2 · Forward+ · 3840×2160 SubViewport capture"
FIX = "FIXTURE capture · Movie Maker 1280×720 @30 fps · preview seed 12345 · HUD hidden"


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


BP = FRAMES / "burstplay"
SP = FRAMES / "smokeplay"
FINAL = EVID / "final"

# --- B02: the game, the two effects ---------------------------------------------------------
img, d = card("Two effects, two jobs.")
w = (CONTENT_W - 80) // 2
paste(img, d, Image.open(BP / "f00040.jpg"), LEFT, TOP_Y, w, 1000, "A · impact burst: a bullet hits a zombie (burstplay frame 40)")
paste(img, d, Image.open(SP / "f00190.jpg"), LEFT + w + 80, TOP_Y, w, 1000, "B · wound smoke: hp 46, walking (smokeplay frame 190)")
block(d, LEFT, 1560, "A: event = player.bullet_hit(point, normal), emitted where fire() resolves a hit on a victim. "
      "B: condition = hp ≤ 60 and alive, from health_changed; amount_ratio = clamp((60 − hp) / 50, 0.2, 1.0).",
      F(60), CONTENT_W)
footer(d, "SCRIPTED PLAY, real input · " + CAP + " · film_capture.gd · logs/film_capture_{burstplay,smokeplay}.log")
save(img, "B02")

# --- B05: Effect A, the first strip --------------------------------------------------------------
img, d = card("Effect A, first strip (r0).")
y = strip(img, d, "impact_burst/r0/strip.png", 380, "Dark: Assembly Hall corner, flashlight pool · read by Claude")
y = strip(img, d, "impact_burst/r0-light/strip.png", y, "Light: Loading Bay floor under the lamp · read by Claude")
block(d, LEFT, y + 10, "Brief: flash on the trigger frame; sparks out by +5; puff widest at +10; gone by +40.  Strip: "
      "nothing on frame 10, everything one frame late; flash gone by +2; the puff is a 0.5 m red-brown disc from the "
      "first frame and never grows.", F(54), CONTENT_W)
footer(d, FIX + " · captures/impact_burst/r0*/strip.png · TUNING.md")
save(img, "B05")

# --- B09: what the state test proved -------------------------------------------------------------
img, d = card("Real fire, counted.")
keep = ("A1 exactly one burst", "A1 burst at the hit point", "A4 burst", "A1 a shot that hits no victim",
        "A2 two live bursts", "A2 node truth", "A3 10 frames later", "A2 continuous fire keeps",
        "A2 the oldest burst")
ls = log_lines(FINAL / "test_impact_burst_state_60fps.log",
               lambda l: l.startswith(("  held fire", "  finished signals", "PASS: 0")) or any(l.startswith("PASS " + k) for k in keep))
ls = [l if len(l) < 118 else l[:115] + "…" for l in ls]
y = mono_lines(d, LEFT, 380, ls, size=44, hot=lambda l: l.startswith("PASS:"))
block(d, LEFT, y + 30, "34 PASS at 60 fps. Aim is a real mouse event, fire is the real fire action. The pool-exhausted "
      "case uses 13 test-emitted signals: continuous fire never fills the pool.", F(56), CONTENT_W)
footer(d, "Recorded output, verbatim (long lines cut with …) · docs/evidence/a6/final/test_impact_burst_state_60fps.log")
save(img, "B09")

# --- B10: tuning A-r1 -------------------------------------------------------------------------------
img, d = card("Tuning A-r1: one setting, reverted.")
y = strip(img, d, "impact_burst/r0/strip.png", 360, "Before (r0): billboard_keep_scale false · dark", h=380)
y = strip(img, d, "impact_burst/r1/strip.png", y, "After (r1): Puff billboard_keep_scale true · dark", h=380)
block(d, LEFT, y + 10, "Prediction (committed before the edit): the puff grows about 2x in the frames read, but as small "
      "dark-red dots, likely too weak over the light floor. Result: it grows, to about 0.07 m: specks. "
      "Decision: reverted. Approved by Claude, pre-authorised in A6-RUNBOOK.md. "
      "Student's verdict: pending, not yet performed.", F(52), CONTENT_W)
footer(d, "FIXTURE captures · TUNING.md A-r1 · commits 3f2e7d6 (prediction), 446dad4, f6eeac4 (revert)")
save(img, "B10")

# --- B12: Effect B strips -----------------------------------------------------------------------------
img, d = card("Effect B: r0 to r2.")
y = strip(img, d, "wound_smoke/r0-dark/strip.png", 360, "r0 (table as written) · dark", h=400)
y = strip(img, d, "wound_smoke/r2-dark/strip.png", y, "r2 (spread 70, turbulence influence 0.03) · dark", h=400)
rows = [("pixels changed vs a no-smoke control", "frame 40", "frame 100", "frame 130"),
        ("r0  light / dark", "116 / 108", "127 / 471", "277 / 1501"),
        ("r1  light / dark", "198 / 232", "150 / 796", "374 / 1552"),
        ("r2  light / dark", "512 / 522", "558 / 1050", "1008 / 2166")]
for i, r in enumerate(rows):
    for j, c in enumerate(r):
        d.text((LEFT + [0, 1500, 2150, 2800][j], y + i * 78), c, font=(S(46) if i == 0 else M(46)),
               fill=MUTED if i == 0 else INK)
footer(d, "FIXTURE captures, seed 12345 · TUNING.md B-r1, B-r2 · docs/evidence/a6/wound_smoke_r*_diff_vs_control.png")
save(img, "B12")

# --- B15: tuning B --------------------------------------------------------------------------------------
img, d = card("Tuning B: a failed prediction, then a cause.")
w3 = (CONTENT_W - 120) // 3
for i, (pth, cap) in enumerate([(EVID / "wound_smoke_r1_dark_diff_vs_control.png", "B-r1 spread 70: diff vs control"),
                                (EVID / "diag_wound_smoke_spread70_turbulence_off.png", "diagnostic: turbulence OFF (not kept)"),
                                (EVID / "wound_smoke_r2_dark_diff_vs_control.png", "B-r2 influence 0.03: diff vs control")]):
    paste(img, d, Image.open(pth), LEFT + i * (w3 + 60), 400, w3, 520, cap)
block(d, LEFT, 1080, "B-r1, spread 25 to 70. Predicted: a 1-2 m cloud, thousands of changed pixels. Got: 796 at frame "
      "100. Failed. A throwaway run with turbulence off: 2200, wisps by frame 40. The default turbulence influence, 0.1, "
      "was pinning the wisps. B-r2, influence 0.1 to 0.03: 1050, wisps by +0.5 s. Both kept. Each approved by Claude, "
      "pre-authorised. Student's verdicts: pending.", F(56), CONTENT_W)
footer(d, "TUNING.md B-r1, B-r2 · counts in a ±130 px window around the player")
save(img, "B15")

# --- B17: generated shader lines beside the brief, and what the draw step does ------------------------------
img, d = card("Computed here, dropped at the draw.")
gl = (GAME / "shaders/particles_generated.gdshader").read_text(encoding="utf-8").splitlines()
for i, (n, note) in enumerate([(161, "brief: Puff scale curve 0.5 → 1.6"), (162, "brief: Puff colour ramp (0.23, 0.06, 0.04)"),
                               (358, "the scale is written into the particle's TRANSFORM")]):
    y = 400 + i * 200
    d.text((LEFT, y), f"{n}", font=M(48), fill=MUTED)
    d.text((LEFT + 160, y), gl[n - 1].strip(), font=M(48), fill=INK)
    d.text((LEFT + 160, y + 70), note, font=S(44), fill=ACCENT)
probe = log_lines(EVID / "probe_particle_scale.log", lambda l: l.startswith("quad"))
mono_lines(d, LEFT, 1050, [probe[1], probe[3]], size=40)
block(d, LEFT, 1250, "Same 1 m quad, scale 0.5: drawn 72 px with billboard_keep_scale false, 36 px with it true. "
      "The process shader writes the scale; the billboard draw step throws it away unless told to keep it. "
      "That is why the r0 puff never grew.", F(56), CONTENT_W)
footer(d, "godot/shaders/particles_generated.gdshader (generated by Godot 4.7.2) · probe_particle_scale.log, windowed, RTX 4050")
save(img, "B17")

# --- B18: tests, mutations, price -------------------------------------------------------------------------
img, d = card("What the tests proved, and the price.")
rows = [("Config A / B", "108 / 39 PASS", "every brief setting read back from the scene"),
        ("State A / B", "34 / 21 PASS", "real fire, real zombie damage, a real medkit"),
        ("Godot 3 rename", "exit 1", "initial_velocity_min silently fell to 0.0; the effect still fired"),
        ("Value change", "exit 1", "Puff velocity 0.6 to 0.9; turbulence 0.6 to 1.2"),
        ("Earlier suites", "baseline", "27 ok · PASS · 3 ok · 7 ok · 35 x3 · 74 · PASS")]
y = 380
for a, b, c in rows:
    d.text((LEFT, y), a, font=S(52), fill=INK)
    d.text((LEFT + 760, y), b, font=M(52), fill=ACCENT)
    d.text((LEFT + 1300, y), c, font=S(48), fill=INK)
    y += 100
gpu = log_lines(EVID / "gpu_price.log", lambda l: l.startswith(("Effect A worst over", "Effect B ratio 1.0 over", "FPS")))
y = mono_lines(d, LEFT, y + 40, gpu, size=44)
block(d, LEFT, y + 30, "GPU: both effects at the counter's noise floor, far inside 0.30 and 0.20 ms. Headless CPU: "
      "near zero by construction, no particle shader runs there. Not provable headless: anything you see.", F(54), CONTENT_W)
footer(d, "docs/evidence/a6/final/*.log · gpu_price.log (script reading the RenderingServer GPU counter, run by Claude Code)")
save(img, "B18")

# --- B19: mistakes, uncertainty, next ------------------------------------------------------------------------
img, d = card("Mistakes caught, and what's still unknown.")
items = ["Claude Code's state test used 'emitting' as alive: a one-shot emitter turns it off when emission ends, "
         "two frames in. Held fire showed one burst. Fixed with a clock, checked against 'finished'.",
         "Mouse aim in the 64x64 headless window is stretched 20x; a disabled zombie leaves physics. Both found by "
         "failing tests.",
         "A commit message said 22 PASS; the log says 21. Corrected in A6-LOG.",
         "B-r1's prediction was wrong; the cause was found, not guessed.",
         "Uncertain: every look claim here is Claude's. Next: the student plays it and records what they see."]
y = 400
for t in items:
    d.text((LEFT, y), "•", font=F(64), fill=ACCENT)
    y = block(d, LEFT + 70, y, t, F(56), CONTENT_W - 70) + 40
footer(d, "A6-LOG.md · git history · HUMAN-CHECK-NOTES.md")
save(img, "B19")

# --- B20: credits ----------------------------------------------------------------------------------------------
img, d = card("Who wrote what.")
items = [("Claude", "the brief, its predictions, budgets and answers; the tuning approvals; the process-shader notes"),
         ("Claude Code", "the effects, previews, trigger code, tests, cost and GPU scripts, strip readings, documents and this film"),
         ("Godot 4.7.2", "particles_generated.gdshader"),
         ("The student", "ran the kit and accepted the two effects; every human check and tuning verdict pending"),
         ("Textures", "none external: radial GradientTexture2D soft dots written in the scenes"),
         ("Revision shown", "game source f4af1c4 · branch a6-effects")]
y = 400
for a, b in items:
    d.text((LEFT, y), a, font=S(56), fill=ACCENT)
    y = block(d, LEFT + 820, y, b, F(58), CONTENT_W - 820) + 50
footer(d, "SOURCES.md (A6 section) · TEST-REPORT.md")
save(img, "B20")
