#!/usr/bin/env bash
# Click handler for waybar's network modules: pick a network, then CHECK that it
# actually works.
#
# Three problems this exists to solve, all observed on this machine:
#
#  1. `networkmanager_dmenu` alone was not installed at all originally, so the
#     click silently did nothing (the shell's "command not found" goes to a
#     stderr nobody reads).
#  2. NetworkManager reports "Connection successfully activated" for a network
#     carrying no data. A phone hotspot whose mobile data is off, or a captive
#     portal, both associate and lease an IP happily. So after the picker exits
#     this verifies the chain that actually matters - gateway, DNS, then a real
#     HTTPS request - and says which step failed.
#  3. A phone hotspot takes longer to advertise than the picker's default scan
#     window. Measured here: absent at 6s, present at ~12s. rescan_delay in
#     config.ini is raised to 15 for that reason, and this script kicks a scan
#     off BEFORE opening the menu so the list is warm by the time it draws.
set -u

notify() { notify-send -a Network "$@"; }

# rofi refuses a second instance, so a second click is harmless - but say so
# rather than appearing dead.
if pgrep -x rofi >/dev/null; then
  notify -u low "Network menu already open"
  exit 0
fi

# Warm the scan list before the menu draws. Backgrounded: NetworkManager keeps
# scanning while rofi is up, so by the time you have read the list a slow
# hotspot has usually appeared. Harmless when the radio is off.
if [ "$(nmcli -t radio wifi 2>/dev/null)" = "enabled" ]; then
  nmcli device wifi rescan >/dev/null 2>&1 &
fi

before=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1)

if command -v networkmanager_dmenu >/dev/null; then
  networkmanager_dmenu
elif command -v nmtui >/dev/null; then
  kitty --class nmtui -e nmtui
else
  notify -u critical "No network menu available" "Install networkmanager-dmenu."
  exit 1
fi

# --- verify -----------------------------------------------------------------
# Only worth reporting if the connection actually changed; otherwise the user
# just looked at the menu and closed it.
after=$(nmcli -t -f NAME connection show --active 2>/dev/null | head -1)
[ "$after" = "$before" ] && exit 0
[ -z "$after" ] && { notify -u normal "Disconnected"; exit 0; }

dev=$(nmcli -t -f DEVICE,TYPE device status 2>/dev/null | awk -F: '$2=="wifi"{print $1; exit}')
gw=$(nmcli -t -f IP4.GATEWAY device show "$dev" 2>/dev/null | cut -d: -f2 | head -1)

# Give DHCP a moment to finish before judging it.
sleep 3

fail=""
[ -n "$gw" ] || fail="no gateway (DHCP did not complete)"
if [ -z "$fail" ] && ! ping -c1 -W3 "$gw" >/dev/null 2>&1; then
  fail="gateway $gw unreachable"
fi
if [ -z "$fail" ] && ! getent hosts github.com >/dev/null 2>&1; then
  fail="DNS not resolving"
fi
if [ -z "$fail" ]; then
  code=$(curl -s --max-time 8 -o /dev/null -w '%{http_code}' https://github.com 2>/dev/null)
  [ "$code" = "200" ] || fail="no internet (HTTPS returned '${code:-nothing}')"
fi

if [ -n "$fail" ]; then
  # The distinction that matters: associated but not usable. On a hotspot this
  # almost always means mobile data is off on the phone.
  notify -u critical "$after: connected but NOT working" "$fail"
else
  notify -u low "$after: connected and working" "gateway $gw, DNS and HTTPS OK"
fi
