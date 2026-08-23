#!/bin/bash

image_dir="$HOME/Pictures/wallpapers"

# Only list regular image files (skip subdirectories like Dynamic-Wallpapers).
declare -A name_to_path
image_list=""
shopt -s nullglob nocaseglob
for img in "$image_dir"/*.{png,jpg,jpeg,webp,gif,bmp}; do
    [ -f "$img" ] || continue
    name="$(basename "${img%.*}")"          # filename without extension
    name_to_path["$name"]="$img"
    image_list+="${name}\x00icon\x1f${img}\n"
done
shopt -u nullglob nocaseglob

selected_image=$(printf '%b' "$image_list" | rofi -dmenu -theme ~/.config/rofi/wallpaper-select.rasi -p "Select wallpaper")
[ -z "$selected_image" ] && exit 0

selected_image_path="${name_to_path[$selected_image]}"

if [ -n "$selected_image_path" ] && [ -f "$selected_image_path" ]; then
  ln -sfn "$selected_image_path" ~/Pictures/wallpaper.png

  if [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    . ~/.config/hypr/scripts/set_wallpaper.sh
  else
    i3-msg restart
  fi

  notify-send -a "Wallpaper selector" "Wallpaper changed" "$selected_image_path" -i ~/Pictures/wallpaper.png
  . ~/.config/hypr/scripts/apply_wal_theme.sh
fi
