# System manifests

Snapshots of machine-level state that lives outside `$HOME`. Nothing here is
applied automatically — review each file before using it on a new machine.

| File | Restore with |
|---|---|
| `pkglist-native.txt` | `pacman -S --needed - < pkglist-native.txt` |
| `pkglist-aur.txt` | `paru -S --needed - < pkglist-aur.txt` |
| `zram-generator.conf` | copy to `/etc/systemd/` |
| `nvidia.conf`, `nvidia-power.conf` | copy to `/etc/modprobe.d/`, then `mkinitcpio -P` |
| `services.txt` / `services-user.txt` | reference lists, enable by hand |

## Exclude on non-ROG hardware

`asusctl`, `supergfxctl`, `rog-control-center` are ASUS ROG only.
`os-prober` only mattered for the Windows dual-boot on this machine.
`supergfxd` also supplies the nouveau blacklist — replace it manually elsewhere.

`nvidia-open-dkms` requires Turing (RTX 20 / GTX 16) or newer. Use `nvidia-dkms`
on Pascal and older.

## Not covered by the package lists

These are referenced by the configs but were installed by hand on Laptop 1, so
they do not appear in `pacman -Qqe` output. Install them or the desktop will
come up with default GTK theming, wrong icons and the wrong cursor.

| Needed for | Install |
|---|---|
| GTK theme — `gtk-3.0/settings.ini` wants `Flat-Remix-GTK-Blue-Dark` | `paru -S flat-remix-gtk` |
| Icon theme — `gtk-3.0/settings.ini` wants `Flat-Remix-Blue-Light` | `paru -S flat-remix` |
| Cursor — `Bibata-Modern-Ice`, set via nwg-look and `~/.icons/default` | `paru -S bibata-cursor-theme-bin` |
| `adw-gtk3-dark`, set by `hypr/configs/autostart.conf` | `pacman -S adw-gtk-theme` |

On Laptop 1 these live in `~/.themes` (5.6 MB) and `~/.icons` (664 MB). They are
deliberately **not** committed — the packages above provide the same files.

### SDDM login theme

`hypr/scripts/apply_wal_theme.sh` syncs the login background to the current
wallpaper by writing to `/usr/share/sddm/themes/simple_sddm_2/Backgrounds/default`.
That theme is not packaged; it was cloned by hand:

```sh
sudo git clone https://github.com/JaKooLit/simple-sddm-2.git \
  /usr/share/sddm/themes/simple_sddm_2
sudo chown -R "$USER" /usr/share/sddm/themes/simple_sddm_2/Backgrounds
printf '[Theme]\nCurrent=simple_sddm_2\n' | sudo tee /etc/sddm.conf.d/theme.conf
```

The wallpaper sync is guarded by `[ -w ... ]`, so it silently does nothing if the
theme is missing — you get no error, just a login screen that never changes.

### Known inconsistency

Two different mechanisms set the GTK theme to two different values:
`gtk-3.0/settings.ini` says `Flat-Remix-GTK-Blue-Dark`, while
`hypr/configs/autostart.conf` runs `gsettings set ... gtk-theme 'adw-gtk3-dark'`.
`adw-gtk3` is not currently installed on Laptop 1 at all, so that gsettings call
sets a theme that does not exist. Worth resolving to one or the other.

## Why `pacman -Qqe` is not a complete manifest

Three defects surfaced while building Laptop 2 from these lists. All three
share a root cause: `pacman -Qqe` records what was *explicitly requested*, not
what the configs actually need.

| Package | Problem | Fix |
|---|---|---|
| `starship` | Prompt is invoked by `.zshrc` on every shell, but it arrived on Laptop 1 as a **dependency**, so it never appeared in `-Qqe` | added to `pkglist-native.txt` |
| `hyprpicker` | Bound in the Hyprland config; also dependency-only on Laptop 1 | added to `pkglist-native.txt` |
| `librewolf-bin` | **Removed from the AUR** — LibreWolf now ships in the official `extra` repo. One dead target aborts the whole `paru` transaction, so nothing installs | dropped from `pkglist-aur.txt`; `librewolf` added to `pkglist-native.txt` |

Before trusting these lists on a new machine, validate every AUR target still
exists — one missing package aborts the entire transaction:

```sh
for p in $(cat system/pkglist-aur.txt); do
  paru -Si "$p" >/dev/null 2>&1 || echo "GONE: $p"
done
```

And check that everything your configs invoke is actually installed, not just
what is in the manifest — that is how `starship` and `hyprpicker` were caught.

## Dead references (missing on BOTH machines)

These are invoked by configs or aliases but installed on neither laptop. They
are pre-existing and harmless; the aliases simply fail if used:
`spicetify`, `swww`, `docker`, `wg-quick`, `awg-quick`, `traceroute`, `rustmon`.

## Keeping the two machines in sync

Three layers, three mechanisms. They are deliberately separate:

| Layer | Mechanism | Automatic? |
|---|---|---|
| Config (this repo) | git | **No** — you commit when a change is good |
| Working files (`~/Projects`, `~/Documents`, …) | Syncthing | Yes, continuous |
| Installed packages | `sync-manifests.sh` + systemd timer | Records daily; **installing is still manual** |

### Package manifests

`system/sync-manifests.sh` records **this machine's** packages into
`system/hosts/<hostname>-{native,aur}.txt` and commits if they changed.

Per-host files are deliberate. The shared `system/pkglist-*.txt` is the curated
reference install list — if every machine wrote to it, they would overwrite each
other forever (Laptop 2 erasing `asusctl`, Laptop 1 erasing `intel-ucode`).

Enable on each machine:

```sh
mkdir -p ~/.config/systemd/user
cp ~/.dotfiles/system/systemd/dotfiles-manifest.{service,timer} ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now dotfiles-manifest.timer
```

To see what the *other* machine has that this one does not:

```sh
git -C ~/.dotfiles pull
~/.dotfiles/system/compare-hosts.sh
```

It prints the `pacman`/`paru` commands but runs nothing. The diff is never meant
to reach zero — the machines legitimately differ by chassis and CPU vendor.

### Syncthing

Peer-to-peer, no cloud. Both machines must be **on at the same time** for changes
to move; nothing stores them in between. It syncs, it does not merge — editing
the same file on both while disconnected leaves a `*.sync-conflict-*` copy.

**Never sync** `~/.config` (git owns it), `~/.cache`, browser profiles, or
anything with a live SQLite database — concurrent writes corrupt them.
`~/Pictures/wallpapers` is a symlink into this repo and is excluded via
`.stignore` so the two tools cannot fight over the same files.
