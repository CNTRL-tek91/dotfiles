#!/usr/bin/env bash
# Click handler for waybar's network modules: open something that can actually
# join a different wifi network.
#
# The previous on-click ran `networkmanager_dmenu` unguarded, and that binary is
# not installed - clicking the icon did nothing at all, silently (the shell
# reported "command not found" to a stderr nobody reads).
#
# Preference order, and why:
#   1. networkmanager_dmenu - a rofi list of visible networks, click to join.
#      Matches how the rest of this bar works (the wallpaper and CPU pickers
#      are both rofi). Install with: pacman -S networkmanager-dmenu
#   2. nmtui in a terminal - "Activate a connection" scans and joins. Not as
#      pretty but always available, since it ships with NetworkManager.
#
# nm-connection-editor is deliberately NOT used as the fallback. It is a GUI,
# but it edits SAVED connection profiles - it does not scan for nearby networks,
# so it cannot do the one thing this button is for.
set -u

# rofi refuses to start a second instance, so a second click while the menu is
# open is harmless - but say so rather than appearing to do nothing.
if pgrep -x rofi >/dev/null; then
  notify-send -a Network -u low "Network menu already open"
  exit 0
fi

if command -v networkmanager_dmenu >/dev/null; then
  exec networkmanager_dmenu
fi

if command -v nmtui >/dev/null; then
  exec kitty --class nmtui -e nmtui
fi

notify-send -a Network -u critical "No network menu available" \
  "Install networkmanager-dmenu, or check that nmtui is present."
