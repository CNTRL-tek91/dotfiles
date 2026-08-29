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

[ -f "$LUA" ] || exit 0
command -v nvim >/dev/null 2>&1 || exit 0

shopt -s nullglob
for sock in "$RUNTIME"/nvim.*; do
  [ -S "$sock" ] || continue
  # Backgrounded so one unresponsive instance (mid-operation, or blocked on a
  # prompt) cannot hold up the rest of the theming pipeline.
  timeout 5 nvim --server "$sock" \
    --remote-expr "execute('luafile $LUA')" >/dev/null 2>&1 &
done
wait
exit 0
