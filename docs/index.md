---
layout: home
title: Resi Arch
titleTemplate: Arch Linux desktop that installs itself

hero:
  name: Resi Arch
  text: An Arch Linux desktop that installs itself
  tagline: Hyprland, Noctalia, rofi and a modern terminal. Pick a wallpaper and everything follows its colors.
  image:
    src: /boot-splash.png
    alt: The Resi Arch boot screen
  actions:
    - theme: brand
      text: Get started
      link: /guide/
    - theme: alt
      text: Install from the ISO
      link: /guide/install-iso
    - theme: alt
      text: View on GitHub
      link: https://github.com/suryakencana007/dotconfigfiles

features:
  - icon: 💿
    title: Installs in minutes, even offline
    details: The installer ISO carries every package it needs. Answer a few questions, wait a few minutes, reboot into a finished desktop. No internet required.
  - icon: 🎨
    title: One wallpaper, one look
    details: Noctalia builds a palette from your wallpaper and renders it into the terminal, launcher, editor, window borders, prompt and login screen.
  - icon: ⌨️
    title: Omarchy keys and menu
    details: The same key bindings, window rules and hierarchical menu as Omarchy. Super+Space reaches everything; Super+K lists every binding.
  - icon: 🔋
    title: Laptop friendly
    details: Automatic battery mode, power profiles remembered per power source, battery charge limit, lid and clamshell handling, night light.
  - icon: 🧰
    title: Development ready
    details: One click sets up Ruby, Node, Go, PHP, Python, Elixir, Java, Rust and more through mise, plus databases in rootless Podman containers.
  - icon: 🔁
    title: Safe to repeat
    details: The installer only fills in what is missing. resi-shell update keeps the setup, Arch, the AUR and your tools current, and resi-shell doctor tells you what is wrong.
---

## Two ways to install

| | Installer ISO | Script |
|---|---|---|
| Use it when | the machine is new or you want to wipe it | Arch is already installed |
| Internet | not needed | needed |
| Time | a few minutes | 10 to 20 minutes |
| Disk | **erased**, set up as Btrfs + Limine | left as it is |
| Guide | [Install from the ISO](/guide/install-iso) | [Install with the script](/guide/install-script) |

On an existing Arch install it is two commands:

```sh
git clone https://github.com/suryakencana007/dotconfigfiles.git ~/dotconfigfiles
~/dotconfigfiles/install.sh
```

## What is inside

- **Hyprland** with a Lua config split into small modules: look, input, window rules, key bindings.
- **Noctalia v5** for the bar, control center, notifications, clipboard history, wallpaper, lock screen,
  idle handling and the login screen.
- **rofi** for the app launcher and the menu.
- **Terminal**: alacritty, zsh with Powerlevel10k, tmux, Neovim (LazyVim) and the usual modern tools.
- **Plumbing**: an idempotent installer, a health check, an update command, per-machine overlays, a boot
  splash and an offline installer ISO.

Everything is a [GNU Stow](https://www.gnu.org/software/stow/) dotfiles repo, so your configs stay plain
files you can read and edit.

## Credits

Heavily inspired by [Omarchy](https://omarchy.org) and built on [Noctalia](https://noctalia.dev).
Released under the [MIT License](https://github.com/suryakencana007/dotconfigfiles/blob/main/LICENSE).
