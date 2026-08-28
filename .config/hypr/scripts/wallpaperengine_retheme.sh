#!/usr/bin/env bash
# Re-themes the desktop from a live wallpaper's actual rendered frame.
# A live scene has no single static image the theming pipeline can read, so
# wallpaperengine-rofi.sh captures one via linux-wallpaperengine's own
# --screenshot flag (documented as built for exactly this, "for use with
# tools like PyWAL") and hands it here. Just forwards to apply_wal_theme.sh -
# the actual pipeline everything (kitty, waybar, LibreWolf via pywalfox)
# reads from - with the screenshot as an override instead of the real
# wallpaper. The SDDM login background is untouched by that override on
# purpose: it stays synced to the real static wallpaper, not a live-preview
# frame.
SHOT="$1"
[ -f "$SHOT" ] || exit 1

~/.config/hypr/scripts/apply_wal_theme.sh "$SHOT"
