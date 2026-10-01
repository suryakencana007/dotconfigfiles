# Installer ISO internals

How the ISO is put together, for people who want to change it or test it. To just use it, see
[Install from the ISO](/guide/install-iso).

## Overview

The ISO is the official Arch live system (the `releng` profile of archiso) plus:

- `archinstall`, which lays out the disk and installs the base system,
- this repo, baked in as a tarball,
- an **offline mirror**: every package the installation needs, the AUR packages already built, and the
  git clones and Noctalia plugins the installer would otherwise download,
- the installer itself, `resi-iso-install`, which starts automatically.

## Building

```sh
sudo pacman -S archiso
sudo resi/iso/build.sh            # result: resi/iso/out/resi-shell-<date>-x86_64.iso + SHA256SUMS
```

The build bakes the repo's **tracked files as they are in the working tree**: uncommitted edits are
included and the version is marked `-dirty`; untracked files are not, so `git add` them first.

| Folder | Purpose | Size |
|---|---|---|
| `resi/iso/work` | scratch space of the build | about 10 GB |
| `resi/iso/cache` | downloaded and built packages, reused by later builds | about 2.5 GB |
| `resi/iso/out` | the ISO; only the newest one is kept | about 4 GB |

`RESI_ISO_ONLINE=1 sudo resi/iso/build.sh` skips the mirror and produces a small ISO that needs
internet to install.

### The offline mirror

`offline-repo.sh` runs as your user (makepkg refuses root) and:

1. resolves everything needed against an empty package database: base system, kernel, firmware,
   Limine, Btrfs tools, snapper, all GPU driver sets, the package list of the repo and the runtime
   dependencies of the AUR packages;
2. downloads the packages with their signatures and **verifies each one with `gpgv`** against the
   build machine's pacman keyring; a bad or missing signature fails the build;
3. builds the AUR packages with makepkg;
4. creates the `resi-offline` repository;
5. bundles oh-my-zsh, powerlevel10k, fzf-tab, TPM and the enabled Noctalia plugins;
6. checks that every package can be installed from this repository alone.

The installer uses `SigLevel = Never` for this repository. The freshly created system has an empty
keyring and cannot fetch keys without a network, so signatures are checked at build time instead.

::: warning Interrupted builds
`build.sh` refuses to delete its work folder while anything is still mounted under it, and never
deletes across mount points. A leftover mount there is the host's own `/dev`.
:::

## What the installer does

1. **Questions.** `resi-iso-install` checks the network, points pacman at the mirror on the ISO, and
   asks for disk, hostname, user, password, encryption, time zone, keyboard and git identity. The
   summary ends with Install or Back.
2. **Base system.** It writes the answers as JSON and runs `archinstall --silent`: partitions, Btrfs
   subvolumes, Limine, the user, NetworkManager, zram.
3. **Desktop.** `resi-iso-postinstall` copies the repo into the new home, sets up snapper, and runs
   `resi-shell install --chroot` inside the new system. The boot splash is the last step.
4. **First login.** Hyprland runs `resi-shell first-login`, which finishes what needs a running
   desktop.

While it runs, the screen shows one line per stage with a timer and a short status taken from the log.
The full output is in `/root/resi-install.log`, and is copied to `/var/log/resi-install.log` on the
installed system.

### Without internet

With no network the installer passes `--offline --skip-ntp --skip-wkd --skip-wifi-check
--no-pkg-lookups` to archinstall. These are command-line flags, not settings in the JSON file: without
them archinstall waits for a time sync that never comes.

The dotfiles repo on the new system has no git history yet. The first `resi-shell update` with
internet links it to GitHub, using the commit recorded in `.git/resi-iso-commit`.

## Environment switches

| Variable | Effect |
|---|---|
| `RESI_VERBOSE=1` (or kernel parameter `resi.verbose`) | show the full output instead of the stage list |
| `RESI_ISO_DRY=1` | only write the archinstall JSON files to `/root/resi/`, touch no disk |

## Testing in a virtual machine

```sh
sudo pacman -S qemu-desktop edk2-ovmf
resi/iso/test-vm.sh resi/iso/out/resi-shell-*.iso   # boot the ISO into a 40 GB virtual disk
resi/iso/test-vm.sh                                  # boot the installed system afterwards
RESI_VM_NET=0 resi/iso/test-vm.sh <iso>              # no network card: a true offline test
```

The virtual disk lives in `~/.local/state/resi/vm/`; delete it to start from an empty disk.

By default the VM has networking, so it uses the mirror but does not prove that an installation works
with no network at all. Use `RESI_VM_NET=0` for that.

A host folder is shared with the VM and works without networking, which is handy for getting the log
out:

```sh
mkdir -p /tmp/host && mount -t 9p -o trans=virtio host /tmp/host    # inside the VM
cp /root/resi-install.log /tmp/host/                                # appears in ~/.local/state/resi/vm/share
```
