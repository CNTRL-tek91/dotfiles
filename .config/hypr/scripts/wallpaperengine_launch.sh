#!/usr/bin/env bash
# Shared launcher: starts a Wallpaper Engine Workshop item as the live
# desktop background and records the choice so it can be restored later.
# Usage: wallpaperengine_launch.sh <workshop-id>
#
# Used by both wallpaperengine-rofi.sh (picking one interactively) and
# wallpaperengine_autostart.sh (restoring one at login) - kept in one place
# so the launch flags, mute retry, and retheme retry can't drift apart
# between the two callers.
id="$1"
[ -n "$id" ] || exit 1

pkill -f 'linux-wallpaperengine' 2>/dev/null
SHOT="$HOME/.cache/wallpaperengine-shot.png"
rm -f "$SHOT"
# --layer background: without it, linux-wallpaperengine defaults to the
# "bottom" layer - the same level waybar renders on - and since it's a
# full-screen surface added after waybar, it covers the bar entirely.
# --silent alone isn't fully trusted here: it suppresses sound generation,
# but PipeWire still shows an unmuted, 100%-volume stream for the process.
# Muted explicitly below as a guaranteed backstop.
# --screenshot: captures an actual rendered frame, used below to re-theme
# the desktop the same way a static wallpaper would - built for exactly
# this by linux-wallpaperengine itself ("for use with tools like PyWAL").
nohup linux-wallpaperengine --layer background --silent --screen-root eDP-1 --bg "$id" \
  --screenshot "$SHOT" \
  > "$HOME/.cache/wallpaperengine.log" 2>&1 &
disown

# Remember the choice so wallpaperengine_autostart.sh can bring it back on
# the next login/boot - a live wallpaper is just a process, it doesn't
# survive a power cycle on its own the way the static awww layer does.
echo "$id" > "$HOME/.cache/wallpaperengine_state"

# Mute its PipeWire stream directly once it appears (retry - it doesn't
# exist the instant the process starts).
for _ in 1 2 3 4 5 6 7 8 9 10; do
  idx=$(pactl -f json list sink-inputs 2>/dev/null | \
    jq -r '.[] | select(.properties["application.name"]=="linux-wallpaperengine") | .index' | head -1)
  if [ -n "$idx" ]; then
    pactl set-sink-input-mute "$idx" 1
    break
  fi
  sleep 0.5
done &
disown

# Re-theme the desktop once the screenshot actually lands (retry - the
# process needs a moment to start rendering before it can capture a frame).
(
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    if [ -f "$SHOT" ]; then
      ~/.config/hypr/scripts/wallpaperengine_retheme.sh "$SHOT"
      break
    fi
    sleep 0.5
  done
) &
disown
