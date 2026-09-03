# Setup inventory

A complete description of this Hyprland desktop, written so an agent or a person
on a new machine can read it, diff it against what is installed, and fill the
gaps. **Read this before installing anything.**

Package manifests live in `system/`. This file explains what the packages are
*for*, how the pieces fit together, and which parts are known to be broken.

---

## 1. Machines

| | Laptop 1 (`archlinux`) | Laptop 2 (`arch-cntrl`) |
|---|---|---|
| CPU | AMD Ryzen 9 5900HS | Intel Core i7-8750H |
| Microcode | `amd-ucode` | `intel-ucode` |
| dGPU | RTX 3070 Mobile (GA104, Ampere) | RTX 2060 Mobile (TU106, Turing) |
| iGPU | AMD Cezanne, active (hybrid) | **none exposed** — UHD 630 disabled in firmware, MUX'd discrete |
| Panel | `eDP-1` 2560x1440@165 | `eDP-1` 1920x1080@144, wired to the NVIDIA GPU |
| Driver | `nvidia-open-dkms` (Turing+) | `nvidia-open-dkms` |
| Boot | GRUB + **Unified Kernel Image** | GRUB + vmlinuz/initramfs |
| Kernel | `linux` | `linux` default, `linux-lts` fallback |
| Chassis | ASUS ROG — `asusctl`, `supergfxctl`, `rog-control-center` | not ROG; none of those |
| Swap | zram 4G zstd | zram 4G zstd |
| Root | ext4 | ext4 |

**Consequences of the iGPU difference.** Laptop 2 is discrete-only, so:
`LIBVA_DRIVER_NAME=nvidia` in `configs/env_vars.conf` is correct — do **not** set
`iHD`; `i915` must not be in `MODULES`; `vulkan-intel` and `intel-media-driver`
install but are inert; and `__NV_PRIME_RENDER_OFFLOAD=1` is a no-op.

**nouveau blacklist.** Laptop 1 gets this free from `supergfxd`. On non-ROG
hardware you must write `/etc/modprobe.d/nouveau-blacklist.conf` yourself, or
nouveau loads beside the proprietary driver and causes intermittent black screens.

---

## 2. Desktop stack

| Role | Package | Config |
|---|---|---|
| Compositor | `hyprland` | `.config/hypr/` |
| Idle / lock | `hypridle`, `hyprlock` | `hypridle.conf`, `hyprlock.conf` |
| Polkit agent | `hyprpolkitagent` | started from `autostart.conf` |
| Bar | `waybar` | `config.jsonc`, `modules.jsonc`, `style.css` |
| Launcher | `rofi` (+ `tofi`, `fuzzel`) | 22 `.rasi` themes |
| Notifications | `swaync` (+ `dunst` for OSD) | `swaync/`, `dunst/` |
| Volume/brightness OSD | `swayosd` | `swayosd/` |
| Wallpaper daemon | `awww` | driven by `set_wallpaper.sh` |
| Terminal | `kitty` (+ `ghostty`, `wezterm` configured) | `kitty/` |
| Editor | `neovim` + LazyVim | `nvim/`; previous custom config at `nvim-custom/`, run with `vc` |
| Shell | `zsh` + zinit + `starship` + `zoxide` + `fzf` | `.zshrc` |
| File manager | `thunar` | `Thunar/`, `xfce4/` |
| Clipboard | `cliphist` + `wl-clipboard` | `Super+V` |
| Screenshots | `grimblast`, `hyprshot`, `grim`, `slurp`, `swappy` | `custom_scripts/screenshot` |
| Colour picker | `hyprpicker` | `Super+Shift+P` |
| Login | `sddm` + `simple_sddm_2` theme | `/etc/sddm.conf.d/theme.conf` |
| Qt theming | `kvantum`, `qt5ct`, `qt6ct` | |
| GTK theming | `adw-gtk-theme`, `flat-remix-gtk`, `nwg-look` | `gtk-3.0/`, `gtk-4.0/` |
| Icons / cursor | `flat-remix`, `bibata-cursor-theme-bin` | `~/.icons/default` |
| Browsers | `librewolf` (primary), `firefox`, `brave-bin` | `.librewolf/` incl. custom startpage |
| Audio | `pipewire`, `pipewire-pulse`, `wireplumber` | user units |
| Shell UI (installed, not autostarted) | `caelestia-shell`, `quickshell-git` | `caelestia/`, `quickshell/` |

---

## 3. Theming pipeline

The desktop recolours itself from the wallpaper. **Four** tools split the work —
this is the least obvious part of the setup:

1. **`wal` (python-pywal16)** — writes `~/.cache/wal/*`, ~60 files consumed by
   many apps. **Not in the repo**: `~/.cache/` is machine-local, so on a new
   machine every wal-dependent config is broken until the theme script runs once.
2. **`wallust` (pinned 3.5.2)** — terminal palette, so code stays readable.
   Targets `kitty/wallust-colors.conf` and `nvim-custom/lua/wallust_base16.lua`.
   Both are **gitignored generated output**. Note the nvim target is **dead** —
   nothing has ever read `wallust_base16.lua`; Neovim is themed by lushwal
   reading `~/.cache/wal` directly, in both the LazyVim and nvim-custom configs.
3. **`lushwal`** — the Neovim end of the pipeline. Builds a colorscheme from
   pywal's cache at startup, so the editor tracks the wallpaper like everything
   else. It compiles into `nvim/colors/`, which is gitignored for the same
   reason as the files above.
4. **`matugen`** — Material You colours for the UI: waybar, hypr, tofi, dunst.

### Accent extraction — why the palette isn't six shades of one colour

pywal crowds all six accent slots into one narrow band. Measured across the 12
wallpapers here, the **closest pair of accent colours was as little as 1.3 Lab
units apart** — the same colour to the eye. On a red wallpaper it returns six
greys. Nothing distinguishes a string from a keyword from an error.

`hypr/scripts/extract_accents.py` runs inside `apply_wal_theme.sh`, between
pywal's extraction and the kitty readability pass. It hands extraction to
**wallust** — already installed, already used here for kitty — whose Lab
colourspace picks perceptually separated colours out of the same image, with
`--check-contrast` keeping them legible. The result is fed back through
`wal --theme`, which regenerates all ~60 template files, so **every consumer
picks it up with no change of its own**.

Measured against pywal on all 12 wallpapers, wallust won on every one: mean
pairwise Lab distance ~2–3× better, closest-pair distance 3–5× better.

Only slots 1–6 and 9–14 are replaced. Background, foreground and the greys stay
pywal's — they set the desktop's mood and already look right.

**Don't "fix" this by synthesising hues.** An earlier version rebuilt the slots
at canonical ANSI hues (red/green/yellow/blue/magenta/cyan) tinted toward the
wallpaper. It scored beautifully on *hue spread* and was flatly wrong: a
wallpaper containing only reds got green and magenta in its theme. Hue spread is
the wrong metric — wallpapers legitimately have one hue. Sampling the red
wallpaper, all 16 of its dominant colours sit between 340° and 356°; the variety
that matters is in **lightness and saturation** (bright red, deep maroon, pale
pink, near-black), which is exactly what a perceptual colourspace finds and what
pywal misses. Judge any change here on pairwise Lab distance and contrast ratio,
not hue.

Tuning lives at the top of the script: `COLORSPACE` (`lab` measured widest —
`labmixed` scored well on the mean but left a pair 2.8 apart), `PALETTE_DARK`
(`harddark16` orders brightest-first, which suits ANSI slots) and `MIN_CONTRAST`
(3.0; lifts lightness only, never hue or saturation). `--preview` prints the
before/after palette with both metrics and writes nothing:

```sh
~/.config/hypr/scripts/extract_accents.py ~/Pictures/wallpaper.png --preview
```

Entry points: `hypr/scripts/wallpaper.sh` (apply + retheme),
`apply_wal_theme.sh` (retheme current), `random_wallpaper.sh` (`Super+W`),
`custom_scripts/wallpaper_select.sh` (`Super+Shift+W`). All of them funnel
through `apply_wal_theme.sh`, so the harmonisation applies to every path —
static wallpapers, random, theme toggle, and live wallpapers via
`wallpaperengine_retheme.sh`.

`apply_wal_theme.sh` also live-reloads kitty (SIGUSR1), nudges waybar, pushes
colours to LibreWolf via `pywalfox`, reloads any running Neovim, and syncs the
SDDM login background.

### Neovim's live reload is pushed, not watched

`reload_nvim_theme.sh` walks the nvim server sockets at
`$XDG_RUNTIME_DIR/nvim.<pid>.<n>` — nvim opens one automatically, so every
running instance is reachable with no per-instance setup — and runs
`nvim_wal_reload.lua` in each via `--remote-expr`.

lushwal ships its own fs_event watcher for this and it is **not** dependable
here: this pipeline rewrites `~/.cache/wal/colors.json` twice per change, a
single-file watch does not survive its target being replaced, and the watcher
only re-arms from the exit callback of a subprocess it spawns. Any one of those
failing leaves an open editor stuck on stale colours for the rest of its
session, with nothing to indicate why. Don't remove the push on the grounds that
lushwal "already does this".

`--remote-expr`, never `--remote-send` — the latter injects keystrokes, which
corrupts whatever is being typed and misfires outside normal mode. The reload is
a standalone `.lua` file rather than a command defined in the config so it works
under both the LazyVim and `nvim-custom` configs, and it no-ops unless lushwal is
the active colorscheme, so a theme picked deliberately with `<leader>uC` survives
a wallpaper change.

**The module-cache clear is load-bearing.** lushwal's addons — the per-plugin
highlight generators for lualine, bufferline, gitsigns — open with
`local colors = require("lushwal").colors` at module scope. Lua evaluates that
once and caches it in `package.loaded`, so without clearing
`lushwal.colors` and `lushwal.addons.*` the reload rebuilds those plugins from
the palette they saw at editor startup, **forever**. The symptom is a theme
split in half: syntax highlighting tracks the wallpaper while the statusline
stays frozen — which looks like the reload doing nothing, since the statusline
is the most colourful thing on screen. lualine also caches its resolved theme
and rebuilds from its own `ColorScheme` autocmd, which has already fired by the
time the modules are fresh, so it needs one explicit re-`setup()` after.

Debugging: `~/.cache/nvim-theme-reload.log` records each run — sockets found and
whether each accepted the reload. This runs with stderr discarded from a
backgrounded subshell, so the log is the only visibility there is.

### On a fresh machine, run this once or the desktop looks broken

```sh
~/.config/hypr/scripts/set_wallpaper.sh   # or Super+W
```

Until then `~/.cache/wal/` is empty and **waybar will not start at all**.

---

## 4. Keybindings

74 binds in `hypr/configs/binds.conf`. `$mainMod` is SUPER.

| Key | Action |
|---|---|
| `Super+Return` / `D` / `F` / `B` / `L` | terminal / launcher / files / browser / lock |
| `Super+Shift+Q` / `Shift+E` / `Shift+R` | close window / exit Hyprland / reload config |
| `Super+1..0`, `Super+Shift+1..0` | switch / move to workspace |
| `Super+arrows`, `Super+Shift+arrows` | focus / move window |
| `Ctrl+Super+arrows` | resize |
| `Super+Shift+F` / `Shift+Space` / `Shift+C` | fullscreen / float / centre |
| `Super+M` / `Super+Shift+M` | minimise to special workspace / restore |
| `Super+V` | clipboard history |
| `Super+W` / `Super+Shift+W` | random wallpaper / wallpaper picker |
| **`Super+Shift+V`** (Laptop 2 only) | Live wallpaper picker (`linux-wallpaperengine`), also re-themes the desktop to match it - see `system/README.md` |
| **`Ctrl+Super+V`** (Laptop 2 only) | Stops the live wallpaper and reverts the theme back to the static wallpaper's colors |
| `Super+Shift+L` / `Shift+N` / `Shift+P` | logout menu / notifications / colour picker |
| `Super+F1` | game mode |
| `Super+X`, then `Super+Escape` | passthrough submap (send keys to a VM/app) |
| `Print`, `Ctrl+Print`, `Ctrl+Shift+Print` | screenshot full / region / window |
| Media & brightness keys | `playerctl`, `swayosd-client`, `changebrightness` |
| Lid close | `systemctl suspend` |
| **`Super+F6`** | **per-host**: `asusctl` on Laptop 1, `auto-cpufreq --force` cycle on Laptop 2 (was `powerprofilesctl` — see `system/README.md`) |
| **`Ctrl+Super+P`** (Laptop 2 only) | Same 3-way power-profile cycle as `Super+F6`, on a second key. Not plain `Super+P` — that's already `pseudo` (dwindle pseudotile) in the shared `binds.conf`. Added because Laptop 2's M1/M2 keys don't work — see the trap entry below. Also pickable via a waybar icon (rofi dropdown) in the notifications/weather drawer. |

Also: 43 window rules, 14 layer rules, 13 env vars.

---

## 5. Per-host configuration

`hyprland.conf` sources `hosts/host.conf` **last**, so a host can override
anything and `$mainMod` is already defined. `host.conf` is a **gitignored
symlink** to the committed file for that machine — so it does not exist after a
fresh clone and **Hyprland will fail to start until you create it**:

```sh
ln -sfn hosts/$(hostname).conf ~/.dotfiles/.config/hypr/hosts/host.conf
```

Committed hosts: `archlinux.conf` (Laptop 1), `arch-cntrl.conf` (Laptop 2).

---

## 6. Services

**System:** `NetworkManager`, `sshd`, `bluetooth`, `cups.{service,socket,path}`,
`power-profiles-daemon`, `systemd-timesyncd`, `sddm`, `fstrim.timer`,
`pkgfile-update.timer`, `nvidia-{suspend,hibernate,resume}`.

**User:** `pipewire`, `pipewire-pulse`, `wireplumber`, `xdg-user-dirs`.

`nvidia-*` pair with `NVreg_PreserveVideoMemoryAllocations=1` in
`/etc/modprobe.d/nvidia-power.conf` — without both, windows are corrupted on wake.

**Laptop 1 only:** `supergfxd`. Do not enable it elsewhere.

---

## 7. Installing on a new machine

```sh
git clone git@github.com:CNTRL-tek91/dotfiles.git ~/.dotfiles

# Register the wal-reload clean filter. .gitattributes asks for it, but the
# filter body lives in .git/config, which is NOT cloned - without this, every
# wallpaper change leaves waybar's style.css showing as modified forever.
git -C ~/.dotfiles config filter.wal-marker.clean "sed '/^\/\* wal-reload /d'"

# Packages — see system/README.md for what to exclude on non-ROG hardware
pacman -S --needed - < ~/.dotfiles/system/pkglist-native.txt
paru   -S --needed - < ~/.dotfiles/system/pkglist-aur.txt

# Link. Pass BOTH -d and -t: stow's default target is the PARENT of the stow
# dir, and it silently does nothing when -d and -t are equal.
mkdir -p ~/.config ~/Pictures            # stop stow folding whole dirs
stow -d ~/.dotfiles -t ~ --no -v .       # dry run
stow -d ~/.dotfiles -t ~ .

ln -sfn hosts/$(hostname).conf ~/.dotfiles/.config/hypr/hosts/host.conf
cp ~/.dotfiles/.config/{mimeapps.list,user-dirs.dirs} ~/.config/
~/.config/hypr/scripts/set_wallpaper.sh  # populate ~/.cache/wal
```

Then the SDDM theme (not packaged):

```sh
sudo git clone https://github.com/JaKooLit/simple-sddm-2.git \
  /usr/share/sddm/themes/simple_sddm_2
sudo chown -R "$USER" /usr/share/sddm/themes/simple_sddm_2/Backgrounds
printf '[Theme]\nCurrent=simple_sddm_2\n' | sudo tee /etc/sddm.conf.d/theme.conf
```

---

## 8. Known bugs and traps

Verified on real hardware. **Read before debugging anything.**

| Problem | Detail |
|---|---|
| **`pacman -Qqe` is not a complete manifest** | It records explicit installs only. It missed `starship` and `hyprpicker` (dependency-only) and every hand-installed theme. Always cross-check what the configs actually invoke. |
| **Relative `@import` in GTK CSS breaks under stow** | `../../.cache/wal/...` resolves against the stylesheet's *real* path. When a whole config dir is symlinked into the repo it becomes `~/.dotfiles/.cache/` and **waybar refuses to start**. Fixed by using absolute paths in waybar/swaync/wlogout `style.css`. |
| **`sed -i` destroys symlinks** | It writes a temp file and renames over the target. `apply_wal_theme.sh` uses `--follow-symlinks` for this reason. This is how Laptop 1's `waybar/style.css` silently stopped being repo-managed and lost its taskbar block. |
| **Do not install `wallust-git`** | It tracks 4.0.0-alpha, which removed `backend = "kmeans"` and rejects this repo's `wallust.toml`. Pin 3.5.2. |
| **Codeberg breaks git clones** | It resets HTTP/2 streams (`curl 92 ... 0x8 CANCEL`). Fix: `git config --global http.version HTTP/1.1`. It also re-packs release tarballs, so AUR sha256 checksums for `wallust` go stale. |
| **`librewolf-bin` was removed from the AUR** | LibreWolf is in `extra` now. One dead AUR target aborts the entire `paru` transaction, so *nothing* installs. |
| **Shallow clones cannot be pushed to a new repo** | `remote unpack failed / did not receive expected object`. Run `git fetch --unshallow` first. |
| **`ssh -T git@github.com` always exits 1** | Even on success. Never chain it with `&&` before a push. |
| `$file_manager = nautilus` | **`nautilus` is not installed on either machine**, so `Super+F` does nothing. `thunar` is what is actually installed. |
| GTK theme conflict | `gtk-3.0/settings.ini` says `Flat-Remix-GTK-Blue-Dark`; `autostart.conf` runs `gsettings set gtk-theme 'adw-gtk3-dark'`. Two mechanisms, two values. |
| Dead references | `spicetify`, `swww`, `docker`, `wg-quick`, `awg-quick`, `traceroute`, `rustmon`, `yandex-disk` are invoked by configs or aliases but installed on neither machine. |
| Not symlinked on purpose | `mimeapps.list`, `user-dirs.dirs` — the system rewrites them in place, which would destroy a symlink. Copy them by hand. |
| **Laptop 2's M1/M2 keys are dead on Linux, and always will be on this generation** | The two macro keys on the left edge of the Y740 (81HE/80UF009HV) keyboard produce zero signal through any Linux-visible channel — confirmed no evdev event (`evtest` on the "Ideapad extra buttons" device, `/dev/input/event9`), no udev/kernel uevent on the wmi/acpi/platform/input subsystems, no change to `/sys/firmware/acpi/platform_profile`, and nothing in `dmesg -w` on keypress, despite `lenovo_wmi_gamezone`/`lenovo_wmi_events`/`ideapad_laptop` all being loaded. Root cause: Lenovo's own manual for this model routes M1/M2 through a Windows-only "Magic Y Key" app rather than the standard hotkey/BIOS layer, and the community driver that reverse-engineers this class of Legion WMI hotkey (`johnfanv2/LenovoLegionLinux`) has an open, unresolved issue for this exact model — its probe fails on this generation's hardware. Not fixable with a keybind; worked around by putting the desired behavior (power-profile cycling) on `Ctrl+Super+P` instead. Since then, `auto-cpufreq` has replaced `power-profiles-daemon` (which it masks - see `system/README.md`) as the actual backend for both `Ctrl+Super+P` and `Super+F6`, via `scripts/cpufreq_cycle.sh`/`scripts/cpufreq_picker.sh` and a NOPASSWD sudoers rule scoped to `auto-cpufreq --force`. |
| **LibreWolf's `AboutNewTab.newTabURL` override stopped working** | `.librewolf/librewolf.overrides.cfg`'s `ChromeUtils.importESModule(...).newTabURL = "..."` trick (used to redirect `about:newtab` to the custom startpage) silently no-ops on newer LibreWolf/Firefox builds — no console error, it just doesn't redirect. Root cause: Mozilla's [newtab-as-built-in-addon rearchitecture](https://bugzilla.mozilla.org/show_bug.cgi?id=1949511) replaced the native `about:newtab` protocol handler (`AboutNewTabRedirectorParent.newChannel()`) with one that never reads `AboutNewTab.newTabURLOverridden` at all — confirmed by decompiling `browser/omni.ja` on Laptop 2 (LibreWolf `154.0-2`, installed fresh so it grabbed whatever was current in `extra`; Laptop 1's install predates the rearchitecture, so the old trick still works there). Arch is rolling-release, so this is a function of *when a machine last updated*, not which laptop it is — check with `librewolf --version`. Fix: install a small local WebExtension using the still-supported `chrome_url_overrides.newtab` manifest key instead. Requires `pref("xpinstall.signatures.required", false)` in `librewolf.overrides.cfg` if the extension is unsigned (an official signed extension like Pywalfox doesn't need this). The homepage pref (`browser.startup.homepage`) is unaffected — it's a different, still-working mechanism. |
| **LibreWolf startpage wasn't responsive to short windows** | `.librewolf/startpage/src/css/style.css` centered content with a fixed `html { height: 100svh }` and no vertical overflow handling. On a short/tiled window (e.g. a quarter-tile), the vertically-centered content taller than the viewport pushed the search bar (the topmost element) above the visible area with no scrollbar to reach it - looked like the search bar had vanished rather than been pushed off-screen. Fixed with `min-height` + `overflow-y: auto` as a fallback, plus `max-height` media queries that shrink spacing so it fits without scrolling in the common case. |
| **`scripts/wallpaper.sh` (matugen + wallust) is dead code** | Not called by anything actually bound to a key. `kitty.conf` and `waybar/style.css` both read from `~/.cache/wal/*` (`wal`/pywal, via `scripts/apply_wal_theme.sh` - the real pipeline, bound through `custom_scripts/wallpaper_select.sh` on `Super+Shift+W`), not from the matugen/wallust files `wallpaper.sh` writes to (`.config/*/wallust/*`). Easy to miss: those files DO update correctly when `wallpaper.sh` runs, they're just never read by anything - looks like it's working until you check the actually-rendered colors. See `system/README.md` for how this surfaced (building live-wallpaper re-theming on top of it first, silently). |
| **`.librewolf/` gaps that don't error, just silently don't apply** | Two more from the same "no error, just doesn't work" family, found auditing Laptop 2: (1) `~/.icons/default` doesn't exist until `nwg-look` (or a manual symlink to `Bibata-Modern-Ice`) is run once — see `system/README.md`; (2) the Pywalfox **browser extension** (`pywalfox@frewacom.org`, from `addons.mozilla.org`) is a separate manual install from the `python-pywalfox` **native host** package — the native host installs and registers fine from the package lists, so `apply_wal_theme.sh`'s `pywalfox update` call exits 0 with nothing on the other end, and LibreWolf just never gets themed. |

---

## 9. Verification checklist

```sh
hyprctl configerrors                  # must be empty
hyprctl monitors                      # real name/mode for hosts/<host>.conf
nvidia-smi                            # dGPU visible
systemctl --failed                    # zero
pgrep -x waybar && pgrep -x swaync    # bar + notifications up
awww query                            # a wallpaper is actually displayed
ls ~/.cache/wal/colors-waybar.css     # theming cache populated
find ~/.config -xtype l               # no dangling symlinks
```
