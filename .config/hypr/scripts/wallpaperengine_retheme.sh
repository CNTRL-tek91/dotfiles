#!/usr/bin/env bash
# Re-themes the desktop from a live wallpaper's actual rendered frame - a
# live scene has no single static image the wal/matugen/wallust pipeline
# can read, so wallpaperengine-rofi.sh captures one via
# linux-wallpaperengine's own --screenshot flag (documented as built for
# exactly this integration, "for use with tools like PyWAL") and hands it
# here. Same pipeline as wallpaper.sh, minus the parts specific to actually
# setting a static wallpaper (awww img, remembering it for next boot) -
# the live scene itself stays the visible wallpaper.
SHOT="$1"
[ -f "$SHOT" ] || exit 1

# Auto dark/light: choose dark or light from the frame's mean brightness
bright=$(magick "$SHOT" -resize 1x1 -format "%[fx:mean]" info: 2>/dev/null)
pal="harddark16"; mode="dark"
if awk "BEGIN{exit !(${bright:-0} > 0.55)}" 2>/dev/null; then pal="light16"; mode="light"; fi

# Blurred lock-screen background matching the live wallpaper
magick "$SHOT" -resize 1920x -blur 0x8 "$HOME/.cache/lockscreen.png" 2>/dev/null

# UI half - matugen (Material You): waybar, hyprland borders, tofi, dunst
matugen image "$SHOT" -m "$mode" --prefer saturation 2>/dev/null

# Terminal + neovim half - wallust (distinct image colors): kitty, nvim
wallust run -s -q -k -p "$pal" "$SHOT"

# Reload everything so the new colors take effect live - same non-destructive
# approach as wallpaper.sh (touch style.css, not a full waybar reload; hyprctl
# keyword, not hyprctl reload - both avoid closing XWayland windows).
touch "$HOME/.config/waybar/style.css"
ac=$(awk '/^\$color9 /{print $3}' "$HOME/.config/hypr/wallust/colors.conf")
inb=$(awk '/^\$color0 /{print $3}' "$HOME/.config/hypr/wallust/colors.conf")
[ -n "$ac" ]  && hyprctl keyword general:col.active_border "$ac"    >/dev/null 2>&1
[ -n "$inb" ] && hyprctl keyword general:col.inactive_border "$inb" >/dev/null 2>&1
dunstctl reload 2>/dev/null
killall -SIGUSR1 kitty 2>/dev/null
