#!/usr/bin/env bash
# Reapplies the "last-state" profile after waking from suspend. This
# controller has no onboard memory (OpenRGB's own UI shows "Saving Not
# Supported" for it), and some USB rails power-cycle across suspend even
# though the rest of the laptop resumes fine - either way, the safe move is
# to just always re-push the saved profile after resume rather than assume
# the keyboard remembered it on its own.
#
# "last-state" is saved manually, from inside OpenRGB itself (File > Save
# Profile As > "last-state"), not captured automatically by a script here -
# see openrgb_autostart.sh for why: this hardware can't be read back from,
# so an external process has no way to discover what's currently showing.
pgrep -x openrgb >/dev/null || exit 0
sleep 1
openrgb --profile last-state >/dev/null 2>&1
