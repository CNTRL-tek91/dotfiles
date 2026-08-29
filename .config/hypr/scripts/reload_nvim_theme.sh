#!/usr/bin/env bash
# Tell every running Neovim to pick up the new wallpaper palette.
#
# nvim always opens a server socket at $XDG_RUNTIME_DIR/nvim.<pid>.<n>, so
# running instances can be reached without any per-instance setup. --remote-expr
# is used rather than --remote-send because it evaluates an expression instead
# of injecting keystrokes - sending keys would corrupt whatever the user is
# typing, and would misfire outside normal mode.
#
# Every instance is handled independently and failures are ignored: sockets go
# stale when an nvim exits, and a dead socket must not stop the live ones from
# updating.
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
LUA="$HOME/.config/hypr/scripts/nvim_wal_reload.lua"
LOG="$HOME/.cache/nvim-theme-reload.log"

# Keep a short log. apply_wal_theme.sh calls this with stderr discarded, and it
# runs from a backgrounded subshell during live-wallpaper changes, so without a
# log a failure here is completely invisible - the editor just keeps its old
# colours and there is nothing to look at. Trimmed so it cannot grow unbounded.
log() { printf '%s %s\n' "$(date +%H:%M:%S)" "$*" >> "$LOG"; }
[ -f "$LOG" ] && [ "$(wc -l < "$LOG")" -gt 200 ] && tail -50 "$LOG" > "$LOG.tmp" && mv "$LOG.tmp" "$LOG"

[ -f "$LUA" ] || { log "abort: no $LUA"; exit 0; }
command -v nvim >/dev/null 2>&1 || { log "abort: nvim not in PATH ($PATH)"; exit 0; }

shopt -s nullglob
found=0
for sock in "$RUNTIME"/nvim.*; do
  [ -S "$sock" ] || continue
  found=$((found + 1))
  # Backgrounded so one unresponsive instance (mid-operation, or blocked on a
  # prompt) cannot hold up the rest of the theming pipeline.
  {
    if err=$(timeout 5 nvim --server "$sock" \
               --remote-expr "execute('luafile $LUA')" 2>&1); then
      log "ok   $(basename "$sock")"
    else
      log "FAIL $(basename "$sock") -> ${err:-timeout/no-response}"
    fi
  } &
done
wait
[ "$found" -eq 0 ] && log "no nvim sockets in $RUNTIME"
exit 0
