#!/usr/bin/env bash
# Change screen brightness and show an on-screen progress-bar OSD via dunst.
# Uses replace-id 9002 + its own stack tag so it won't clash with the volume OSD.
step=5

case "$1" in
    up)   brightnessctl -q set "${step}%+" ;;
    down) brightnessctl -q set "${step}%-" ;;
esac

# current brightness as a percentage (field 4 of machine-readable output)
b=$(brightnessctl -m | cut -d, -f4 | tr -d '%')

dunstify -a "Brightness" -t 1500 -r 9002 -u low \
    -i display-brightness-symbolic \
    -h string:x-dunst-stack-tag:brightness \
    -h int:value:"$b" \
    "Brightness   ${b}%"
