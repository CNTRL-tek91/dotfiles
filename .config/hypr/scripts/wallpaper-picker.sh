#!/usr/bin/env bash
# Browse wallpapers with tofi and apply the chosen one (with dynamic theming).
DIRS=("$HOME/.config/assets/backgrounds" "$HOME/Pictures/Wallpapers")
choice=$(find "${DIRS[@]}" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null \
    | sed "s|^$HOME/||" \
    | tofi --prompt-text "wallpaper: " -c "$HOME/.config/tofi/configA")
[ -z "$choice" ] && exit 0
exec "$HOME/.config/hypr/scripts/wallpaper.sh" "$HOME/$choice"
