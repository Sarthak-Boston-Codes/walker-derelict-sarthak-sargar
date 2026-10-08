"""B05 (placeholder vs real) and B16 (facing grids) stills, each rendered from an
isolated copy of the game so the real project is never modified.

  python make_stills.py SCRATCH_DIR
"""
import re, shutil, subprocess, sys, tarfile, io, os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

GODOT = r"C:\Users\sarth\GotDot\Godot_v4.7.2-stable_win64.exe"
ROUTES = Path(__file__).resolve().parent
FILM = ROUTES.parents[1]
REPO = FILM.parents[1]
MEDIA = FILM / "media"
SCRATCH = Path(sys.argv[1])
font = ImageFont.truetype("C:/Windows/Fonts/consola.ttf", 22)


def run(args, **kw):
    r = subprocess.run(args, capture_output=True, text=True, encoding="utf-8", errors="replace", **kw)
    for line in (r.stdout + r.stderr).splitlines():
        if "SCRIPT ERROR" in line or "Parse Error" in line:
            print("   ", line)
    return r


def isolated_copy(name, rev=None):
    """Copy godot/ (working tree, or a git revision) without the .godot cache, then import."""
    dst = SCRATCH / name
    if dst.exists():  # \\?\ prefix: the imported .godot cache has paths past MAX_PATH
        shutil.rmtree("\\\\?\\" + str(dst.resolve()))
    if rev:
        tar = subprocess.run(["git", "-C", str(REPO), "archive", rev, "godot"], capture_output=True, check=True).stdout
        tarfile.open(fileobj=io.BytesIO(tar)).extractall(dst, filter="data")
        dst = dst / "godot"
    else:
        shutil.copytree(REPO / "godot", dst, ignore=shutil.ignore_patterns(".godot"))
    run([GODOT, "--headless", "--path", str(dst), "--import"])
    return dst


def screenshot(project, out):
    # 1920x1080 window: canvas_items stretch renders the 1280x720 room at 1.5x,
    # so the 4K card is composed from pixels instead of upscaled ones.
    env = dict(os.environ, SHOT_PATH=str(out))
    run([GODOT, "--path", str(project), "--resolution", "1920x1080", "-s", str(ROUTES / "shot_room.gd")], env=env)
    return Image.open(out).convert("RGB")


def label(img, text):
    d = ImageDraw.Draw(img)
    w = d.textlength(text, font=font)
    d.rectangle([0, img.height - 40, w + 24, img.height], fill=(0, 0, 0))
    d.text((12, img.height - 34), text, font=font, fill=(255, 255, 255))
    return img


# --- B05: same spawn frame, placeholders vs real art --------------------------
real = isolated_copy("iso_real")
blank = isolated_copy("iso_placeholders")
manifest = blank / "assets" / "asset_manifest.gd"
src = manifest.read_text(encoding="utf-8")
art_block = re.search(r"const ART := \{.*?\n\}", src, re.S).group(0)
blanked = re.sub(r'(": )"res://[^"]*"', r'\1""', art_block)
manifest.write_text(src.replace(art_block, blanked), encoding="utf-8")
print("B05 isolated copy: ART paths blanked ->", blanked.count('""'), "of 11")
a = screenshot(blank, SCRATCH / "b05_placeholders.png")
b = screenshot(real, SCRATCH / "b05_real.png")
print("B05 screenshot sizes:", a.size, b.size)
# Native 3840x2160 card on the film's cream page (no letterbox, no upscale).
from cards import card, footer, F, S, INK, MUTED, LEFT, CONTENT_W
img, d = card("Same frame, same code.")
gap = 80
pw = (CONTENT_W - gap) // 2  # both panels inside title-safe
for i, (shot, cap) in enumerate([(a, "Isolated copy, every ART path blanked → runtime placeholders"),
                                 (b, "The real build → generated art")]):
    p = shot.resize((pw, round(shot.height * pw / shot.width)), Image.LANCZOS)
    x = LEFT + i * (pw + gap)
    img.paste(p, (x, 440))
    d.rectangle([x, 440, x + p.width, 440 + p.height], outline=INK, width=4)
    d.text((x, 440 + p.height + 40), cap, font=S(52), fill=INK)
footer(d, f"make_stills.py · two isolated copies of godot/ (game code f88f58d), same spawn frame, {a.width}×{a.height} render")
img.save(MEDIA / "B05.png")

# --- B16: facing grids --------------------------------------------------------
env = dict(os.environ, SHOT_PATH=str(MEDIA / "B16_after_mirror_tilt.png"))
r = run([GODOT, "--path", str(real), "-s", str(ROUTES / "facing_grid_c.gd")], env=env)
print("B16 current grid (mirror + tilt):", "PASS checks" if "FAILS: 0" in r.stdout else r.stdout[-400:])
before = isolated_copy("iso_7fc6a99", rev="7fc6a99")
env = dict(os.environ, SHOT_PATH=str(MEDIA / "B16_before_7fc6a99.png"))
run([GODOT, "--path", str(before), "-s", str(ROUTES / "facing_grid_free.gd")], env=env)
print("B16 before grid (free rotation, commit 7fc6a99) written")
