#!/usr/bin/env bash
# Regenerate the package manifests and commit them if they changed.
#
# Run by the systemd user timer `dotfiles-manifest.timer`. Deliberately does
# NOT install anything: it only records what this machine has, so the other
# machine can see the difference on its next `git pull`.
#
# Only ever stages the two manifest files, so unrelated work in progress is
# never swept into a commit.
set -uo pipefail

REPO="${DOTFILES_REPO:-$HOME/.dotfiles}"
cd "$REPO" || { echo "no repo at $REPO"; exit 1; }

NATIVE="system/pkglist-native.txt"
AUR="system/pkglist-aur.txt"

pacman -Qqen | LC_ALL=C sort > "$NATIVE.tmp"
pacman -Qqem | LC_ALL=C sort > "$AUR.tmp"

changed=0
for f in "$NATIVE" "$AUR"; do
  if ! cmp -s "$f.tmp" "$f"; then mv "$f.tmp" "$f"; changed=1; else rm -f "$f.tmp"; fi
done

if [ "$changed" -eq 0 ]; then
  echo "manifests unchanged"
  exit 0
fi

echo "manifests changed on $(uname -n):"
git --no-pager diff --stat -- "$NATIVE" "$AUR"

git add -- "$NATIVE" "$AUR"
git commit -q -m "Update package manifests from $(uname -n)

Automated: $(pacman -Qqen | wc -l) native, $(pacman -Qqem | wc -l) AUR." || exit 0

# Rebase onto the remote before pushing so the two machines cannot diverge.
# --autostash keeps any unrelated work in progress out of the way.
if ! git pull --rebase --autostash -q origin main; then
  echo "rebase failed - leaving the commit local, resolve by hand"
  git rebase --abort 2>/dev/null
  exit 1
fi

if git push -q origin main; then
  echo "pushed"
else
  echo "push failed (offline?) - commit is local, will go out next run"
fi
