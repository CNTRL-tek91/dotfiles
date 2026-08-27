#!/usr/bin/env bash
# Fan / power-profile OSD watcher.
# Watches the ACPI platform_profile (which Fn+F6 changes via asusd) and pops a
# notification whenever the mode changes — the Linux equivalent of the Windows
# Armoury Crate on-screen fan-mode indicator. Autostarted from autostart.conf.

PROFILE_FILE="/sys/firmware/acpi/platform_profile"
[ -r "$PROFILE_FILE" ] || exit 0

# Map profile -> friendly label + Nerd Font icon.
label_for() {
  case "$1" in
    quiet)       echo "󰢝  Silent" ;;
    balanced)    echo "󰗑  Balanced" ;;
    performance) echo "󰓅  Performance" ;;
    low-power)   echo "󰌪  Silent" ;;
    *)           echo "  ${1^}" ;;
  esac
}

last="$(<"$PROFILE_FILE")"

while true; do
  current="$(<"$PROFILE_FILE")"
  if [ "$current" != "$last" ]; then
    notify-send -a "Fan Profile" -u low -t 1500 -h string:x-canonical-private-synchronous:profile-osd \
      "Fan Mode" "$(label_for "$current")"
    last="$current"
  fi
  sleep 1
done
