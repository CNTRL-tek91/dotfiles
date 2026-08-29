#!/usr/bin/env python3
"""Give pywal's palette real hue variety, harmonised to the wallpaper.

THE PROBLEM
pywal builds the 16-colour palette out of the colours it finds in the image. On
any wallpaper with a strong colour cast - a mostly-red scene, say - every one of
the six accent slots comes back a shade of that same colour. Measured on this
desktop's wallpaper, colours 1-6 spanned 6 degrees of hue: functionally one
colour. Terminals and editors then have nothing to distinguish a string from a
keyword from an error, and everything reads as flat monochrome.

Designed themes (catppuccin, darcula, gruvbox) don't work that way. They keep
the six ANSI slots at genuinely distinct hues - red, green, yellow, blue,
magenta, cyan - and unify them by giving every slot a shared saturation and
lightness character, plus a slight rotation toward one house hue.

WHAT THIS DOES
Rebuilds slots 1-6 (and their bright counterparts 9-14) at properly separated
hues, then pulls them toward the wallpaper's dominant hue so the result still
reads as "that wallpaper's theme" rather than a generic rainbow. Where the
wallpaper genuinely contains a hue near a slot's target, that real hue is used
in preference to the synthetic one, so authentic wallpaper colours survive.

Background, foreground and the greys (0, 7, 8, 15) are passed through from
pywal untouched - they already carry the wallpaper's mood and changing them
would alter the desktop's overall look, not just its accents.

Usage:
    harmonize_palette.py IMAGE [--pull F] [--in JSON] [--out JSON] [--preview]

    --pull F   0.0 = fully separated hues (rainbow), 1.0 = pywal's current
               monochrome behaviour. Default 0.30.
    --preview  print the palette and its hue spread instead of writing.
"""
import argparse
import colorsys
import json
import os
import re
import subprocess
import sys

# Canonical ANSI hues, in degrees. These are the slots a terminal palette and
# every syntax highlighter assume exist.
ANSI_HUES = {1: 0.0, 2: 120.0, 3: 45.0, 4: 215.0, 5: 300.0, 6: 180.0}

# A wallpaper hue is only allowed to claim a slot if it lands this close to the
# slot's target. Wider and slots start stealing each other's colours; narrower
# and genuine wallpaper colours get ignored in favour of synthetic ones.
SNAP_TOLERANCE = 30.0

# Colours below this saturation carry no usable hue information - greys and
# near-blacks would otherwise dominate the "what hue is this wallpaper" vote.
MIN_USEFUL_SAT = 0.15

# Ceiling on how far the wheel is rotated toward the wallpaper. Past roughly
# this much the slots stop matching their names - a "red" error message tinted
# 40 degrees toward an amber wallpaper is still red, but at 90 it is orange.
MAX_ROTATION = 25.0

# The readable band the wallpaper's saturation/value are mapped into. The floors
# keep text legible on a dark background; the ceilings stop a vivid wallpaper
# producing neon that vibrates against it.
SAT_FLOOR, SAT_CEIL = 0.38, 0.88
VAL_FLOOR, VAL_CEIL = 0.58, 0.92


def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def rgb2hex(rgb):
    return "#" + "".join(f"{round(max(0, min(1, c)) * 255):02x}" for c in rgb)


def hsv(h):
    return colorsys.rgb_to_hsv(*hex2rgb(h))


def circ_mean(degrees, weights):
    """Average of hues on the colour wheel. A plain mean is wrong here: red at
    350 and red at 10 average to cyan at 180 rather than to red at 0."""
    import math
    x = sum(w * math.cos(math.radians(d)) for d, w in zip(degrees, weights, strict=True))
    y = sum(w * math.sin(math.radians(d)) for d, w in zip(degrees, weights, strict=True))
    if x == 0 and y == 0:
        return 0.0
    return math.degrees(math.atan2(y, x)) % 360


def circ_dist(a, b):
    d = abs(a - b) % 360
    return min(d, 360 - d)


def image_colors(path, n=32):
    """Dominant colours of the image with their pixel counts, via ImageMagick."""
    try:
        out = subprocess.run(
            ["magick", path, "-resize", "400x400>", "-colors", str(n),
             "-format", "%c", "histogram:info:-"],
            capture_output=True, text=True, timeout=60, check=True).stdout
    except (subprocess.SubprocessError, FileNotFoundError):
        return []
    found = []
    for line in out.splitlines():
        m = re.search(r"(\d+):.*?#([0-9A-Fa-f]{6})", line)
        if m:
            found.append((int(m.group(1)), "#" + m.group(2).lower()))
    return found


def analyse(colors):
    """Anchor hue and the saturation/value character of the wallpaper."""
    useful = []
    for count, hx in colors:
        h, s, v = hsv(hx)
        if s >= MIN_USEFUL_SAT and 0.08 < v < 0.97:
            useful.append((count, h * 360, s, v))
    if not useful:
        return 0.0, 0.55, 0.62, []
    anchor = circ_mean([u[1] for u in useful], [u[0] for u in useful])
    # Population-weighted median-ish: use the most populous colours' character
    # rather than a flat mean, so a few stray pixels don't set the tone.
    useful.sort(key=lambda u: -u[0])
    top = useful[:max(3, len(useful) // 2)]
    sat = sum(u[2] for u in top) / len(top)
    val = sum(u[3] for u in top) / len(top)
    return anchor, sat, val, useful


def build(image, src, pull):
    data = json.load(open(src))
    cols = dict(data["colors"])

    img = image_colors(image)
    anchor, img_sat, img_val, useful = analyse(img)

    # Map the wallpaper's character into a readable band PROPORTIONALLY rather
    # than clamping into it. Clamping looks equivalent and is not: most photos
    # sit below a 0.45 saturation floor, so every muted wallpaper produced the
    # identical palette and the theme stopped being wallpaper-driven at all -
    # the exact opposite of the problem this script exists to solve. Scaling
    # keeps washed-out wallpapers muted and vivid ones vivid, while guaranteeing
    # the band stays legible on a dark background.
    sat = SAT_FLOOR + (SAT_CEIL - SAT_FLOOR) * min(1.0, img_sat)
    val = VAL_FLOOR + (VAL_CEIL - VAL_FLOOR) * min(1.0, img_val)

    # Tint by rotating the WHOLE wheel toward the anchor, not by pulling each
    # hue toward it individually. Pulling individually compresses the wheel:
    # with a warm anchor, blue and cyan both slide counter-clockwise into green
    # and the slots stop meaning what syntax highlighters expect them to mean.
    # A rigid rotation keeps the 60-degree spacing between slots intact, and the
    # shared saturation/value below is what actually makes the palette cohere -
    # which is how designed themes do it too.
    nearest = min(ANSI_HUES.values(), key=lambda c: circ_dist(c, anchor))
    delta = ((anchor - nearest + 180) % 360 - 180) * pull
    delta = max(-MAX_ROTATION, min(MAX_ROTATION, delta))

    used = []
    for slot, canonical in ANSI_HUES.items():
        target = (canonical + delta) % 360

        # Prefer a hue the wallpaper actually contains, if one is close enough
        # and isn't already claimed by another slot.
        best, best_d = None, SNAP_TOLERANCE
        for _count, hue, _s, _v in useful:
            d = circ_dist(hue, target)
            if d < best_d and all(circ_dist(hue, u) > 18 for u in used):
                best, best_d = hue, d
        hue = best if best is not None else target
        used.append(hue)

        cols[f"color{slot}"] = rgb2hex(colorsys.hsv_to_rgb(hue / 360.0, sat, val))
        # Bright variants: lighter and a little less saturated, which is the
        # relationship pywal and most designed palettes use.
        cols[f"color{slot + 8}"] = rgb2hex(
            colorsys.hsv_to_rgb(hue / 360.0, max(0.0, sat - 0.12), min(1.0, val + 0.14)))

    data["colors"] = cols
    return data, anchor, sat, val


def spread(cols):
    hues = [hsv(cols[f"color{i}"])[0] * 360 for i in range(1, 7)]
    return max(circ_dist(a, b) for a in hues for b in hues)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--pull", type=float, default=0.30)
    ap.add_argument("--in", dest="src",
                    default=os.path.expanduser("~/.cache/wal/colors.json"))
    ap.add_argument("--out", dest="out")
    ap.add_argument("--preview", action="store_true")
    a = ap.parse_args()

    if not os.path.exists(a.src):
        sys.exit(f"no pywal colors at {a.src}")

    before = json.load(open(a.src))["colors"]
    data, anchor, sat, val = build(a.image, a.src, a.pull)

    if a.preview:
        print(f"anchor hue {anchor:6.1f}deg   sat {sat:.2f}   val {val:.2f}   pull {a.pull}")
        print(f"  before  spread {spread(before):5.1f}deg   "
              + " ".join(before[f"color{i}"] for i in range(1, 7)))
        print(f"  after   spread {spread(data['colors']):5.1f}deg   "
              + " ".join(data["colors"][f"color{i}"] for i in range(1, 7)))
        return

    out = a.out or a.src
    with open(out, "w") as f:
        json.dump(data, f, indent=4)


if __name__ == "__main__":
    main()
