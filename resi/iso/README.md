# resi-shell installer ISO

A bootable Arch Linux ISO that installs resi-shell the way the Omarchy ISO does: `archinstall` lays
out the disk (GPT, 1 GiB EFI on `/boot`, the rest Btrfs with `@`, `@home`, `@log`, `@pkg` subvolumes,
`compress=zstd`, optional LUKS), installs Arch with the resi package list, Limine and zram, creates
the user, then `resi-shell install --chroot` runs inside the new system. Snapper is configured for
`/`. The ISO carries an **offline mirror** (the full package closure, the AUR packages pre-built,
and the git clones the installer needs), so a fresh machine installs in a few minutes without
internet, like the Omarchy ISO. With internet the mirror is still used first and Arch mirrors only
fill in anything missing. Only the nvim/tmux plugins and the Wallhaven plugin are fetched later, by
the first `resi-shell update` with a connection.

## Build (on any Arch machine)

```
sudo pacman -S archiso
sudo resi/iso/build.sh            # -> resi/iso/out/resi-shell-<date>-x86_64.iso + SHA256SUMS
```

The build stages the official `releng` profile, appends `packages.extra`, overlays `airootfs/`, and
bakes the repo's **tracked files as they are in the working tree** into
`/usr/share/resi-shell/dotconfigfiles.tar` (uncommitted edits are included and the version is
marked `-dirty`; untracked files are not, `git add` them first). Work dir `resi/iso/work` (~10 GB, gitignored), output `resi/iso/out`.

The offline mirror is built by `offline-repo.sh`, run as your user (makepkg refuses root): it
resolves the closure of base + kernel + firmware + Limine/Btrfs/snapper + GPU drivers (Mesa, Intel,
AMD, NVIDIA) + `resi/packages.pacman` against an empty package database, downloads the packages
with their signatures, builds `yay-bin` and `resi/packages.aur` with makepkg, runs `repo-add`, and
tars oh-my-zsh, powerlevel10k, fzf-tab and TPM. Everything is cached in `resi/iso/cache/` (about
2.5 GB, gitignored) so rebuilds only fetch what changed. The ISO ends up around 4 GB.
`RESI_ISO_ONLINE=1 sudo resi/iso/build.sh` skips the mirror for a small online-only ISO.

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

1. `resi-iso-install` starts on tty1 (`/root/.zlogin`). It checks the network; with the offline
   mirror present it puts `[resi-offline]` first in the live `pacman.conf` (and, without network,
   removes the Arch repos so pacstrap never tries to download). Then it asks: target
   disk (fzf), hostname, username + password, LUKS yes/no, timezone (fzf), keyboard layout, and an
   optional git name/email for the dotfiles repo. A summary box ends with `[ Install ] [ Back ]`;
   Back returns to the questions with the previous answers as defaults.
2. It writes `/root/resi/user_configuration.json` and `user_credentials.json` and runs
   `archinstall --silent` for the base system only (Btrfs layout, Limine, user, NetworkManager, zram).
3. `resi-iso-postinstall` runs in three phases: `prepare` copies the baked repo to
   `/home/<user>/dotconfigfiles` (as a git repo tracking `origin/main`), sets up snapper and adds a
   temporary NOPASSWD sudoers drop-in (plus the mirror bind-mount and a local-only `pacman.conf`
   when installing offline); `install` runs `resi-shell install --chroot [--offline]` as the user,
   which installs the desktop packages, shell, dotfiles and services; `finish` restores a clean
   `pacman.conf` pointing at the normal Arch mirrors, removes the drop-in, copies the log to
   `/var/log/resi-install.log` and unmounts.
   The last install step is the boot splash (`resi/boot/setup-boot-splash.sh`): Plymouth theme "Resi Arch",
   `quiet splash`, Limine entry "Resi Arch". The ISO's own boot menu is branded by `build.sh`
   ("Resi Arch installer", `resi/boot/iso-splash.png` for the BIOS menu).
4. On first login Hyprland runs `resi-shell first-login`, which finishes the steps that need a live
   session (GTK theme via gsettings, greeter sync).

While installing, the screen shows only a stage board (one line per stage with a spinner, the
elapsed time and a sub-status taken from the log: the current `resi-shell` step and the pacman
`installing foo (178/420)` counter). Everything else goes to `/root/resi-install.log`; press
Ctrl+Alt+F2 and `tail -f` it to watch. A failed stage shows the last error lines from the log and
leaves the target mounted at `/mnt`. `RESI_VERBOSE=1 resi-iso-install` (or the kernel parameter
`resi.verbose`) prints the full output instead. `RESI_ISO_DRY=1 resi-iso-install` only writes the
JSON files, useful to inspect the plan without touching a disk.
