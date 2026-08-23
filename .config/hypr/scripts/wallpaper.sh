#!/usr/bin/env bash
# Apply a wallpaper AND regenerate the whole desktop palette from it.
# Usage: wallpaper.sh /path/to/image
WALL="$1"
if [ -z "$WALL" ] || [ ! -f "$WALL" ]; then
    echo "usage: wallpaper.sh /path/to/image" >&2
    exit 1
fi

# Auto dark/light: choose dark or light from the wallpaper's mean brightness
bright=$(magick "$WALL" -resize 1x1 -format "%[fx:mean]" info: 2>/dev/null)
pal="harddark16"; mode="dark"
if awk "BEGIN{exit !(${bright:-0} > 0.55)}" 2>/dev/null; then pal="light16"; mode="light"; fi

# Set the wallpaper
awww img "$WALL" --transition-type wipe --transition-duration 1 2>/dev/null

# Blurred lock-screen background for hyprlock (must be PNG) matching the wallpaper
magick "$WALL" -resize 1920x -blur 0x8 "$HOME/.cache/lockscreen.png" 2>/dev/null

# UI half — matugen (Material You): waybar, hyprland borders, tofi, dunst
matugen image "$WALL" -m "$mode" --prefer saturation 2>/dev/null

# Terminal + neovim half — wallust (distinct image colors): kitty, nvim
# -k/--check-contrast: force every color to a readable contrast vs the background
# (without it, some wallpapers yield near-black ANSI colors -> invisible terminal text)
wallust run -s -q -k -p "$pal" "$WALL"

# Reload everything so the new colors take effect live
# Re-apply waybar's CSS WITHOUT a full reload: a SIGUSR2 reload recreates waybar's
# layer-shell surface, which forces a relayout that kills XWayland windows (Firefox).
# Touching style.css triggers reload_style_on_change (style-only, surface untouched).
touch "$HOME/.config/waybar/style.css"
# Update window border colors live via hyprctl keyword — NOT `hyprctl reload`,
# which re-applies the monitor config and can close XWayland windows (e.g. Firefox).
ac=$(awk '/^\$color9 /{print $3}' "$HOME/.config/hypr/wallust/colors.conf")
inb=$(awk '/^\$color0 /{print $3}' "$HOME/.config/hypr/wallust/colors.conf")
[ -n "$ac" ]  && hyprctl keyword general:col.active_border "$ac"    >/dev/null 2>&1
[ -n "$inb" ] && hyprctl keyword general:col.inactive_border "$inb" >/dev/null 2>&1
dunstctl reload 2>/dev/null           # dunst re-reads dunstrc
killall -SIGUSR1 kitty 2>/dev/null    # kitty live-reloads its colors
# tofi has no daemon; it picks up the new colors on next launch

# Remember the choice so it loads on next boot
echo "$WALL" > "$HOME/.cache/current_wallpaper"
