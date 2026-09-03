#!/usr/bin/env bash
# Trigger an entry in OpenRGB's tray menu on the ALREADY RUNNING instance.
#
#   openrgb_tray.sh "Show/Hide"        # click it
#   openrgb_tray.sh --find "last-state" # print its id, change nothing
#
# Why this exists: OpenRGB is not single-instance, so anything that shells out
# to `openrgb` again starts a second copy, and two copies writing to the same
# USB controller is what made the keyboard glitch. The tray icon exports its
# menu over com.canonical.dbusmenu, so the running instance can be driven
# directly instead. StatusNotifierItem.Activate is NOT an alternative - it is
# a no-op in OpenRGB's Qt tray (returns success, does nothing).
#
# Menu item ids are assigned at runtime, so they are always looked up by
# label rather than hardcoded.
set -u

find_only=0
[ "${1:-}" = "--find" ] && { find_only=1; shift; }
label="${1:-}"
[ -n "$label" ] || { echo "usage: $(basename "$0") [--find] <menu label>" >&2; exit 2; }

pgrep -x openrgb >/dev/null || exit 0

for name in $(busctl --user list --no-pager 2>/dev/null | awk '/openrgb/{print $1}'); do
  layout=$(gdbus call --session --dest "$name" --object-path /MenuBar \
    --method com.canonical.dbusmenu.GetLayout -- 0 -1 "[]" 2>/dev/null) || continue
  [ -n "$layout" ] || continue

  id=$(printf '%s' "$layout" | LABEL="$label" python3 -c "
import os, re, sys
want = os.environ['LABEL']
s = sys.stdin.read()
for m in re.finditer(r\"\((\d+), \{[^{}]*'label': <'([^']*)'>\", s):
    if m.group(2) == want:
        print(m.group(1)); break
" 2>/dev/null)
  [ -n "$id" ] || continue

  if [ "$find_only" = 1 ]; then
    echo "$id"
    exit 0
  fi

  gdbus call --session --dest "$name" --object-path /MenuBar \
    --method com.canonical.dbusmenu.Event "$id" "clicked" "<0>" 0 >/dev/null 2>&1
  exit 0
done

exit 1
