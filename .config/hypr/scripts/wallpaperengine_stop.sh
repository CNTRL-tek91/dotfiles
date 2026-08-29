#!/usr/bin/env bash
# Stops any running live wallpaper. awww's own static-wallpaper layer never
# stops running underneath it, so killing linux-wallpaperengine alone is
# enough to reveal the normal wallpaper again - but the desktop THEME (waybar,
# kitty, hyprland borders, LibreWolf) would still be showing colors extracted
# from the live wallpaper's last frame. Re-run apply_wal_theme.sh with no
# override so it themes from the real wallpaper again, same as it does
# normally.

if pkill -f 'linux-wallpaperengine'; then
  # Clear the "a live wallpaper was on" state, so wallpaperengine_autostart.sh
  # leaves the static wallpaper alone on the next login/boot instead of
  # bringing this one back.
  rm -f "$HOME/.cache/wallpaperengine_state"
  ~/.config/hypr/scripts/apply_wal_theme.sh >/dev/null 2>&1
  notify-send -a "Wallpaper" -u low -t 1500 "Live wallpaper stopped" "Back to your static wallpaper"
else
  notify-send -a "Wallpaper" -u low -t 1500 "No live wallpaper running"
fi
