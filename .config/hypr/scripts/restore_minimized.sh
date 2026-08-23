#!/usr/bin/env python3
"""Restore ONE minimized window per invocation (most-recently-minimized first).

Windows are "minimized" by moving them to the special:minimized workspace
(Super+M in binds.conf). This script brings back a single window — the one
minimized most recently — to the workspace you're currently looking at, and
focuses it. Pressing it again restores the next one, giving a LIFO stack.

"Most recently minimized" == the parked window with the smallest focusHistoryID:
Hyprland numbers windows by focus recency (0 = focused now), and you always
minimize the window that was focused, so among the parked windows the smallest
id is the one stashed most recently.
"""
import json
import subprocess
import sys

SPECIAL = "special:minimized"


def hypr_json(*args):
    out = subprocess.run(["hyprctl", "-j", *args], capture_output=True, text=True).stdout
    return json.loads(out) if out.strip() else None


def dispatch(*args):
    subprocess.run(["hyprctl", "dispatch", *args])


def main():
    clients = hypr_json("clients") or []
    parked = [c for c in clients if c.get("workspace", {}).get("name") == SPECIAL]
    if not parked:
        sys.exit(0)  # nothing is minimized

    # smallest focusHistoryID = most recently used = most recently minimized
    target = min(parked, key=lambda c: c.get("focusHistoryID", 1 << 30))
    addr = target["address"]

    cur = hypr_json("activeworkspace") or {}
    cur_id = cur.get("id")
    if cur_id is None:
        sys.exit(0)

    # bring it onto the current workspace and focus it
    dispatch("movetoworkspacesilent", f"{cur_id},address:{addr}")
    dispatch("focuswindow", f"address:{addr}")


if __name__ == "__main__":
    main()
