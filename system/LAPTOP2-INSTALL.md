# Laptop 2 install notes

Hardware-specific deltas for the second machine. Laptop 1 is AMD + RTX 3070M;
**Laptop 2 is Intel + RTX 2060 Mobile (TU106, Turing)**. The package manifests in
this directory were generated on Laptop 1, so several entries are wrong here.

## Deltas from Laptop 1

| | Laptop 1 | Laptop 2 |
|---|---|---|
| CPU | AMD | Intel → `intel-ucode`, **not** `amd-ucode` |
| dGPU | RTX 3070M (Ampere) | RTX 2060M (TU106/Turing) — `nvidia-open-dkms` still correct |
| iGPU | AMD Cezanne | **NONE USABLE** — i7-8750H's UHD 630 is disabled in firmware; the laptop is MUX'd to discrete. `card1-eDP-1` (the internal panel) hangs off the NVIDIA GPU. |
| Power profile | `asusctl` (ROG only) | `powerprofilesctl` |
| nouveau blacklist | supplied by `supergfxd` | must be written by hand |

## pacstrap

```sh
pacstrap -K /mnt \
  base base-devel linux linux-firmware linux-headers \
  intel-ucode \
  linux-lts linux-lts-headers \
  nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver \
  mesa vulkan-icd-loader \
  grub efibootmgr dosfstools mtools \
  networkmanager wpa_supplicant \
  zsh sudo git vim zram-generator
```

## In the chroot

Use a hostname other than `archlinux` (Laptop 1 uses that); these notes assume
`arch-cntrl`, and the per-host Hyprland file is keyed off it.

```sh
# i915 first so the internal panel comes up early on an Intel hybrid
sed -i 's/^MODULES=.*/MODULES=(nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck)/' /etc/mkinitcpio.conf

cp /path/to/repo/system/nvidia.conf /path/to/repo/system/nvidia-power.conf /etc/modprobe.d/
printf 'blacklist nouveau\nalias nouveau off\n' > /etc/modprobe.d/nouveau-blacklist.conf
cp /path/to/repo/system/zram-generator.conf /etc/systemd/

mkinitcpio -P
```

`nouveau-blacklist.conf` is required here. On Laptop 1 `supergfxd` writes that
blacklist; there is no supergfxd on non-ROG hardware, and nouveau loading beside
the proprietary driver causes intermittent black screens.

## Packages, minus what does not apply

```sh
grep -vxF -e asusctl -e supergfxctl -e rog-control-center -e os-prober \
          -e paru-debug -e amd-ucode \
  system/pkglist-native.txt | sudo pacman -S --needed -

grep -vxF -e asusctl -e supergfxctl -e rog-control-center -e paru -e paru-debug \
  system/pkglist-aur.txt | paru -S --needed -
```

Also install the hand-installed theme dependencies listed in `README.md` in this
directory — they are not in either manifest.

## Linking the config

`stow`'s default target is the PARENT of the stow directory, and it silently does
nothing when `-d` and `-t` are equal. Pass both explicitly:

```sh
stow -d ~/.dotfiles -t ~ --no -v .   # dry run, resolve conflicts first
stow -d ~/.dotfiles -t ~ .
```

Copy `mimeapps.list` and `user-dirs.dirs` by hand — they are committed but
deliberately not symlinked, because the system rewrites them in place.

## Per-host Hyprland file

`hyprland.conf` sources `hosts/host.conf` last. Create this machine's file and
point the gitignored symlink at it:

```sh
cat > ~/.dotfiles/.config/hypr/hosts/arch-cntrl.conf <<'CONF'
monitor = , preferred, auto, 1
xwayland { force_zero_scaling = true }

# NO override needed: this machine is discrete-only, so the LIBVA_DRIVER_NAME=nvidia
# already set in configs/env_vars.conf is correct. Do NOT set iHD here — there is
# no Intel GPU for it to bind to.

# Laptop 1 binds this to `asusctl profile next`, which is ROG-only.
bind = SUPER, F6, exec, powerprofilesctl set balanced
CONF

ln -sfn hosts/arch-cntrl.conf ~/.dotfiles/.config/hypr/hosts/host.conf
```

Run `hyprctl monitors` once Hyprland starts and replace the fallback `monitor`
line with the panel's real name, resolution and refresh rate.

## Services

```sh
sudo systemctl enable bluetooth cups.socket power-profiles-daemon \
     systemd-timesyncd sddm fstrim.timer pkgfile-update.timer \
     nvidia-suspend nvidia-hibernate nvidia-resume
systemctl --user enable pipewire wireplumber xdg-user-dirs
```

Do **not** enable `supergfxd` — it is not installed and does not apply.

## Verify

```sh
nvidia-smi                                     # dGPU visible
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia \
  glxinfo | grep -i renderer                   # names the RTX 2060
glxinfo | grep -i renderer                     # names the Intel iGPU
vainfo                                         # VAAPI via iHD
```

## Corrections found during the real install (2026-08-24)

- **Hostname is `arch-cntrl`**, so the per-host file is `hosts/arch-cntrl.conf`.
- **No Intel iGPU is exposed.** Only the RTX 2060 appears in `lspci` class 03xx,
  `i915` loads but binds to nothing, and the internal panel is `card1-eDP-1` on
  the NVIDIA card. Drop `i915` from `MODULES`; `vulkan-intel` and
  `intel-media-driver` install fine but are inert.
- **`__NV_PRIME_RENDER_OFFLOAD=1`** in `configs/env_vars.conf` is an Optimus
  offload hint and is unnecessary on a discrete-only machine. Harmless, but it
  is not doing anything.
- **GRUB defaults to whichever kernel it finds first**, which was `linux-lts`.
  Set `GRUB_TOP_LEVEL="/boot/vmlinuz-linux"` in `/etc/default/grub` and re-run
  `grub-mkconfig` so mainline is the default and LTS stays the fallback.
- **A `--depth 1` clone cannot be pushed to a new repo.** Unrelated to Laptop 2,
  but the same trap applies to any fresh clone of this repo.
- Laptop 1 boots a Unified Kernel Image; Laptop 2 uses classic
  vmlinuz + initramfs + GRUB. Both work; the ~220 MB initramfs is normal given
  the split `linux-firmware` packages.
