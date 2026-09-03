#!/usr/bin/env bash
# Re-applies the "last-state" profile after waking from suspend.
#
# Why anything is needed at all: this controller has no onboard memory
# (OpenRGB's own UI shows "Saving Not Supported" for it), and some USB rails
# power-cycle across suspend even though the rest of the laptop resumes fine.
#
# "last-state" is saved manually from inside OpenRGB (Profiles > Save Profile),
# not captured by a script - this hardware cannot be read back from, so an
# external process has no way to discover what is currently showing.
#
# The profile carries the Effects Plugin's state too, not just static colors:
# the plugin hooks OpenRGB's own profile save/load (OnProfileSave /
# OnProfileAboutToLoad) and writes a "plugins" section into the profile JSON,
# with "AutoStart": true per effect. So restoring the profile restores the
# running effect - including a Layers stack - and not merely a colour
# snapshot. Anything built in the Effects tab must be re-saved over
# "last-state" to survive, or the profile still holds the previous effect.
#
# This drives the ALREADY RUNNING instance through its tray menu rather than
# running `openrgb --profile last-state`. That command starts a SECOND
# OpenRGB, which then fights the first one over the same USB controller - the
# exact failure that had six of them stacked up making the keyboard glitch.
pgrep -x openrgb >/dev/null || exit 0

# Give the USB rail a moment to settle before touching the device.
sleep 2

exec "$HOME/.config/hypr/scripts/openrgb_tray.sh" "last-state"
