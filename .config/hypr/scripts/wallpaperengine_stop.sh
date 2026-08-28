#!/usr/bin/env bash
# Stops any running live wallpaper. awww's own static-wallpaper layer never
# stops running underneath it, so killing linux-wallpaperengine alone is
# enough to reveal the normal wallpaper again - but the desktop THEME (waybar,
# kitty, hyprland borders) would still be showing colors extracted from the
# live wallpaper's last frame. Re-run the normal static-wallpaper pipeline on
# the current wallpaper to put the theme back in sync too.

if pkill -f 'linux-wallpaperengine'; then
  wall="$(readlink -f "$HOME/Pictures/wallpaper.png" 2>/dev/null)"
  if [ -n "$wall" ] && [ -f "$wall" ]; then
    ~/.config/hypr/scripts/wallpaper.sh "$wall" >/dev/null 2>&1
  fi
  notify-send -a "Wallpaper" -u low -t 1500 "Live wallpaper stopped" "Back to your static wallpaper"
else
  notify-send -a "Wallpaper" -u low -t 1500 "No live wallpaper running"
fi
