"""Shared 3840x2160 card style for the film's own stills (B05, B16, B17, B18, B19, B23):
the film's cream page, EB Garamond title, @NikBearBrown footer.

All ink stays inside brutalist.art's title-safe area (final_frame_check.py: a 5%
inset, x 192-3648, y 108-2052 at 4K), with a little extra margin."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

W, H = 3840, 2160
MARGIN = 220                 # left/right; safe edge is 192
LEFT, RIGHT = MARGIN, W - MARGIN
CONTENT_W = RIGHT - LEFT     # 3400
TOP = 150                    # title top; safe edge is 108
FOOTER_Y = 1960              # footer text top; must end above 2052
INK, PAGE, ACCENT, MUTED = (61, 57, 41), (250, 249, 245), (217, 119, 87), (120, 114, 96)
FONTS = Path(r"C:\Users\sarth\brutalist.art\runtime\fonts")
_serif = next(FONTS.rglob("EBGaramond-Regular.ttf"))
F = lambda size: ImageFont.truetype(str(_serif), size)
M = lambda size: ImageFont.truetype("C:/Windows/Fonts/consola.ttf", size)
S = lambda size: ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", size)


def card(title):
    img = Image.new("RGB", (W, H), PAGE)
    d = ImageDraw.Draw(img)
    d.text((LEFT, TOP), title, font=F(140), fill=INK)
    return img, d


def footer(d, text):
    d.text((LEFT, FOOTER_Y), text, font=S(40), fill=MUTED)
    d.text((RIGHT - d.textlength("@NikBearBrown", font=F(56)), FOOTER_Y - 14), "@NikBearBrown", font=F(56), fill=INK)
