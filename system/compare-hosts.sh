#!/usr/bin/env bash
# Show what another machine has that is genuinely ABSENT here.
# Read-only: prints commands, runs nothing.
#
# Compares the other host's EXPLICIT list against this host's FULL installed
# set (pacman -Qq, not -Qqe). A package present here only as a dependency is
# still present -- reporting it as missing would be noise, and that same
# distinction is why `starship` and `hyprpicker` went unnoticed for so long.
set -uo pipefail
export LC_ALL=C          # comm requires both inputs in the SAME collation

cd "${DOTFILES_REPO:-$HOME/.dotfiles}" || exit 1
HOST="$(uname -n)"

shopt -s nullglob
snapshots=(system/hosts/*-native.txt)
if [ ${#snapshots[@]} -eq 0 ]; then
  echo "no host snapshots yet - run system/sync-manifests.sh on each machine"; exit 0
fi

here_all=$(mktemp); pacman -Qq | sort > "$here_all"
trap 'rm -f "$here_all"' EXIT

found_other=0
for f in "${snapshots[@]}"; do
  other="$(basename "$f" -native.txt)"
  [ "$other" = "$HOST" ] && continue
  found_other=1
  echo "=== on $other, absent on $HOST ==="

  miss_n=$(comm -13 "$here_all" <(sort "$f") | tr '\n' ' ')
  af="system/hosts/${other}-aur.txt"
  miss_a=""
  [ -f "$af" ] && miss_a=$(comm -13 "$here_all" <(sort "$af") | tr '\n' ' ')

  if [ -n "${miss_n// }" ]; then echo "  native: sudo pacman -S --needed $miss_n"; else echo "  native: nothing missing"; fi
  if [ -n "${miss_a// }" ]; then echo "  aur:    paru -S --needed $miss_a";        else echo "  aur:    nothing missing"; fi
  echo
done

[ "$found_other" -eq 0 ] && { echo "only $HOST has a snapshot so far"; exit 0; }

cat <<'NOTE'
  These machines legitimately differ - the diff is not meant to reach zero:
    asusctl / supergfxctl / rog-control-center   ROG chassis only
    amd-ucode vs intel-ucode                     per CPU vendor
    vulkan-intel / intel-media-driver            useless without an Intel iGPU
  Review before installing anything.
NOTE
