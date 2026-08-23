# dotfiles

Hyprland desktop on Arch Linux. Wayland throughout, themed dynamically from the
current wallpaper via [wallust](https://codeberg.org/explosion-mental/wallust)
and pywal, so every application's palette follows whatever is on screen.

## What's in here

| | |
|---|---|
| Compositor | Hyprland 0.55 — `hypridle`, `hyprlock`, `hyprpolkitagent` |
| Bar | Waybar, with a cava audio-visualiser module |
| Launcher | rofi (plus tofi and fuzzel), with menus for wallpapers, clipboard, emoji, calc and theme switching |
| Notifications | swaync, dunst, swayosd for volume and brightness overlays |
| Terminal | kitty, with ghostty and wezterm configured alongside |
| Editor | Neovim, lazy.nvim, plugin versions pinned in `lazy-lock.json` |
| Shell | zsh with zinit, starship, zoxide, fzf-tab |
| Theming | wallust and matugen templates, Kvantum, qt5ct/qt6ct, GTK 3/4 |
| Files | Thunar, `lf` |
| Login | SDDM |

## Layout

```
.config/            application config, stow-linked into ~/.config
  hypr/
    configs/        shared Hyprland config, sourced in order
    hosts/          per-machine overrides — see below
    scripts/        wallpaper, theming, brightness, volume, OSD helpers
  wallust/          colour-scheme templates that drive every app's palette
Pictures/           wallpapers referenced by the picker and set_wallpaper.sh
system/             package manifests and machine-level config snapshots
```

## Install

```sh
git clone git@github.com:CNTRL-tek91/dotfiles.git ~/.dotfiles

# Packages (see system/README.md — some entries are ASUS ROG specific)
pacman -S --needed - < ~/.dotfiles/system/pkglist-native.txt
paru   -S --needed - < ~/.dotfiles/system/pkglist-aur.txt

# Link it. Pass BOTH -d and -t: stow's default target is the PARENT of the
# stow directory, and it silently does nothing when -d and -t are equal.
stow -d ~/.dotfiles -t ~ --no -v .   # dry run first
stow -d ~/.dotfiles -t ~ .
```

## Per-machine config

Everything is shared between machines except one file. `hyprland.conf` sources
`hosts/host.conf` **last**, so a host can override anything above it and all
variables like `$mainMod` are already defined by then.

`hosts/host.conf` is a gitignored symlink pointing at the committed file for
whichever machine you are on:

```sh
ln -sfn hosts/$(hostname).conf ~/.dotfiles/.config/hypr/hosts/host.conf
```

Monitor layout and hardware-specific keybinds live there — the ASUS `asusctl`
power-profile bind on one machine, `powerprofilesctl` on another.

## Keeping machines in sync

```sh
cd ~/.dotfiles && git add -A && git commit -m "..." && git push   # on one
cd ~/.dotfiles && git pull && stow -d ~/.dotfiles -t ~ --restow . # on the other
hyprctl reload
```

## Notes

- `mimeapps.list` and `user-dirs.dirs` are committed but deliberately **not**
  symlinked — the system rewrites them in place, which would destroy a symlink.
  Copy them by hand on a new machine.
- `apply_wal_theme.sh` uses `sed -i --follow-symlinks`. Plain `sed -i` replaces
  a symlink with a regular file, which silently unmanages whatever it edits.

---

Originally based on [vernette/hyprsnap](https://github.com/vernette/hyprsnap),
since heavily modified. Thanks to the original author.
