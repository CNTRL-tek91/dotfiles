#!/usr/bin/env bash
# Bring OpenRGB up as EXACTLY ONE process running EXACTLY ONE effect, and say
# so in a log. Used for both boot and resume-from-sleep.
#
# Why a full restart rather than reloading the profile into the running
# instance (what openrgb_restore_state.sh did): after suspend the USB
# controller may have been re-enumerated underneath a still-running OpenRGB.
# Reloading a profile into that instance leaves the old effect's state behind,
# and the symptom is a second effect compositing over the first - a colour
# overlay that was never configured, plus glitching as two writers fight for
# the same 94 LEDs. Killing first is the only way to guarantee a clean slate,
# because this controller has no readable state to reconcile against.
#
# Everything here is verified rather than assumed: the count after starting is
# checked, and the effect is confirmed to have actually started in OpenRGB's
# own log before this reports success.
set -uo pipefail

LOG="$HOME/.cache/openrgb-restart.log"
log() { printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$LOG"; }

# `pgrep -xc` PRINTS 0 and EXITS 1 when nothing matches, so the obvious
# `$(pgrep -xc openrgb || echo 0)` yields the two-line string "0\n0" and every
# numeric test then fails with "integer expected". head -1 keeps it a number.
nrgb() { pgrep -xc openrgb 2>/dev/null | head -1; }

# Keep the log from growing without bound.
[ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 500 ] && tail -n 200 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"

log "--- restart requested (${1:-manual}) ---"

# 1. Stop everything. SIGTERM first so OpenRGB can release the USB handle.
before=$(nrgb)
if [ "$before" -gt 0 ]; then
  pkill -x openrgb
  for _ in 1 2 3 4 5 6 7 8 9 10; do
    sleep 0.5
    [ "$(nrgb)" -eq 0 ] && break
  done
  # Anything still alive after 5s is wedged; it must not survive into the
  # new instance or both will drive the controller.
  if [ "$(nrgb)" -gt 0 ]; then
    log "SIGTERM left $(nrgb) alive, sending SIGKILL"
    pkill -9 -x openrgb
    sleep 1
  fi
fi
log "stopped (was $before, now $(nrgb))"

# 2. Let the USB rail settle. On resume the device may not be back yet.
sleep 2

# 3. Start exactly one, loading the saved profile (which carries the effect
#    and its AutoStart flag).
openrgb --startminimized --profile last-state >/dev/null 2>&1 &
sleep 6

# 4. Verify the process count. More than one here means something else also
#    started OpenRGB - the whole failure this script exists to prevent.
count=$(nrgb)
if [ "$count" -eq 0 ]; then
  log "FAIL: nothing started; retrying once"
  openrgb --startminimized --profile last-state >/dev/null 2>&1 &
  sleep 6
  count=$(nrgb)
elif [ "$count" -gt 1 ]; then
  log "FAIL: $count processes after start - killing all but the newest"
  pgrep -x openrgb | head -n -1 | xargs -r kill
  sleep 2
  count=$(nrgb)
fi

# 5. Verify the effect actually started, not just that the process exists.
newlog=$(find "$HOME/.config/OpenRGB/logs" -name '*.log' -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
if [ -n "$newlog" ]; then
  # grep -c has the same shape as pgrep -xc: prints 0, exits 1 on no match.
  started=$(grep -c 'thread started' "$newlog" 2>/dev/null | head -1)
  ended=$(grep -c 'thread ended' "$newlog" 2>/dev/null | head -1)
  started=${started:-0}; ended=${ended:-0}
  live=$((started - ended))
  log "processes=$count  effects_live=$live  (started=$started ended=$ended)"
  if [ "$count" -eq 1 ] && [ "$live" -eq 1 ]; then
    log "OK"
  else
    log "WARN: expected 1 process and 1 effect"
  fi
else
  log "processes=$count  (no OpenRGB log found to check effects)"
fi
