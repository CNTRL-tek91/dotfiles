#!/usr/bin/env bash
# Stops any running live wallpaper. awww's own static-wallpaper layer never
# stops running underneath it, so killing linux-wallpaperengine alone is
# enough to reveal the normal wallpaper again - nothing else to restore.

if pkill -f 'linux-wallpaperengine'; then
  notify-send -a "Wallpaper" -u low -t 1500 "Live wallpaper stopped" "Back to your static wallpaper"
else
  notify-send -a "Wallpaper" -u low -t 1500 "No live wallpaper running"
fi
