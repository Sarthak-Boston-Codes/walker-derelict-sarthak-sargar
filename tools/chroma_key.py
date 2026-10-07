"""Remove a flat green-screen background and save a transparent PNG.

Treats each pixel as  C = a*F + (1-a)*K  (K = key color, sampled from the
image border). Alpha comes from how green the pixel is relative to K; the
foreground color F is then recovered by removing K's share, which strips
green spill from edges and from semi-transparent areas (shadow, light beam).

Usage:
    python tools/chroma_key.py IN.jpg OUT.png [--scale 0.12] [--rotate DEG]

Use one shared --scale for every pose of a character so they keep the same
zoom relative to each other (0.12 makes the scavenger's ~330 px body ~40 px,
matching the 48x48 placeholder).
"""
import argparse

import numpy as np
from PIL import Image


def greenness(rgb: np.ndarray) -> np.ndarray:
    return rgb[..., 1] - np.maximum(rgb[..., 0], rgb[..., 2])


def key_out(rgb: np.ndarray, low: float, high: float) -> np.ndarray:
    border = np.concatenate([rgb[:20].reshape(-1, 3), rgb[-20:].reshape(-1, 3),
                             rgb[:, :20].reshape(-1, 3), rgb[:, -20:].reshape(-1, 3)])
    key = np.median(border, axis=0)
    raw_a = np.clip(1.0 - greenness(rgb) / greenness(key), 0.0, 1.0)

    # Recover foreground color from the unclamped-but-nonzero alpha.
    safe_a = np.maximum(raw_a, 1e-3)[..., None]
    fg = np.clip((rgb - (1.0 - safe_a) * key) / safe_a, 0.0, 1.0)

    # Below `low` is background noise (JPEG); above `high` is solid subject.
    alpha = np.clip((raw_a - low) / (high - low), 0.0, 1.0)
    fg[alpha == 0] = 0.0
    return np.dstack([fg, alpha])


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--rotate", type=int, default=0, help="degrees counter-clockwise (character art: leave at 0, stored upright facing east -- see godot/scenes/facing.gd)")
    ap.add_argument("--scale", type=float, default=1.0, help="resize factor applied after rotation")
    ap.add_argument("--low", type=float, default=0.10)
    ap.add_argument("--high", type=float, default=0.97)
    args = ap.parse_args()

    rgb = np.asarray(Image.open(args.src).convert("RGB"), dtype=np.float64) / 255.0
    rgba = key_out(rgb, args.low, args.high)
    out = Image.fromarray(np.round(rgba * 255.0).astype(np.uint8), "RGBA")
    if args.rotate:
        out = out.rotate(args.rotate, expand=True)
    if args.scale != 1.0:
        size = (max(1, round(out.width * args.scale)), max(1, round(out.height * args.scale)))
        # Pillow premultiplies RGBA while resampling, so no dark fringes.
        out = out.resize(size, Image.LANCZOS)
    out.save(args.dst)
    print(f"wrote {args.dst} {out.size} RGBA")


if __name__ == "__main__":
    main()
