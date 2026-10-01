# Install from the ISO

Use the ISO for a new machine or when you want to wipe one. It carries every package it needs, so the
installation works **without internet** and takes a few minutes.

::: danger The chosen disk is erased
The installer wipes the whole disk you select, including other operating systems on it. Copy anything
you need off the machine first.
:::

## What you need

- A machine with UEFI firmware and **Secure Boot switched off**.
- A disk of at least 20 GB.
- A USB stick of 8 GB or more.
- Any Arch machine to build the ISO on (there is no ready-made download).

## 1. Build the ISO

```sh
git clone https://github.com/suryakencana007/dotconfigfiles.git ~/dotconfigfiles
sudo pacman -S archiso
sudo ~/dotconfigfiles/resi/iso/build.sh
```

The result is `resi/iso/out/resi-shell-<date>-x86_64.iso`, about 4 GB. The first build downloads the
packages (about 2.5 GB, cached for later builds).

## 2. Write it to a USB stick

Find the stick first. `dd` overwrites the device you name without asking.

```sh
lsblk -dpo NAME,SIZE,MODEL,TRAN        # the stick has TRAN = usb, for example /dev/sdb
sudo dd if=resi/iso/out/resi-shell-*.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

## 3. Boot and answer the questions

Boot the target machine from the stick. The installer starts by itself and asks for:

1. the disk to install to,
2. a hostname,
3. your user name and password,
4. whether to encrypt the disk (you will type the passphrase at every boot),
5. time zone and keyboard layout,
6. optionally your git name and email.

It then shows a summary. Choose **Install** to start, or **Back** to change an answer.

::: tip Hostname
If the repo has an overlay for this machine (`hosts/<hostname>`), type that hostname so it gets applied.
See [Several machines](/guide/machines).
:::

## 4. Wait, then reboot

While it installs you see a short list of stages with a timer, not scrolling package output. The full
output goes to `/root/resi-install.log`.

When it says **Installed in ...**, remove the stick and reboot. You get the Resi Arch boot splash and
then the login screen.

## 5. If you installed without internet

Connect to a network and run once:

```sh
resi-shell update
```

This fetches the few things that only exist online (tmux and Neovim plugins) and links the dotfiles repo
to GitHub so later updates work.

## What ends up on the disk

- GPT with a 1 GiB EFI partition and Btrfs on the rest (subvolumes `@`, `@home`, `@log`, `@pkg`,
  compressed with zstd), optionally inside LUKS.
- Limine as the bootloader, zram for swap, snapper snapshots of `/`.
- Your user with sudo, NetworkManager, and the complete desktop.

## If something goes wrong

A failed stage is marked and the last error lines are shown, with the path of the full log. The target
stays mounted at `/mnt` so you can look at it. Fix the cause and run `resi-iso-install` again.

More about how the ISO works and how to test it in a virtual machine:
[Installer ISO internals](/reference/iso).
