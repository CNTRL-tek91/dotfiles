#!/usr/bin/env bash
# Run "$1" in a persistent, dedicated kitty output window.
# First call opens the window; later calls reuse it, so output accumulates.
CMD="$1"
SOCK="unix:/tmp/nvim-runner.sock"

# If the runner window isn't reachable, spawn a fresh persistent one.
if ! kitten @ --to "$SOCK" ls >/dev/null 2>&1; then
    rm -f /tmp/nvim-runner.sock 2>/dev/null          # drop any stale socket from a closed window
    kitty --class nvim-runner \
          -o allow_remote_control=yes \
          -o confirm_os_window_close=0 \
          --listen-on "$SOCK" >/dev/null 2>&1 &
    # wait for its remote-control socket to come up
    for _ in $(seq 1 50); do
        kitten @ --to "$SOCK" ls >/dev/null 2>&1 && break
        sleep 0.1
    done
fi

# Send the command (with a trailing newline = Enter) to the window's shell.
kitten @ --to "$SOCK" send-text -- "$CMD"$'\n'
