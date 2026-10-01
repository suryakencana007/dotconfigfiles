# What is resi-shell?

resi-shell is a complete Arch Linux desktop that installs itself. You get a tiling window manager, a
bar with panels, a launcher, a themed terminal and a login screen that all look like one product, and a
single command that keeps them up to date.

The desktop is called **Resi Arch**; the tool that installs and maintains it is **`resi-shell`**.

<script setup>
import { withBase } from "vitepress";
</script>

## A three-minute tour

<video class="resi-demo" controls playsinline muted preload="none" :poster="withBase('/demo-poster.jpg')">
  <source :src="withBase('/demo.mp4')" type="video/mp4">
  Your browser does not play this video. <a :href="withBase('/demo.mp4')">Download it</a> instead.
</video>

## The parts

| Part | Role |
|---|---|
| [Hyprland](https://hypr.land) | window manager (tiling, workspaces, animations) |
| [Noctalia v5](https://noctalia.dev) | bar, control center, notifications, clipboard, wallpaper, lock screen, login screen |
| rofi | app launcher and the hierarchical menu |
| alacritty, zsh, tmux, Neovim | terminal stack |
| `resi-shell` | installer, updater and health check |

## What makes it different

- **It follows your wallpaper.** Pick an image and Noctalia builds a color palette from it. The same
  palette is rendered into the terminal, the launcher, Neovim, GTK apps, the window borders, the shell
  prompt and the login screen.
- **It is the same on every machine.** Graphics drivers are detected, the monitor rule is a wildcard,
  the lock-screen layout is generated for the screen it finds. Real one-machine exceptions live in a
  small [overlay folder](/guide/machines).
- **It can be reinstalled without thinking.** The [installer ISO](/guide/install-iso) works without
  internet and takes a few minutes. The [script](/guide/install-script) can be run again at any time.
- **It stays readable.** Everything is a dotfiles repo managed with GNU Stow. Configs in `~/.config`
  are links into the repo, so there is nothing hidden.

## Where to go next

- New or wiped machine: [Install from the ISO](/guide/install-iso)
- Arch already installed: [Install with the script](/guide/install-script)
- Already installed: [First steps](/guide/first-steps), then [Everyday keys](/guide/keys)

## Credits

resi-shell is heavily inspired by [Omarchy](https://omarchy.org): the key bindings, the menu, the tmux
config and the window rules were ported from it. The ISO layout follows the Omarchy ISO too.
