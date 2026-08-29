#!/usr/bin/env bash
# Login/boot autostart for OpenRGB. Starts it minimized AND immediately loads
# the "last-state" profile saved by openrgb_save_state.sh, so whatever effect
# (Rain, a custom color, the Effects Plugin's rainbow-wave, etc.) was active
# when the machine last went to sleep/shut down comes right back - otherwise
# a fresh start leaves the keyboard on its own firmware-default rainbow,
# since this controller has no onboard memory of its own. `--profile` on a
# name that doesn't exist yet (e.g. the very first run, before any state has
# ever been saved) is a harmless no-op, not an error.
#
# Wrapped in a retry instead of calling `openrgb` directly from exec-once:
# observed once that the raw exec-once invocation silently vanished a few
# seconds into Hyprland's own startup - log stops mid hardware-detection,
# no crash trace, no process left behind. Most likely an early D-Bus/tray
# race this specific moment in the boot sequence hits and a plain retry
# doesn't. Rather than chase a one-off, transient race further, just make
# sure a failure here doesn't cost the whole session's keyboard lighting.
for _ in 1 2 3; do
  openrgb --startminimized --profile last-state &
  pid=$!
  sleep 3
  if kill -0 "$pid" 2>/dev/null; then
    exit 0
  fi
done
