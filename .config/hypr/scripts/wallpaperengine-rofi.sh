#!/usr/bin/env bash
# Live wallpaper picker: rofi showing Wallpaper Engine Workshop thumbnails in
# a horizontal row (same layout as wallpaper-rofi.sh). Selecting one renders
# it as the actual desktop background via linux-wallpaperengine, since the
# Wallpaper Engine Steam app itself can't paint a Wayland desktop - it only
# knows how to hook into Windows' compositor, even under Proton.

WORKSHOP_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960"
THUMBS="$HOME/.cache/wallpaperengine-thumbs"
mkdir -p "$THUMBS"

emit() {
  for dir in "$WORKSHOP_DIR"/*/; do
    id="$(basename "$dir")"
    preview="$dir/preview.jpg"
    [ -f "$preview" ] || preview="$dir/preview.gif"
    [ -f "$preview" ] || continue
    thumb="$THUMBS/$id.png"
    if [ ! -f "$thumb" ] || [ "$preview" -nt "$thumb" ]; then
      magick "$preview[0]" -thumbnail 400x240^ -gravity center -extent 400x240 "$thumb" 2>/dev/null
    fi
    printf '%s\0icon\x1f%s\n' "$id" "$thumb"
  done
}

chosen=$(emit | rofi -dmenu -i -p "Live Wallpaper" -theme "$HOME/.config/rofi/wallpaper.rasi")
[ -z "$chosen" ] && exit 0

pkill -f 'linux-wallpaperengine' 2>/dev/null
# --layer background: without it, linux-wallpaperengine defaults to the
# "bottom" layer - the same level waybar renders on - and since it's a
# full-screen surface added after waybar, it covers the bar entirely.
# --silent alone isn't fully trusted here: it suppresses sound generation,
# but PipeWire still shows an unmuted, 100%-volume stream for the process.
# Muted explicitly below as a guaranteed backstop.
nohup linux-wallpaperengine --layer background --silent --screen-root eDP-1 --bg "$chosen" \
  > "$HOME/.cache/wallpaperengine.log" 2>&1 &
disown

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
