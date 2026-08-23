#!/usr/bin/env python3
"""Generate a readable, wallpaper-themed kitty palette from pywal's colors.

pywal derives the terminal palette from the wallpaper, but the colors often come
out too dark/low-contrast to read (especially the shell's syntax-highlighting and
autosuggestions, which use the ANSI palette slots). This keeps each color's HUE
and SATURATION from the wallpaper, so the terminal still matches the theme, but
enforces a minimum LIGHTNESS so text never becomes unreadable on the dark
background.

Input:  ~/.cache/wal/colors.json
Output: ~/.cache/wal/colors-kitty-readable.conf   (included by kitty.conf)
"""
import colorsys
import json
import os

CACHE = os.path.expanduser("~/.cache/wal")
SRC = os.path.join(CACHE, "colors.json")
OUT = os.path.join(CACHE, "colors-kitty-readable.conf")


def hex2rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def rgb2hex(rgb):
    return "#" + "".join(f"{round(max(0, min(1, c)) * 255):02x}" for c in rgb)


def clamp_light(h, min_l, max_l=1.0):
    """Return color h with its HSL lightness clamped into [min_l, max_l]."""
    r, g, b = hex2rgb(h)
    hue, light, sat = colorsys.rgb_to_hls(r, g, b)
    light = max(min_l, min(max_l, light))
    return rgb2hex(colorsys.hls_to_rgb(hue, light, sat))


def main():
    with open(SRC) as f:
        data = json.load(f)

    bg = data["special"]["background"]          # keep the dark background as-is
    fg = clamp_light(data["special"]["foreground"], 0.72)
    c = data["colors"]

    out = {}
    out[0] = clamp_light(c["color0"], 0.16, 0.30)   # "black" — kept dark
    for i in range(1, 7):                            # normal colors
        out[i] = clamp_light(c[f"color{i}"], 0.55)
    out[7] = clamp_light(c["color7"], 0.70)          # "white"
    out[8] = clamp_light(c["color8"], 0.45)          # autosuggestion gray — dim but visible
    for i in range(9, 15):                           # bright colors
        out[i] = clamp_light(c[f"color{i}"], 0.62)
    out[15] = clamp_light(c["color15"], 0.80)        # "bright white"

    lines = [f"foreground {fg}", f"background {bg}", f"cursor {fg}"]
    lines += [f"color{i} {out[i]}" for i in range(16)]
    with open(OUT, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
