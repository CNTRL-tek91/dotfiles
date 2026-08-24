#!/usr/bin/env bash
# Record THIS machine's installed packages into system/hosts/<hostname>-*.txt
# and commit if they changed.
#
# Run by the systemd user timer `dotfiles-manifest.timer`.
#
# Writes PER-HOST files on purpose. The shared system/pkglist-*.txt is the
# curated reference install list; if every machine wrote to it they would
# overwrite each other forever (Laptop 2 erasing asusctl, Laptop 1 erasing
# intel-ucode, ad infinitum).
#
# Installs nothing. It records state so the other machine can see the
# difference and you can decide.
set -uo pipefail

REPO="${DOTFILES_REPO:-$HOME/.dotfiles}"
HOST="$(uname -n)"
cd "$REPO" || { echo "no repo at $REPO"; exit 1; }

mkdir -p system/hosts
NATIVE="system/hosts/${HOST}-native.txt"
AUR="system/hosts/${HOST}-aur.txt"

pacman -Qqen | LC_ALL=C sort > "$NATIVE.tmp"
pacman -Qqem | LC_ALL=C sort > "$AUR.tmp"

changed=0
for f in "$NATIVE" "$AUR"; do
  if ! cmp -s "$f.tmp" "$f" 2>/dev/null; then mv "$f.tmp" "$f"; changed=1; else rm -f "$f.tmp"; fi
done

[ "$changed" -eq 0 ] && { echo "no package changes on $HOST"; exit 0; }

echo "package changes on $HOST:"
git --no-pager diff --stat -- "$NATIVE" "$AUR" 2>/dev/null || echo "  (first run)"

git add -- "$NATIVE" "$AUR"
git commit -q -m "Package snapshot: $HOST

$(wc -l < "$NATIVE") native, $(wc -l < "$AUR") AUR. Automated." || exit 0

if ! git pull --rebase --autostash -q origin main; then
  echo "rebase failed - commit left local, resolve by hand"
  git rebase --abort 2>/dev/null
  exit 1
fi
git push -q origin main && echo "pushed" || echo "push failed (offline?) - will retry next run"
