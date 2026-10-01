# Install with the script

Use the script when Arch Linux is already installed and you want to keep the disk as it is.

## What you need

- A working Arch install (the defaults of `archinstall` are fine).
- A user in the `wheel` group, so `sudo` works.
- An internet connection.

## Install

```sh
sudo pacman -Syu --needed git base-devel
git clone https://github.com/suryakencana007/dotconfigfiles.git ~/dotconfigfiles
cd ~/dotconfigfiles
./install.sh --dry-run        # optional: shows what would happen, changes nothing
./install.sh                  # asks for sudo once
sudo reboot
```

It takes 10 to 20 minutes depending on your connection. After the reboot, log in at the new login
screen and continue with [First steps](/guide/first-steps).

::: tip Safe to repeat
The installer only fills in what is missing. If it stops halfway, fix the cause and run it again.
:::

## What it does, step by step

1. **Packages** from the official repos (`resi/packages.pacman`): Hyprland, Noctalia, rofi, terminal
   tools, fonts, audio, network, greetd, mpv, Plymouth and more.
2. **AUR**: installs `yay` if needed, then `resi/packages.aur` (Brave, Spotify, noctalia-greeter,
   gpu-screen-recorder).
3. **GPU drivers by detection**: NVIDIA (`nvidia-open-dkms`, kernel headers, early KMS), AMD (mesa,
   vulkan-radeon), Intel (mesa, vulkan-intel), plus CPU microcode.
4. **Shell**: oh-my-zsh, Powerlevel10k, fzf-tab; zsh becomes the login shell.
5. **Configs**: links every package of the repo into your home with GNU Stow, plus the overlay for this
   machine when `hosts/<hostname>` exists. Files already in the way are kept as `*.pre-resi`.
6. **Plugins** for tmux (TPM) and Neovim (lazy.nvim).
7. **Folders** (`~/Pictures/Screenshots`, `~/Pictures/Wallpapers`) and your **git identity** (asked
   once, stored locally, never committed).
8. **Services**: NetworkManager, Bluetooth, power-profiles-daemon, greetd.
9. **GTK**: dark mode, adw-gtk3 theme, Papirus icons; mpv as the default player.
10. **Login screen**: noctalia-greeter with its look synced from the desktop.
11. **Boot splash**: the Resi Arch Plymouth theme and bootloader branding, see
    [Boot splash](/guide/boot-splash).

At the first login a short one-time step finishes what needs a running desktop: the GTK theme, the
login-screen sync, the lock-screen layout for your monitor and the Wallhaven plugin.
