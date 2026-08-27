#!/usr/bin/env bash
# Core setter for auto-cpufreq's forced governor mode. Called by
# cpufreq_cycle.sh (keybind) and cpufreq_picker.sh (waybar rofi menu) so both
# stay in sync via the same state file. `sudo auto-cpufreq --force` needs the
# NOPASSWD sudoers rule in /etc/sudoers.d/auto-cpufreq-force to run silently.

STATE_FILE="$HOME/.cache/auto-cpufreq-mode"

case "$1" in
  silent)      arg=powersave;    label="󰢝  Silent" ;;
  balanced)    arg=reset;        label="󰗑  Balanced" ;;
  performance) arg=performance;  label="󰓅  Performance" ;;
  *) echo "usage: cpufreq_set.sh silent|balanced|performance" >&2; exit 1 ;;
esac

sudo /usr/bin/auto-cpufreq --force "$arg" >/dev/null 2>&1
echo "$1" > "$STATE_FILE"
notify-send -a "CPU Mode" -u low -t 1500 -h string:x-canonical-private-synchronous:cpufreq-osd \
  "CPU Mode" "$label"
