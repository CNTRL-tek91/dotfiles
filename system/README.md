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
