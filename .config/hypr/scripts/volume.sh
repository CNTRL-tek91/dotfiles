#!/usr/bin/env bash
# Change volume (or toggle mute) and show an on-screen progress-bar OSD via dunst.
# The notification replaces itself in place (fixed id + stack tag) so it doesn't pile up.
step=2

case "$1" in
    up)   pamixer -i "$step" ;;
    down) pamixer -d "$step" ;;
    mute) pamixer -t ;;
esac

vol=$(pamixer --get-volume)
muted=$(pamixer --get-mute)

if [ "$muted" = "true" ]; then
    dunstify -a "Volume" -t 1500 -r 9001 -u low \
        -i audio-volume-muted-symbolic \
        -h string:x-dunst-stack-tag:volume \
        -h int:value:0 \
        "Muted"
else
    if   [ "$vol" -lt 34 ]; then icon=audio-volume-low-symbolic
    elif [ "$vol" -lt 67 ]; then icon=audio-volume-medium-symbolic
    else                         icon=audio-volume-high-symbolic
    fi
    dunstify -a "Volume" -t 1500 -r 9001 -u low \
        -i "$icon" \
        -h string:x-dunst-stack-tag:volume \
        -h int:value:"$vol" \
        "Volume   ${vol}%"
fi
