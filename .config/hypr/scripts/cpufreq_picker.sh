#!/usr/bin/env bash
# Waybar icon entry point: a rofi dropdown to pick the CPU mode directly,
# instead of cycling. Same styling as wallpaper-rofi.sh.

chosen=$(printf '󰢝  Silent\n󰗑  Balanced\n󰓅  Performance\n' | \
  rofi -dmenu -i -p "CPU Mode" -theme "$HOME/.config/rofi/power-picker.rasi")

case "$chosen" in
  *Silent*)      mode=silent ;;
  *Balanced*)    mode=balanced ;;
  *Performance*) mode=performance ;;
  *) exit 0 ;;
esac

exec ~/.config/hypr/scripts/cpufreq_set.sh "$mode"
