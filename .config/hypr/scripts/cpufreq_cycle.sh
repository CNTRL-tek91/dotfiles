#!/usr/bin/env bash
# Keybind entry point (Ctrl+Super+P / Super+F6): cycles Silent -> Balanced ->
# Performance -> Silent, same 3-way pattern as the old powerprofilesctl bind.

STATE_FILE="$HOME/.cache/auto-cpufreq-mode"
current=$(cat "$STATE_FILE" 2>/dev/null)

case "$current" in
  silent)      next=balanced ;;
  balanced)    next=performance ;;
  *)           next=silent ;;
esac

exec ~/.config/hypr/scripts/cpufreq_set.sh "$next"
