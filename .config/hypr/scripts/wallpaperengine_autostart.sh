#!/usr/bin/env bash
# Restores a live wallpaper across a reboot/relogin, if one was active when
# the machine was last shut down/suspended. linux-wallpaperengine is just a
# process - it obviously doesn't survive a power cycle - while autostart.conf's
# set_wallpaper.sh unconditionally re-applies the static ~/Pictures/wallpaper.png
# on every boot via awww, so without this a live wallpaper silently reverts to
# static on every reboot even though nothing asked for that.
#
# wallpaperengine_state is written by wallpaperengine_launch.sh whenever a live
# wallpaper is picked, and cleared by wallpaperengine_stop.sh - so its mere
# presence/absence here is exactly "was a live wallpaper the last thing active".
STATE="$HOME/.cache/wallpaperengine_state"
[ -s "$STATE" ] || exit 0

id="$(<"$STATE")"
WORKSHOP_DIR="$HOME/.local/share/Steam/steamapps/workshop/content/431960/$id"
[ -d "$WORKSHOP_DIR" ] || exit 0

exec ~/.config/hypr/scripts/wallpaperengine_launch.sh "$id"
