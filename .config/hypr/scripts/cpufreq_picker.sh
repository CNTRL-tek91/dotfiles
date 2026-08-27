#!/usr/bin/env bash
# Waybar icon entry point: a rofi dropdown to pick the CPU mode directly,
# instead of cycling. Same styling as wallpaper-rofi.sh.

current=$(cat "$HOME/.cache/auto-cpufreq-mode" 2>/dev/null)
case "$current" in
  silent)      row=0 ;;
  performance) row=2 ;;
  *)           row=1 ;;  # balanced, or unset/first run
esac

chosen=$(printf '󰢝  Silent\n󰗑  Balanced\n󰓅  Performance\n' | \
  rofi -dmenu -i -p "CPU Mode" -selected-row "$row" -theme "$HOME/.config/rofi/power-picker.rasi")

case "$chosen" in
  *Silent*)      mode=silent ;;
  *Balanced*)    mode=balanced ;;
  *Performance*) mode=performance ;;
  *) exit 0 ;;
esac

exec ~/.config/hypr/scripts/cpufreq_set.sh "$mode"
