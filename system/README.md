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

## Steam needs `multilib` enabled first

`steam` is in `pkglist-native.txt`, but a fresh Arch install doesn't have the
`multilib` repo enabled (32-bit packages Steam depends on live there) - it's
commented out in `/etc/pacman.conf` by default. Uncomment the `[multilib]`
block and its `Include` line, then `pacman -Syu` before installing, or the
`pacman -S --needed -` restore for `pkglist-native.txt` will fail on `steam`
specifically.

## `linux-wallpaperengine` needs Wallpaper Engine's Steam Workshop content

`scripts/wallpaperengine-rofi.sh` (`Super+Shift+V`, Laptop 2 only) reads
already-downloaded Workshop items directly from
`~/.local/share/Steam/steamapps/workshop/content/431960/` - it does nothing
useful without Wallpaper Engine (Steam App ID 431960) actually owned and
its Workshop items downloaded first. The Wallpaper Engine *Steam app itself*
can't paint a Wayland desktop even under Proton (it only knows how to hook
into Windows' compositor) - `linux-wallpaperengine` is what actually renders
the background, via `wlr-layer-shell`, independent of the Steam app.

Also re-themes the desktop to match, same as picking a static wallpaper
does. A live scene has no single static image the theming pipeline can
read, so `linux-wallpaperengine`'s own `--screenshot` flag (documented by
the project as built "for use with tools like PyWAL") grabs an actual
rendered frame, which `scripts/wallpaperengine_retheme.sh` hands to
`scripts/apply_wal_theme.sh <image>` - the actual live pipeline everything
(kitty, waybar, LibreWolf via pywalfox) reads from (`wal`/pywal, writing
`~/.cache/wal/*`), now accepting an optional image-path override instead of
always using `~/Pictures/wallpaper.png`. `Ctrl+Super+V` (stop) reverts by
calling it again with no override.

`scripts/wallpaper.sh` (matugen + wallust, targeting `.config/*/wallust/*`)
looks like a parallel theming pipeline but isn't wired to anything actually
bound to a key - nothing reads its output. Confirmed by checking what
kitty.conf and waybar/style.css actually `include`/`@import`: both point at
`~/.cache/wal/*`, not the matugen/wallust files. Cost real debugging time
the first time through this feature (looked like it worked - the matugen/
wallust files updated with correct extracted values - until checking the
actually-rendered colors, which hadn't moved at all). If the matugen/
wallust half is meant to replace `wal` rather than sit unused beside it,
that's unfinished migration work, not documented anywhere else.

`--silent` alone doesn't fully mute a wallpaper's audio - PipeWire still
showed an unmuted, 100%-volume stream for the process despite the flag.
`wallpaperengine-rofi.sh` also explicitly mutes the stream via `pactl` once
it appears (short retry loop - it doesn't exist the instant the process
starts).

### Surviving reboot/sleep: which one comes back

`linux-wallpaperengine` is just a process - a reboot, or even just logging
back in, kills it the same as closing any other app, while
`autostart.conf`'s `set_wallpaper.sh` unconditionally re-applies the static
`~/Pictures/wallpaper.png` on every login regardless. Without anything
tracking which kind was actually active, a live wallpaper would silently
revert to static on every reboot even though nothing asked for that.

The launch logic used to live directly in `wallpaperengine-rofi.sh`;
pulled out into `scripts/wallpaperengine_launch.sh` so both the interactive
picker and the login-time restore below call the exact same code, instead
of two copies of the launch flags/mute-retry/retheme-retry drifting apart.
It also writes the chosen Workshop id to `~/.cache/wallpaperengine_state`
- `wallpaperengine_stop.sh` clears that file when the live wallpaper is
turned off. `scripts/wallpaperengine_autostart.sh` (`exec-once` in
`hosts/arch-cntrl.conf`, after `set_wallpaper.sh`) checks that file at
login: present → relaunches the same Workshop item on top of the static
layer underneath; absent (never turned on, or explicitly stopped) → leaves
the static wallpaper alone. Either way the *other* one (static picked
last, or a live wallpaper explicitly stopped) is exactly what should still
be showing after a reboot, and now is.

## Exclude on non-ROG hardware

`asusctl`, `supergfxctl`, `rog-control-center` are ASUS ROG only.
`os-prober` only mattered for the Windows dual-boot on this machine.
`supergfxd` also supplies the nouveau blacklist — replace it manually elsewhere.

`nvidia-open-dkms` requires Turing (RTX 20 / GTX 16) or newer. Use `nvidia-dkms`
on Pascal and older.

## `ckb-next` can't control Laptop 2's keyboard RGB - `openrgb` does

Laptop 2's built-in keyboard enumerates over USB as `048d:c935 Corsair
Gaming K95 RGB PLATINUM Keyboard` (`lsusb`) - vendor `048d` is **ITE**, not
Corsair's real vendor ID (`1b1c`). It's the laptop's own keyboard, built on
an ITE controller, carrying Corsair naming/branding from a Lenovo-Corsair
collaboration on this model - not an external Corsair desktop keyboard.
`ckb-next` only recognizes genuine Corsair-vendor-ID hardware, so it always
reports "no devices connected" here regardless of the daemon running -
that's expected, not fixable by config. `openrgb` recognizes it directly
and by name ("Lenovo Legion Y740"), with a full per-key RGB map including
the Legion logo, power button, vents, and USB ports. The waybar RGB icon
launches `openrgb` for this reason. Keep `ckb-next` installed in case a
real Corsair peripheral gets plugged in later; `ckb-next-daemon` is
`systemctl disable --now`'d since it currently serves no purpose here.

### `openrgb-git`, not the `extra` repo's `openrgb`

The keyboard's own driver only exposes "Direct" mode (static per-LED
colors) - the rainbow-wave/breathing/spectrum-cycle effects come from the
separate **OpenRGB Effects Plugin** (`openrgb-plugin-effects-git`, AUR),
which depends on `qt6-tools`. Arch's official `extra` repo ships `openrgb`
built against **Qt5** (confirmed via `ldd`) - a Qt6 plugin won't load
against a Qt5 host, Qt plugins can't cross major versions. Swapped to
`openrgb-git` (AUR), which is Qt6 and declares `Conflicts: openrgb` /
`Provides: openrgb`, so `paru -S openrgb-git openrgb-plugin-effects-git`
removes the `extra` package cleanly in the same transaction - not a
plugin-only install. Verified the plugin actually loaded via
`~/.config/OpenRGB/logs/` ("58 effects registered"), not just that the
package installed.

### Keeping an effect applied across closing the window, sleep, and reboot

This controller has no onboard memory - OpenRGB's own UI shows "Saving Not
Supported" for it - so any custom color or Effects Plugin animation (Rain,
rainbow-wave, etc.) only exists while OpenRGB is actively streaming it live;
the instant the process stops driving it, the keyboard falls back to its own
firmware-default rainbow cycle. Three separate moments can cause that:

- **Closing the OpenRGB window.** Fixed by `minimize_on_close: true` in
  `~/.config/OpenRGB/OpenRGB.json` (was `false` - closing the window used to
  fully quit the app, not minimize it to tray) plus `exec-once = ...
  openrgb_autostart.sh` in `hosts/arch-cntrl.conf`, which keeps it running
  from login onward.
- **Suspend/resume.** `hypridle.conf`'s `after_sleep_cmd` re-pushes the saved
  profile once the laptop wakes, since some USB rails power-cycle across
  suspend even though the rest of the laptop resumes fine.
- **A real reboot/shutdown.** Kills the OpenRGB process outright, which loses
  power to the controller too. `openrgb_autostart.sh` starts OpenRGB back up
  with `--profile last-state`, so whatever was saved comes right back instead
  of sitting on firmware-default rainbow after boot.

All three reload the same profile, named `last-state`, and none of them
*capture* it automatically - only load it. That's deliberate, not a
shortcut: `openrgb --save-profile` run from a separate CLI invocation
re-detects the hardware from scratch rather than reading the already-running
GUI process's in-memory state, and this controller can't be read back from
(same root cause as "Saving Not Supported"), so a fresh detection gets back
all-zero colors - confirmed by testing, not assumed. Saving "last-state" from
*inside* the already-running OpenRGB GUI (File > Save Profile As >
"last-state") avoids that, because it serializes the same process's live
RGBController state instead of re-detecting. Re-save it (same menu, same
name) any time you want a newly-picked effect to become the one that
survives sleep/reboot - it won't happen on its own.

## `auto-cpufreq` masks `power-profiles-daemon`

Installed and running as a systemd daemon on Laptop 2 (`sudo auto-cpufreq
--install`), trying an alternative to the Lenovo WMI power-profile path after
that turned out to change nothing measurable (see `SETUP.md`'s M1/M2 trap
entry). `--install` auto-detects and masks `power-profiles-daemon`, which
means `Ctrl+Super+P` and `Super+F6` (both call `powerprofilesctl`) currently
do nothing on Laptop 2 - not broken, just superseded while this is running.

To revert to `power-profiles-daemon` and get those binds working again:

```sh
sudo auto-cpufreq --remove
sudo systemctl unmask power-profiles-daemon.service
sudo systemctl enable --now power-profiles-daemon.service
```

Don't install `auto-cpufreq`'s daemon on Laptop 1 without checking first - it
would mask `power-profiles-daemon` there too, which Laptop 1's own `Super+F6`
(`asusctl profile next`) doesn't depend on, but worth confirming nothing else
on that machine reads `power-profiles-daemon` before enabling it.

`Super+F6` and `Ctrl+Super+P` now drive `auto-cpufreq --force` instead (via
`scripts/cpufreq_cycle.sh` / `scripts/cpufreq_picker.sh`, state tracked in
`~/.cache/auto-cpufreq-mode`), cycling Silent/Balanced/Performance the same
way the old `powerprofilesctl` binds did. Unlike `powerprofilesctl`,
`auto-cpufreq --force` has no unprivileged/polkit path - it hard-requires
root. That needs a one-time, machine-local sudoers rule (**not** in this
repo, since sudoers files must be root-owned and 0440 - `stow` can't manage
it) scoped to exactly the three commands these scripts call:

```sh
cat <<'EOF' > /tmp/auto-cpufreq-force-sudoers
cntrl ALL=(root) NOPASSWD: /usr/bin/auto-cpufreq --force powersave, /usr/bin/auto-cpufreq --force performance, /usr/bin/auto-cpufreq --force reset
EOF
sudo visudo -cf /tmp/auto-cpufreq-force-sudoers && \
sudo install -m 0440 /tmp/auto-cpufreq-force-sudoers /etc/sudoers.d/auto-cpufreq-force
rm /tmp/auto-cpufreq-force-sudoers
```

Validate with `visudo -cf` on a temp file before it ever touches
`/etc/sudoers.d/` - a bad sudoers file can lock out `sudo` entirely.

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
| Pywalfox browser extension (native host is packaged; the LibreWolf-side add-on is not) | Install the signed build from `addons.mozilla.org/firefox/addon/pywalfox/` via `about:addons` → gear → Install Add-on From File |

On Laptop 1 these live in `~/.themes` (5.6 MB) and `~/.icons` (664 MB). They are
deliberately **not** committed — the packages above provide the same files.

Confirmed missing on first boot of Laptop 2: both the cursor symlink and the
Pywalfox extension. `python-pywalfox` (native host) installs from the package
list and registers its native-messaging manifest fine, but that's only half
the pipe — without the browser extension, `apply_wal_theme.sh`'s `pywalfox
update` call runs and exits 0 with nothing listening on the other end, so
LibreWolf silently never gets themed. No error, so this is easy to miss.

### LibreWolf's Google search engine needs a policy, not just a pref

`.librewolf/librewolf.overrides.cfg` sets `defaultPref("browser.search.
defaultenginename", "Google")`, with a comment saying "Also edit your
policies.json" - but that policy addition was never actually made, on either
machine. The pref alone does nothing if "Google" isn't a search engine
LibreWolf actually knows about (it ships with DuckDuckGo and friends, not
Google, by design). Fixed by adding a real `SearchEngines` entry to
`/usr/lib/librewolf/distribution/policies.json` (name, URL template, icon,
suggestions URL, plus `"Default": "Google"`) - same root-owned,
package-managed file the `ExtensionSettings`/`FirefoxHome` policies already
live in, so it doesn't survive a `librewolf` package update and needs
reapplying after one. Takes effect on LibreWolf's next launch (policies only
load at startup, like the override file).

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
sets a theme that does not exist and silently no-ops there. Worth resolving to
one or the other.

On Laptop 2, `adw-gtk-theme` **is** installed (it's in `system/README.md`'s
own hand-install table above), so the same gsettings call actually succeeds —
`adw-gtk3-dark` wins and overrides the `settings.ini` value for real. Same
inconsistency, but it now has a visible effect instead of silently failing.

## Why `pacman -Qqe` is not a complete manifest

Three defects surfaced while building Laptop 2 from these lists. All three
share a root cause: `pacman -Qqe` records what was *explicitly requested*, not
what the configs actually need.

| Package | Problem | Fix |
|---|---|---|
| `starship` | Prompt is invoked by `.zshrc` on every shell, but it arrived on Laptop 1 as a **dependency**, so it never appeared in `-Qqe` | added to `pkglist-native.txt` |
| `hyprpicker` | Bound in the Hyprland config; also dependency-only on Laptop 1 | added to `pkglist-native.txt` |
| `librewolf-bin` | **Removed from the AUR** — LibreWolf now ships in the official `extra` repo. One dead target aborts the whole `paru` transaction, so nothing installs | dropped from `pkglist-aur.txt`; `librewolf` added to `pkglist-native.txt` |
| `paru-debug` | **Removed from the AUR** sometime after Laptop 2 was set up (it had already installed fine by then, so no local symptom — but a fresh `paru -S --needed - < pkglist-aur.txt` on a future machine would abort on it) | dropped from `pkglist-aur.txt` |

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

### Syncthing device pairing (already configured)

| Machine | Device ID |
|---|---|
| `archlinux` (Laptop 1) | `M7CEQTS-33JFF5S-OVZERHX-GGUFZ67-TBEQTF5-WWSIPD3-MEMAG6N-TGTOSQZ` |
| `arch-cntrl` (Laptop 2) | `EQQYIYF-LWNS4BK-ZXDUVOO-JU5UHSY-UCAYBMP-F5QVAKI-TO6XHBI-K554QQ2` |

Shared folders, all `sendreceive` with filesystem watching:
`~/Projects`, `~/Documents`, `~/Desktop`, `~/Pictures`.

`~/Pictures/.stignore` excludes `wallpapers` and `wallpaper.png` — the first is
a symlink into this repo, so git owns it, and letting Syncthing manage the same
files would have the two tools fighting.

Web UI on either machine: <http://127.0.0.1:8384>

Adding a third machine: install `syncthing`, `systemctl --user enable --now
syncthing`, then add its device ID on an existing machine and share the folders
to it.

**Limits worth remembering.** Both machines must be powered on at the same time —
it is peer-to-peer, nothing holds the data in between. It syncs, it does not
merge: editing one file on both while disconnected leaves a `*.sync-conflict-*`
copy alongside the original. Never add `~/.config`, `~/.cache`, browser profiles
or anything with a live SQLite database.
