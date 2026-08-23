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
