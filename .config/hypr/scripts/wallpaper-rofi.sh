#!/usr/bin/env bash
# Graphical wallpaper picker: rofi showing wallpaper thumbnails in a horizontal
# row. Selecting one applies it AND triggers full dynamic theming via wallpaper.sh.

# Wallpapers live in the dotfiles repo and are symlinked in by stow, so find
# needs -L: it will not descend into a symlinked starting directory otherwise.
DIRS=("$HOME/Pictures/wallpapers")
THUMBS="$HOME/.cache/wallpaper-thumbs"
mkdir -p "$THUMBS"

# Emit one rofi entry per wallpaper: hidden full-path text + a cached thumbnail icon.
emit() {
    find -L "${DIRS[@]}" -maxdepth 1 -type f \
        \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | sort | \
    while read -r img; do
        thumb="$THUMBS/$(printf '%s' "$img" | sha1sum | cut -c1-16).png"
        if [ ! -f "$thumb" ] || [ "$img" -nt "$thumb" ]; then
            magick "$img" -thumbnail 400x240^ -gravity center -extent 400x240 "$thumb" 2>/dev/null
        fi
        printf '%s\0icon\x1f%s\n' "$img" "$thumb"
    done
}

chosen=$(emit | rofi -dmenu -i -p "Wallpaper" -theme "$HOME/.config/rofi/wallpaper.rasi")
[ -z "$chosen" ] && exit 0
exec "$HOME/.config/hypr/scripts/wallpaper.sh" "$chosen"
