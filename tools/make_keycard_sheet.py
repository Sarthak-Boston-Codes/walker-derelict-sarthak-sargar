"""Generate godot/art/keycard_sheet.png: the A7 keycard spin sheet.

Written by Claude Code for DERELICT (Assignment 7). No third-party art or
licence: every pixel is drawn here with Pillow.

Sheet: 8 cells of 64 x 64 px in one row (hframes 8, vframes 1), frame 0-7
left to right. Cell k shows the card turned k * 45 degrees about its
vertical axis. The drawn width is |cos(theta)| of the full width (an
edge-on card, cells 2 and 6, is a 2 px line). The face that is visible is
the one a real turning card shows: the front while cos(theta) > 0 (cells
7, 0, 1), the back while cos(theta) < 0 (cells 3, 4, 5); the back is a
different colour, so cell 4 is visibly not cell 0. A small perspective
lean (the nearer edge taller) makes cell 1 and cell 7 mirror images rather
than copies. There is no 360-degree cell. The card is centred in every
cell by construction (same centre, symmetric extents).

Usage (from the repo root):  python tools/make_keycard_sheet.py
Deterministic: the same script always writes the same pixels.
"""
import math
import os
import sys

from PIL import Image, ImageDraw

CELL = 64
FRAMES = 8
SS = 4  # supersampling factor
CARD_W, CARD_H = 52, 36  # full-width card in cell pixels
LEAN = 0.10  # perspective: the nearer edge is up to 10 % taller
EDGE_W = 2  # px width of an edge-on card

FRONT_BODY = (14, 42, 58, 255)
FRONT_RIM = (43, 217, 255, 255)  # the HUD keycard label colour #2BD9FF
CHIP = (232, 190, 74, 255)
BACK_BODY = (255, 159, 28, 255)
BACK_RIM = (120, 60, 0, 255)
STRIPE = (20, 20, 22, 255)
EDGE = (200, 230, 240, 255)


def face(front: bool) -> Image.Image:
    w, h = CARD_W * SS, CARD_H * SS
    im = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    r = 5 * SS
    if front:
        d.rounded_rectangle([0, 0, w - 1, h - 1], r, fill=FRONT_BODY, outline=FRONT_RIM, width=2 * SS)
        # gold chip, left
        d.rounded_rectangle([7 * SS, 11 * SS, 18 * SS, 23 * SS], 2 * SS, fill=CHIP)
        d.line([7 * SS, 17 * SS, 18 * SS, 17 * SS], fill=FRONT_BODY, width=SS)
        # cyan stripes, right (an ID line and a name line)
        d.rectangle([23 * SS, 10 * SS, 45 * SS, 14 * SS], fill=FRONT_RIM)
        d.rectangle([23 * SS, 19 * SS, 38 * SS, 22 * SS], fill=FRONT_RIM)
        # diamond (the HUD's keycard glyph), bottom right
        cx, cy, s = 42 * SS, 28 * SS, 3 * SS
        d.polygon([(cx, cy - s), (cx + s, cy), (cx, cy + s), (cx - s, cy)], fill=FRONT_RIM)
    else:
        d.rounded_rectangle([0, 0, w - 1, h - 1], r, fill=BACK_BODY, outline=BACK_RIM, width=2 * SS)
        # magnetic stripe across the top third, and a signature box
        d.rectangle([2 * SS, 6 * SS, w - 2 * SS - 1, 13 * SS], fill=STRIPE)
        d.rectangle([6 * SS, 20 * SS, 34 * SS, 27 * SS], fill=(255, 236, 200, 255), outline=BACK_RIM, width=SS)
    return im


def cell(k: int, front_img: Image.Image, back_img: Image.Image) -> Image.Image:
    theta = math.radians(45 * k)
    c, s = math.cos(theta), math.sin(theta)
    big = Image.new("RGBA", (CELL * SS, CELL * SS), (0, 0, 0, 0))
    cx, cy = CELL * SS / 2, CELL * SS / 2
    if abs(c) < 1e-6:
        # edge-on: a thin line, centred
        d = ImageDraw.Draw(big)
        w = EDGE_W * SS
        d.rectangle([cx - w / 2, cy - CARD_H * SS / 2, cx + w / 2 - 1, cy + CARD_H * SS / 2 - 1], fill=EDGE)
        return big.resize((CELL, CELL), Image.BOX)
    src = front_img if c > 0 else back_img
    out_w = max(1, round(CARD_W * SS * abs(c)))
    # Heights at the left and right edges: the edge turning toward the
    # viewer is taller. For 0 < theta < 180 the right edge comes forward.
    h_left = CARD_H * SS * (1.0 - LEAN * s)
    h_right = CARD_H * SS * (1.0 + LEAN * s)
    x0 = round(cx - out_w / 2)
    sw = src.width
    for x in range(out_w):
        u = (x + 0.5) / out_w
        col = src.crop((min(sw - 1, int(u * sw)), 0, min(sw, int(u * sw) + 1), src.height))
        hh = max(1, round(h_left + (h_right - h_left) * u))
        col = col.resize((1, hh), Image.BOX)
        big.alpha_composite(col, (x0 + x, round(cy - hh / 2)))
    return big.resize((CELL, CELL), Image.BOX)


def main() -> int:
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "godot", "art", "keycard_sheet.png")
    front_img, back_img = face(True), face(False)
    sheet = Image.new("RGBA", (CELL * FRAMES, CELL), (0, 0, 0, 0))
    for k in range(FRAMES):
        sheet.alpha_composite(cell(k, front_img, back_img), (k * CELL, 0))
    sheet.save(out, optimize=False)
    print("wrote %s (%d x %d, %d cells of %d x %d)" % (out, sheet.width, sheet.height, FRAMES, CELL, CELL))
    for k in range(FRAMES):
        bbox = sheet.crop((k * CELL, 0, (k + 1) * CELL, CELL)).getbbox()
        print("cell %d  %3d deg  bbox %s" % (k, 45 * k, bbox))
    return 0


if __name__ == "__main__":
    sys.exit(main())
