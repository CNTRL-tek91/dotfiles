#!/usr/bin/env bash
# Show what the OTHER machine has that this one does not.
# Read-only: prints commands, runs nothing.
set -uo pipefail
cd "${DOTFILES_REPO:-$HOME/.dotfiles}" || exit 1
HOST="$(uname -n)"

shopt -s nullglob
others=(system/hosts/*-native.txt)
[ ${#others[@]} -eq 0 ] && { echo "no host snapshots yet - run sync-manifests.sh on each machine"; exit 0; }

for f in "${others[@]}"; do
  other="$(basename "$f" -native.txt)"
  [ "$other" = "$HOST" ] && continue
  echo "=== on $other but not on $HOST ==="
  miss_n=$(comm -13 <(pacman -Qqen | LC_ALL=C sort) <(LC_ALL=C sort "$f") | tr '\n' ' ')
  miss_a=$(comm -13 <(pacman -Qqem | LC_ALL=C sort) <(LC_ALL=C sort "system/hosts/${other}-aur.txt" 2>/dev/null) | tr '\n' ' ')
  [ -n "${miss_n// }" ] && echo "  native: sudo pacman -S --needed $miss_n" || echo "  native: nothing missing"
  [ -n "${miss_a// }" ] && echo "  aur:    paru -S --needed $miss_a"        || echo "  aur:    nothing missing"
  echo
  echo "  NOTE: the machines legitimately differ. asusctl/supergfxctl/rog-control-center"
  echo "  are ROG-only, and amd-ucode vs intel-ucode is per-CPU. Review before installing."
done
