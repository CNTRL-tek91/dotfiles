#!/usr/bin/env bash
# Browse wallpapers with tofi and apply the chosen one (with dynamic theming).
# Wallpapers live in the dotfiles repo and are symlinked in by stow, so find
# needs -L: it will not descend into a symlinked starting directory otherwise.
DIRS=("$HOME/Pictures/wallpapers")
choice=$(find -L "${DIRS[@]}" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null \
    | sed "s|^$HOME/||" \
    | tofi --prompt-text "wallpaper: " -c "$HOME/.config/tofi/configA")
[ -z "$choice" ] && exit 0
exec "$HOME/.config/hypr/scripts/wallpaper.sh" "$HOME/$choice"
