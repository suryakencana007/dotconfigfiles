# resi-shell installer ISO

A bootable Arch Linux ISO that installs resi-shell the way the Omarchy ISO does: `archinstall` lays
out the disk (GPT, 1 GiB EFI on `/boot`, the rest Btrfs with `@`, `@home`, `@log`, `@pkg` subvolumes,
`compress=zstd`, optional LUKS), installs Arch with the resi package list, Limine and zram, creates
the user, then `resi-shell install --chroot` runs inside the new system. Snapper is configured for
`/`. It is an **online** installer: the live system needs internet (Ethernet, or `iwctl` for Wi-Fi).

## Build (on any Arch machine)

```
sudo pacman -S archiso
sudo resi/iso/build.sh            # -> resi/iso/out/resi-shell-<date>-x86_64.iso + SHA256SUMS
```

The build stages the official `releng` profile, appends `packages.extra`, overlays `airootfs/`, and
bakes the repo's **committed HEAD** (`git archive`) into `/usr/share/resi-shell/dotconfigfiles.tar`.
Commit before building. Work dir `resi/iso/work` (~10 GB, gitignored), output `resi/iso/out`.

## Test in a VM

```
sudo pacman -S qemu-desktop edk2-ovmf
resi/iso/test-vm.sh resi/iso/out/resi-shell-*.iso   # boot the ISO into a 40 GB virtual disk
resi/iso/test-vm.sh                                  # boot the installed system afterwards
# the virtual disk lives in ~/.local/state/resi/vm/ (delete it to start from an empty disk)
# SSH into the VM: host port 2222 is forwarded to the VM's port 22
#   in the VM:  sudo systemctl enable --now sshd
#   on the host: ssh -p 2222 <user>@127.0.0.1
```

## What the live installer does

1. `resi-iso-install` starts on tty1 (`/root/.zlogin`). It checks the network, then asks: target
   disk (fzf), hostname, username + password, LUKS yes/no, timezone (fzf), keyboard layout, and an
   optional git name/email for the dotfiles repo.
2. It writes `/root/resi/user_configuration.json` and `user_credentials.json` and runs
   `archinstall --silent`.
3. `resi-iso-postinstall` copies the baked repo to `/home/<user>/dotconfigfiles` (as a git repo
   tracking `origin/main`), sets up snapper, adds a temporary NOPASSWD sudoers drop-in and runs
   `resi-shell install --chroot` as the user, then removes the drop-in and unmounts.
4. On first login Hyprland runs `resi-shell first-login`, which finishes the steps that need a live
   session (GTK theme via gsettings, greeter sync).

Log: `/root/resi-install.log` in the live system. `RESI_ISO_DRY=1 resi-iso-install` only writes the
JSON files, useful to inspect the plan without touching a disk.
