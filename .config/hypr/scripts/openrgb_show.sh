#!/usr/bin/env bash
# Click handler for waybar's "custom/rgb" button: surface the OpenRGB that is
# already running, rather than starting another one.
#
# Neither obvious approach works here:
#   - A bare `openrgb` starts a SECOND instance. OpenRGB is not
#     single-instance, so repeated clicks stack them up and they fight over
#     the same USB controller - that is the keyboard "glitching everywhere".
#   - The tray icon's StatusNotifierItem.Activate method is a no-op in
#     OpenRGB's Qt tray. It returns success and does nothing (verified).
#
# What does work is the tray menu's own "Show/Hide" entry, driven over the
# com.canonical.dbusmenu interface that the tray icon already exports.
#
# There is usually no window to raise at all: OpenRGB autostarts with
# --startminimized, and its minimize_on_close setting means closing the
# window destroys it while leaving the process running in the tray.
set -u

CLASS="org.openrgb.OpenRGB"

# A window already exists - just focus it. Deliberately NOT Show/Hide, which
# would toggle the window back off.
if hyprctl -j clients 2>/dev/null | grep -q "\"$CLASS\""; then
  hyprctl dispatch focuswindow "class:$CLASS" >/dev/null 2>&1
  exit 0
fi

# Not running at all - start it the same way autostart does, so the saved
# lighting comes back with it.
if ! pgrep -x openrgb >/dev/null; then
  openrgb --startminimized --profile last-state >/dev/null 2>&1 &
  exit 0
fi

# Running, but tray-only. Ask its tray menu to show the window. The menu item
# id is assigned at runtime, so look it up by label instead of hardcoding it.
for name in $(busctl --user list --no-pager 2>/dev/null | awk '/openrgb/{print $1}'); do
  layout=$(gdbus call --session --dest "$name" --object-path /MenuBar \
    --method com.canonical.dbusmenu.GetLayout -- 0 -1 "[]" 2>/dev/null) || continue

  id=$(printf '%s' "$layout" | python3 -c "
import re, sys
m = re.search(r\"\((\d+), \{[^{}]*'label': <'Show/Hide'>\", sys.stdin.read())
print(m.group(1) if m else '')
" 2>/dev/null)
  [ -n "$id" ] || continue

  gdbus call --session --dest "$name" --object-path /MenuBar \
    --method com.canonical.dbusmenu.Event "$id" "clicked" "<0>" 0 >/dev/null 2>&1
  exit 0
done

exit 0
