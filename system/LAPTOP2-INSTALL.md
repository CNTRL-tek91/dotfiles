# Laptop 2 install notes

Hardware-specific deltas for the second machine. Laptop 1 is AMD + RTX 3070M;
**Laptop 2 is Intel + RTX 2060 Mobile (TU106, Turing)**. The package manifests in
this directory were generated on Laptop 1, so several entries are wrong here.

## Deltas from Laptop 1

| | Laptop 1 | Laptop 2 |
|---|---|---|
| CPU | AMD | Intel → `intel-ucode`, **not** `amd-ucode` |
| dGPU | RTX 3070M (Ampere) | RTX 2060M (TU106/Turing) — `nvidia-open-dkms` still correct |
| iGPU | AMD Cezanne | Intel → needs `vulkan-intel`, `intel-media-driver` |
| Power profile | `asusctl` (ROG only) | `powerprofilesctl` |
| nouveau blacklist | supplied by `supergfxd` | must be written by hand |

## pacstrap

```sh
pacstrap -K /mnt \
  base base-devel linux linux-firmware linux-headers \
  intel-ucode \
  linux-lts linux-lts-headers \
  nvidia-open-dkms nvidia-utils nvidia-settings libva-nvidia-driver \
  mesa vulkan-intel intel-media-driver vulkan-icd-loader \
  grub efibootmgr dosfstools mtools \
  networkmanager wpa_supplicant \
  zsh sudo git vim zram-generator
```

## In the chroot

Use a hostname other than `archlinux` (Laptop 1 uses that); these notes assume
`arch-laptop2`, and the per-host Hyprland file is keyed off it.

```sh
# i915 first so the internal panel comes up early on an Intel hybrid
sed -i 's/^MODULES=.*/MODULES=(i915 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
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
cat > ~/.dotfiles/.config/hypr/hosts/arch-laptop2.conf <<'CONF'
monitor = , preferred, auto, 1
xwayland { force_zero_scaling = true }

# Intel iGPU drives the panel, so VAAPI should use it rather than the dGPU.
# Overrides the LIBVA_DRIVER_NAME=nvidia set in configs/env_vars.conf.
env = LIBVA_DRIVER_NAME, iHD

# Laptop 1 binds this to `asusctl profile next`, which is ROG-only.
bind = SUPER, F6, exec, powerprofilesctl set balanced
CONF

ln -sfn hosts/arch-laptop2.conf ~/.dotfiles/.config/hypr/hosts/host.conf
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
