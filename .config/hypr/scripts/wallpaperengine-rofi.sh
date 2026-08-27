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
nohup linux-wallpaperengine --screen-root eDP-1 --bg "$chosen" \
  > "$HOME/.cache/wallpaperengine.log" 2>&1 &
disown
