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

# pywal crowds all six accent slots into one narrow band, so the six colours are
# barely distinguishable from each other - on the current red wallpaper it even
# returns six greys. extract_accents.py hands extraction to wallust instead,
# which picks perceptually separated colours out of the SAME image (measured
# better on all 12 wallpapers here), then wal --theme regenerates all ~60
# template files from the result so every consumer - kitty, waybar, hyprland,
# nvim - picks it up with no change of its own.
#
# Best-effort: if either step fails, pywal's own palette is already on disk, so
# the desktop still themes, just with duller accents.
accent_args=("$WALL_IMG")
[ -n "$wal_arguments" ] && accent_args+=(--light)
if python3 ~/.config/hypr/scripts/extract_accents.py "${accent_args[@]}" 2>/dev/null; then
  wal --theme "$HOME/.cache/wal/colors.json" -q -n -e 2>/dev/null
fi

# Build a readability-floored, wallpaper-themed kitty palette, then live-reload
# any running kitty instances (new windows pick it up automatically).
python3 ~/.config/hypr/scripts/kitty_readable_colors.py 2>/dev/null
# Tell every running kitty to reload its config (picks up the new palette live).
killall -SIGUSR1 kitty 2>/dev/null

# Tell every running Neovim to re-read the palette. lushwal ships an fs_event
# watcher on ~/.cache/wal/colors.json, but it is not something to rely on: this
# pipeline rewrites that file twice per change, a single-file watch does not
# survive the file being replaced, and the watcher only re-arms from the exit
# callback of a subprocess it spawns - so one missed event leaves an open editor
# stuck on the old colours for the rest of its session. Pushing the reload is
# deterministic and costs nothing when no editor is open.
~/.config/hypr/scripts/reload_nvim_theme.sh 2>/dev/null

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
