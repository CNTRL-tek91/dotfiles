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

# Refresh the frozen requirements of venvs that are ALREADY tracked, so an
# environment recorded in this repo cannot silently drift from what is
# installed. system/<venv>-requirements.txt <-> ~/.venvs/<venv>.
#
# Deliberately opt-in: only files that already exist are refreshed. Creating a
# venv does not enrol it, because most are scratch - the first run of this
# after adding ~/.venvs/testvenv committed an empty manifest for it, which is
# accurate and useless. To track a new venv, freeze it once by hand and this
# keeps it current from then on.
#
# Folded into THIS script rather than given a timer of its own: two units both
# committing and pushing the same repo would race, and the pull --rebase / push
# handling below only needs to exist once.
#
# A full `uv pip freeze` is used rather than the hand-written install list - it
# pins transitive dependencies, so it reproduces the environment instead of
# re-resolving it. Sorted so the diffs stay readable; uv's own output order is
# not stable under LC_ALL=C.
VENVS="$HOME/.venvs"
if command -v uv >/dev/null; then
  for rec in system/*-requirements.txt; do
    [ -e "$rec" ] || continue
    name="$(basename "$rec")"; name="${name%-requirements.txt}"
    venv="$VENVS/$name"

    # Venv gone: drop the record rather than leave a stale manifest behind.
    # Plain rm, then stage the path explicitly - `git rm --ignore-unmatch`
    # exits 0 on an untracked file WITHOUT deleting it, so a `|| rm -f`
    # fallback never fires and the stale manifest survives.
    if [ ! -x "$venv/bin/python" ]; then
      rm -f "$rec"
      git add -A -- "$rec" 2>/dev/null
      changed=1
      continue
    fi

    VIRTUAL_ENV="$venv" uv pip freeze 2>/dev/null | LC_ALL=C sort > "$rec.tmp" || { rm -f "$rec.tmp"; continue; }

    # An empty freeze on a venv that previously had packages means uv failed,
    # not that the venv emptied itself - never let that blank a good manifest.
    if [ ! -s "$rec.tmp" ] && [ -s "$rec" ]; then
      echo "  skipped $name: freeze came back empty, keeping the existing manifest"
      rm -f "$rec.tmp"
      continue
    fi

    if ! cmp -s "$rec.tmp" "$rec" 2>/dev/null; then mv "$rec.tmp" "$rec"; changed=1; else rm -f "$rec.tmp"; fi
  done
fi

[ "$changed" -eq 0 ] && { echo "no package or venv changes on $HOST"; exit 0; }

echo "changes on $HOST:"
git --no-pager diff --stat HEAD -- "$NATIVE" "$AUR" system/*-requirements.txt 2>/dev/null || echo "  (first run)"

git add -A -- "$NATIVE" "$AUR" system/*-requirements.txt
git commit -q -m "Package snapshot: $HOST

$(wc -l < "$NATIVE") native, $(wc -l < "$AUR") AUR. Automated." || exit 0

if ! git pull --rebase --autostash -q origin main; then
  echo "rebase failed - commit left local, resolve by hand"
  git rebase --abort 2>/dev/null
  exit 1
fi
git push -q origin main && echo "pushed" || echo "push failed (offline?) - will retry next run"
