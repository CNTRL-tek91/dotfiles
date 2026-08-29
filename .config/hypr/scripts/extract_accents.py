#!/usr/bin/env python3
"""Replace pywal's accent colours with genuinely distinct ones from the wallpaper.

THE PROBLEM
pywal's extraction crowds all six accent slots into one narrow band. Measured
across this machine's 12 wallpapers, the mean perceptual distance between
colours 1-6 was 8-32 (Lab units) and the *closest pair* was as low as 1.3 -
two slots that are literally the same colour to the eye. So a red wallpaper
themes the desktop in six reds you cannot tell apart, and nothing distinguishes
a string from a keyword from an error.

WHY NOT SYNTHESISE HUES
An earlier attempt rebuilt the slots at canonical ANSI hues - red, green,
yellow, blue, magenta, cyan - and tinted them toward the wallpaper. It scored
brilliantly on hue spread and was completely wrong: a wallpaper that contains
only reds got green and magenta in its theme, colours that appear nowhere in
the image. Hue spread was the wrong metric. Wallpapers legitimately have one
hue; what they also have is a wide range of LIGHTNESS and SATURATION - the
bright red, the deep maroon, the pale pink, the near-black - and that is the
variety worth extracting.

WHAT THIS DOES
Hands extraction to wallust, which is built for this and is already installed.
Its Lab colourspace picks perceptually separated colours instead of a narrow
band, and --check-contrast keeps them legible against the background. Measured
on the same 12 wallpapers, wallust beat pywal on every single one: mean
distance roughly 2-3x better, closest-pair distance 3-5x better.

Only slots 1-6 and 9-14 are replaced. Background, foreground and the greys stay
pywal's, because they set the desktop's overall mood and already look right -
this is meant to fix the accents, not restyle everything.

Two engines are available so they can be compared, selected with --engine or
by putting a word in ~/.config/hypr/theme_engine:

  wallust  (default)  Colours sampled from the image in Lab space. What is on
                      screen is what you get.
  matugen             Material You. Derives a principled tonal system from the
                      image's dominant colour, mapping Material roles onto the
                      ANSI slots the way AccursedGalaxy/omarchy-auto-theme does
                      (red=error, green=tertiary, yellow=primary_fixed,
                      blue=primary, magenta=secondary, cyan=tertiary_fixed).
                      That project itself only runs on Omarchy, which is not
                      installed here; this is a port of its colour mapping.

Usage:
    extract_accents.py IMAGE [--light] [--preview] [--engine wallust|matugen]
"""
import argparse
import colorsys
import json
import math
import os
import subprocess
import sys
import tempfile

CACHE = os.path.expanduser("~/.cache/wal")
COLORS_JSON = os.path.join(CACHE, "colors.json")

# Chosen by measurement, not preference - see the module docstring. `lab` gave
# the widest perceptual separation of the colourspaces tried; `harddark16`
# orders brightest-first, which suits ANSI slots where colour1 wants to be
# visible; `--check-contrast` keeps everything legible on the background.
BACKEND, COLORSPACE = "full", "lab"
PALETTE_DARK, PALETTE_LIGHT = "harddark16", "light16"

# Minimum WCAG contrast ratio an accent must reach against the background.
# wallust's own check leaves some colours near 2.0, which is readable for a UI
# accent but marginal for text. Lifting to 3.0 costs little separation.
#
# Tried 4.0 and it read as washed out - reverted. The measurement behind that
# attempt is still worth keeping: raising this is not free on muted wallpapers,
# where lifting lightness converges the colours toward the same pale grey. Going
# 3.0 -> 4.5 costs saturated wallpapers nothing (29.0 -> 29.1 mean Lab
# separation) but takes about a third off muted ones (341402 14.4 -> 9.8, xeno2
# 24.1 -> 17.1). Use --min-contrast to try a value before changing this, and
# read --preview's separation figure alongside the contrast one.
MIN_CONTRAST = 3.0

# Material You role -> ANSI slot, lifted from omarchy-auto-theme's
# omarchy-quattro-colors.toml so the comparison is against what that project
# actually does rather than a mapping of my own invention. The bright variants
# are its set_lightness values.
MATUGEN_SLOTS = {
    1: ("error", 84.0),
    2: ("tertiary", 84.0),
    3: ("primary_fixed", 90.0),
    4: ("primary", 84.0),
    5: ("secondary", 84.0),
    6: ("tertiary_fixed", 90.0),
}


def _lin(c):
    c /= 255.0
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _rgb(hx):
    hx = hx.strip().lstrip("#")
    return [int(hx[i:i + 2], 16) for i in (0, 2, 4)]


def luminance(hx):
    r, g, b = (_lin(v) for v in _rgb(hx))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def lab(hx):
    r, g, b = (_lin(v) for v in _rgb(hx))
    x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
    y = 0.2126 * r + 0.7152 * g + 0.0722 * b
    z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883

    def f(t):
        return t ** (1 / 3) if t > 0.008856 else (7.787 * t + 16 / 116)

    fx, fy, fz = f(x), f(y), f(z)
    return (116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz))


def lift_contrast(hx, bg, target=MIN_CONTRAST):
    """Raise a colour's lightness until it reads against bg, keeping its hue.

    Hue and saturation are what make the colour belong to the wallpaper, so
    only lightness moves, and only as far as it has to.
    """
    if contrast(hx, bg) >= target:
        return hx
    r, g, b = (v / 255 for v in _rgb(hx))
    h, light, s = colorsys.rgb_to_hls(r, g, b)
    darker_bg = luminance(bg) < 0.5
    for _ in range(60):
        light = min(1.0, light + 0.02) if darker_bg else max(0.0, light - 0.02)
        cand = "#" + "".join(
            f"{round(max(0, min(1, c)) * 255):02x}"
            for c in colorsys.hls_to_rgb(h, light, s))
        if contrast(cand, bg) >= target or light in (0.0, 1.0):
            return cand
    return hx


def wallust_palette(image, light):
    """Ask wallust for a 16-colour palette. Returns {index: hex} or None."""
    palette = PALETTE_LIGHT if light else PALETTE_DARK
    with tempfile.TemporaryDirectory() as td:
        tpl_dir = os.path.join(td, "tpl")
        os.mkdir(tpl_dir)
        out = os.path.join(td, "out.txt")
        with open(os.path.join(tpl_dir, "plain"), "w") as f:
            f.write("\n".join("{{color%d}}" % i for i in range(16)))
        with open(os.path.join(td, "w.toml"), "w") as f:
            f.write(f"[templates]\nplain.template = 'plain'\nplain.target = '{out}'\n")
        try:
            subprocess.run(
                ["wallust", "run", image, "-b", BACKEND, "-c", COLORSPACE,
                 "-p", palette, "-k", "-q", "-s", "--no-hooks",
                 "--config-file", os.path.join(td, "w.toml"),
                 "--templates-dir", tpl_dir],
                capture_output=True, timeout=120, check=True)
        except (subprocess.SubprocessError, FileNotFoundError):
            return None
        if not os.path.exists(out):
            return None
        with open(out) as f:
            vals = [ln.strip() for ln in f if ln.strip().startswith("#")]
    return dict(enumerate(vals)) if len(vals) >= 16 else None


def set_lightness(hx, pct):
    """matugen's set_lightness filter: force HSL lightness to a percentage."""
    r, g, b = (v / 255 for v in _rgb(hx))
    h, _, sat = colorsys.rgb_to_hls(r, g, b)
    return "#" + "".join(
        f"{round(max(0, min(1, c)) * 255):02x}"
        for c in colorsys.hls_to_rgb(h, pct / 100.0, sat))


def matugen_palette(image, light):
    """Material You palette via matugen. Returns {index: hex} or None.

    --dry-run matters: without it matugen would render the templates in
    ~/.config/matugen/config.toml and retheme waybar/hypr/tofi/dunst as a side
    effect of merely asking it for colours.
    """
    mode = "light" if light else "dark"
    try:
        out = subprocess.run(
            ["matugen", "image", image, "--dry-run", "--json", "hex",
             "--prefer", "saturation", "--mode", mode, "-q"],
            capture_output=True, text=True, timeout=120, check=True).stdout
    except (subprocess.SubprocessError, FileNotFoundError):
        return None
    # Shape is colors -> role -> mode -> {"color": "#rrggbb"}, i.e. keyed by
    # role first and mode second, not the other way round.
    try:
        roles = json.loads(out)["colors"]
    except (ValueError, KeyError):
        return None

    def role(name):
        v = roles.get(name)
        if isinstance(v, dict):
            v = v.get(mode, v.get("default"))
            if isinstance(v, dict):
                v = v.get("color")
        return v if isinstance(v, str) and v.startswith("#") else None

    pal = {}
    for slot, (name, bright_l) in MATUGEN_SLOTS.items():
        base = role(name)
        if base is None:
            return None
        pal[slot] = base
        pal[slot + 8] = set_lightness(base, bright_l)
    return pal


def score(cols, bg):
    pts = [lab(c) for c in cols]
    ds = [math.dist(pts[i], pts[j])
          for i in range(len(pts)) for j in range(i + 1, len(pts))]
    cs = [contrast(c, bg) for c in cols]
    return sum(ds) / len(ds), min(ds), min(cs)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("image")
    ap.add_argument("--light", action="store_true")
    ap.add_argument("--preview", action="store_true")
    ap.add_argument("--engine", choices=("wallust", "matugen"), default=None)
    ap.add_argument("--min-contrast", type=float, default=MIN_CONTRAST,
                    help="minimum WCAG contrast ratio against the background")
    a = ap.parse_args()

    # --engine wins; otherwise a one-word file, so switching engines (and
    # switching back) is a single edit with nothing to reinstall.
    engine = a.engine
    if engine is None:
        try:
            engine = open(os.path.expanduser(
                "~/.config/hypr/theme_engine")).read().strip()
        except OSError:
            engine = "wallust"
        if engine not in ("wallust", "matugen"):
            engine = "wallust"

    if not os.path.exists(COLORS_JSON):
        sys.exit("no pywal palette to build on")
    data = json.load(open(COLORS_JSON))
    bg = data["special"]["background"]
    before = [data["colors"][f"color{i}"] for i in range(1, 7)]

    pal = (matugen_palette if engine == "matugen" else wallust_palette)(
        a.image, a.light)
    if pal is None:
        sys.exit(f"{engine} produced no palette")

    for i in list(range(1, 7)) + list(range(9, 15)):
        data["colors"][f"color{i}"] = lift_contrast(pal[i], bg, a.min_contrast)
    after = [data["colors"][f"color{i}"] for i in range(1, 7)]

    if a.preview:
        bm, bmin, bc = score(before, bg)
        am, amin, ac = score(after, bg)
        print(f"engine {engine}   background {bg}")
        print(f"  before  dist {bm:5.1f}/{bmin:5.1f}  contrast {bc:4.2f}  "
              + " ".join(before))
        print(f"  after   dist {am:5.1f}/{amin:5.1f}  contrast {ac:4.2f}  "
              + " ".join(after))
        return

    with open(COLORS_JSON, "w") as f:
        json.dump(data, f, indent=4)


if __name__ == "__main__":
    main()
