#!/bin/bash
# Usage: apply_wal_theme.sh [/path/to/image]
# Defaults to the actual wallpaper. Callers pass an override when the thing
# to theme from isn't a static wallpaper on disk - e.g. wallpaperengine-rofi.sh
# passes a screenshot of a live wallpaper, since there's no single static
# image a live scene to read otherwise.

WALL_IMG="${1:-$HOME/Pictures/wallpaper.png}"

THEME_FILE="/tmp/theme_variant"
wal_arguments=""

if [ -s "$THEME_FILE" ]; then
  case $(<"$THEME_FILE") in
    "light") wal_arguments="lighten -l" ;;
  esac
fi

wal -i "$WALL_IMG" --cols16 $wal_arguments -q -n -e

# pywal picks the palette out of the image, so a wallpaper with any colour cast
# collapses all six accent slots onto one hue - a red wallpaper themes the whole
# desktop in six shades of red, with nothing left to distinguish a string from a
# keyword from an error. harmonize_palette.py rewrites those slots to properly
# separated hues while keeping the wallpaper's saturation/brightness character,
# then wal --theme regenerates all ~60 template files from the result, so every
# consumer (kitty, waybar, hyprland, nvim, ...) picks it up with no changes of
# its own. Both steps are best-effort: if either fails the original pywal
# palette is already on disk and the desktop still themes, just monochromatically.
if python3 ~/.config/hypr/scripts/harmonize_palette.py "$WALL_IMG" 2>/dev/null; then
  wal --theme "$HOME/.cache/wal/colors.json" -q -n -e 2>/dev/null
fi

# Build a readability-floored, wallpaper-themed kitty palette, then live-reload
# any running kitty instances (new windows pick it up automatically).
python3 ~/.config/hypr/scripts/kitty_readable_colors.py 2>/dev/null
# Tell every running kitty to reload its config (picks up the new palette live).
killall -SIGUSR1 kitty 2>/dev/null

# Reload waybar colors via a STYLE-ONLY reload (reload_style_on_change), which does
# NOT recreate the layer-shell surface, so XWayland windows (LibreWolf) survive.
# A real content change is required (a bare `touch` only updates mtime, which waybar
# may ignore); we keep a single self-replacing marker line at the end of style.css.
sed -i --follow-symlinks '/^\/\* wal-reload /d' ~/.config/waybar/style.css
printf '/* wal-reload %s */\n' "$(date +%s%N)" >> ~/.config/waybar/style.css

# Sync the SDDM (boot login screen) background to the current wallpaper.
# The simple_sddm_2 theme reads Backgrounds/default; that file is user-owned, so
# we can overwrite it without sudo. Re-encode to PNG (the theme's expected format)
# and fall back to a raw copy if ImageMagick isn't available. Guarded by -w so it
# silently skips (never prompts for a password) if the file isn't writable.
SDDM_BG="/usr/share/sddm/themes/simple_sddm_2/Backgrounds/default"
WALL_SRC="$(readlink -f ~/Pictures/wallpaper.png)"
if [ -n "$WALL_SRC" ] && [ -f "$WALL_SRC" ] && [ -w "$SDDM_BG" ]; then
  magick "$WALL_SRC" "PNG:$SDDM_BG" 2>/dev/null || cp -f "$WALL_SRC" "$SDDM_BG"
fi

# Push the new pywal colors into LibreWolf/Firefox via the pywalfox extension.
command -v pywalfox >/dev/null && pywalfox update >/dev/null 2>&1
# Optional integrations (only run if installed).
command -v walogram  >/dev/null && walogram -s >/dev/null 2>&1
command -v spicetify >/dev/null && spicetify apply -q -n >/dev/null 2>&1
