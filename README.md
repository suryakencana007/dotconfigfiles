# resi-shell

An opinionated Arch Linux desktop in one command: **Hyprland** (Lua config, Omarchy-style keybindings and
window rules) + **Noctalia v5** (bar, launcher panels, notifications, lock screen, idle, wallpaper, greeter)
+ **rofi** (app launcher and a hierarchical menu) + a modern terminal stack (zsh, Powerlevel10k, alacritty,
tmux, Neovim/LazyVim). Every color follows the wallpaper: Noctalia generates a Material 3 palette and renders
it into alacritty, rofi, Neovim, the Hyprland borders, the shell prompt and the login screen.

The whole thing is a [GNU Stow](https://www.gnu.org/software/stow/) dotfiles repo plus an idempotent
installer, so a wiped machine is back to 100% with:

```sh
git clone https://github.com/suryakencana007/dotconfigfiles.git ~/dotconfigfiles
~/dotconfigfiles/install.sh
```

Heavily inspired by [Omarchy](https://omarchy.org) (bindings, menu, tmux and window rules were ported from
its Lua config) and built on [Noctalia](https://noctalia.dev).

See [NOTES.md](NOTES.md) for the *why* behind the decisions here, gotchas to know before editing, and
things that were tried and rejected.

---

## What you get

| Area | Details |
|---|---|
| **Compositor** | Hyprland 0.56+ with the native Lua config, split into modules (`looknfeel`, `input`, `windows`, `bindings/*`). Omarchy defaults: gaps 5/10, `Super+W` close, `Super+arrows` focus, `Super+1..0` workspaces, groups, resize, universal `Super+C/V/X/A` clipboard, Quake-style scratchpad on ``Super+` ``. Blur, subtle window opacity, Noctalia-themed borders. |
| **Capture** | Screenshots by Noctalia's native screencopy capture (frozen region select, annotator, clipboard + `~/Pictures/Screenshots`); screen recording by gpu-screen-recorder (KMS capture, GPU encoding, 60 fps, desktop audio), toggled from one key like Omarchy, with a red REC button in the bar while recording (click to stop). |
| **Shell** | Noctalia v5: transparent bar with island-style capsule groups, control center, notifications, clipboard history, wallpaper picker, OSD, polkit agent, idle lock (10 min) and screen-off (11 min), blurred lock screen with a centered compact login box. |
| **Launcher & menu** | rofi 2.0 (Wayland). `Super+Alt+Space` = app launcher, `Super+Space` = Omarchy-style hierarchical menu (Apps, Learn, Trigger, Toggle, Style, Setup, Install, Update, Remove, About, System). Install > Package / AUR opens a floating fzf picker with package previews (multi-select with Tab), like Omarchy's; Update > Resi shell runs `resi-shell update` in a floating terminal, after a Yes/No confirmation like Omarchy's update screen. Remove > Package lists explicitly installed packages and removes the selection with their unused dependencies. In a submenu, Backspace on an empty filter goes back. Both toggle: press again to close. |
| **Login** | greetd + noctalia-greeter; wallpaper, palette, font, corner radius and monitor layout are auto-synced from the desktop (`noctalia/greeter.toml`) without a password prompt. |
| **GTK apps** | Thunar and other GTK3/GTK4 apps use adw-gtk3 + Papirus icons in dark mode, colored by Noctalia's GTK templates. |
| **Media** | mpv + yt-dlp as the default video/audio player, hardware decoding on the iGPU, floating window without transparency. |
| **Terminal** | alacritty (MesloLGS Nerd Font, opacity, Noctalia colors), zsh + oh-my-zsh + Powerlevel10k (lean, one line, ANSI colors so it follows the theme), fzf/fzf-tab, zoxide, eza, bat, fd, ripgrep, delta, dust, duf, btop, tldr, lazygit. |
| **tmux** | Omarchy's config: `Ctrl+Space` prefix, `Alt+Enter` split, `Alt+1..9` windows, status bar on top, TPM with resurrect + continuum (sessions survive reboots). |
| **Neovim** | LazyVim with a base16 colorscheme rendered by Noctalia (live reload on theme change), transparent background. |
| **Helpers** | `hypr-keybindings` (`Super+K`, searchable list formatted like Omarchy's), `hypr-menu`, `hypr-theme-carousel` (`Super+Shift+Ctrl+Space`: sliding wallpaper carousel like omarchy-shell's theme picker, the centered card is the selection), `hypr-theme` (rofi: palettes, dark/light, gallery), `hypr-record` (screen recording toggle), `hypr-pkg-install` (fzf package picker for repo/AUR install and removal, used by the menu), `hypr-tui` (runs a command in a floating terminal and waits for a key before closing, like Omarchy's presentation wrapper), `rofi-toggle`, `resi-shell`. |
| **Claude Code** | Skills and agents that know this setup (`hyprland-config`, `noctalia-config`, `terminal-stack`, `dotfiles-stow`; agents `hyprland-tweaker`, `noctalia-tweaker`, `dotfiles-keeper`). |

### Key bindings (the ones you will use every day)

| Action | Keys |
|---|---|
| Menu / App launcher | `Super+Space` / `Super+Alt+Space` |
| Terminal / Terminal + tmux | `Super+Enter` / `Super+Alt+Enter` |
| Browser (Brave) / File manager (Thunar) | `Super+Shift+B` / `Super+Shift+F` |
| Close window / Fullscreen / Float | `Super+W` / `Super+F` / `Super+T` |
| Focus / Swap / Workspace | `Super+arrows` / `Super+Shift+arrows` / `Super+1..0` |
| Control center / Session menu / Lock | `Super+S` / `Super+Esc` / `Super+Ctrl+L` |
| Clipboard history / Wallpaper | `Super+Ctrl+V` / `Super+Ctrl+Space` |
| Theme switcher / Wallhaven browser | `Super+Shift+Ctrl+Space` / `Super+Ctrl+Alt+Space` |
| Screenshot area / window / screen | `Print` / `Shift+Print` / `Ctrl+Print` (Noctalia, with annotator) |
| Record area / screen (toggle) | `Alt+Print` / `Ctrl+Alt+Print` (gpu-screen-recorder, like Omarchy) |
| All key bindings | `Super+K` |

---

## Installation

### Walkthrough for a fresh machine

Every step below is a command you can paste. Lines starting with `#` are comments.

```sh
# 1. Base Arch is installed (archinstall is fine) and you are logged in as your user (in the wheel group).
sudo pacman -Syu --needed git base-devel

# 2. Clone over HTTPS first: no SSH key exists on a fresh machine yet.
git clone https://github.com/suryakencana007/dotconfigfiles.git ~/dotconfigfiles
cd ~/dotconfigfiles

# 3. Optional: preview what the installer will do.
./install.sh --dry-run

# 4. Install everything. Asks for sudo once; ~10-20 minutes depending on network.
./install.sh

# 5. Reboot so the GPU driver, greetd and the login shell take effect.
sudo reboot
```

After the reboot, log in through the Noctalia greeter and finish the parts no script can do:

```sh
# 6. SSH key for GitHub, then switch the repo remote to SSH so push works.
ssh-keygen -t ed25519 -C "$(cat /etc/hostname)"
cat ~/.ssh/id_ed25519.pub        # paste at https://github.com/settings/keys
cd ~/dotconfigfiles && git remote set-url origin git@github.com:suryakencana007/dotconfigfiles.git
git config user.name "Your Name" && git config user.email "you@example.com"   # only if the installer did not ask

# 7. Wallpapers: put images here, then pick one in Noctalia (Super+Ctrl+Space) or the carousel (Super+Shift+Ctrl+Space).
mkdir -p ~/Pictures/Wallpapers && cp /path/to/*.jpg ~/Pictures/Wallpapers/

# 8. Check the result any time.
resi-shell doctor
```

In Noctalia Settings (`Super+Shift+,`): run the setup wizard if it opens. Greeter auto-sync is enabled by
`noctalia/greeter.toml` and the installer triggers the first sync; if the login screen still shows the default look,
run `noctalia msg greeter-sync` once (or Settings → Security → Sync Now). The color templates (Hyprland borders, alacritty, GTK 3/4, btop) are enabled by
`noctalia/templates.toml`; if the wizard wrote its own list, check **Templates** and make sure Hyprland, Alacritty,
GTK 3 and GTK 4 are on, otherwise borders and apps keep their static colors after a wallpaper change.
Sign in to Brave and Spotify. On a laptop with a discrete GPU, set the BIOS to hybrid graphics.

### Machine-specific parts

If this machine should carry its own overrides (centered lock screen login box, extra monitors), add a host
overlay before or after the install, see [Several machines](#several-machines-hostshostname) below:

```sh
cd ~/dotconfigfiles
cp -r hosts/legionarch "hosts/$(cat /etc/hostname)"
hyprctl monitors -j | jq -r '.[].name'                        # e.g. eDP-1
sed -i 's/eDP-2/eDP-1/g' "hosts/$(cat /etc/hostname)/.config/noctalia/lockscreen-widgets.toml"
resi-shell install                                            # re-run: idempotent, only stows what is missing
git add hosts && git commit -m "Add host overlay for $(cat /etc/hostname)" && git push
```

### What the installer does

The installer is **idempotent**: running it again on a configured machine is safe and only fills in what is
missing. It performs these steps in order:

1. **Packages** from the official repos, listed in `resi/packages.pacman` (Hyprland, Noctalia, rofi, terminal
   tools, fonts, audio, network, greetd, mpv, ...).
2. **AUR**: installs `yay` if needed, then `resi/packages.aur` (Brave, Spotify, noctalia-greeter,
   gpu-screen-recorder).
3. **GPU drivers by detection**: NVIDIA (`nvidia-open-dkms` + `linux-headers` + early KMS in mkinitcpio),
   AMD (mesa, vulkan-radeon), Intel (mesa, vulkan-intel), plus CPU microcode.
4. **Shell**: oh-my-zsh, Powerlevel10k, fzf-tab, links the distro's zsh plugins, `chsh` to zsh.
5. **Stow**: links every package into `$HOME`, plus the host overlay when `hosts/<hostname>` exists. Existing
   plain files are moved aside as `*.pre-resi` (never a file that already resolves into the repo, so re-runs are safe).
6. **tmux** plugins (TPM) and **Neovim** plugins (lazy.nvim, headless).
7. **Folders** (`~/Pictures/Screenshots`, `~/Pictures/Wallpapers`) and your **git identity** (asked once,
   stored in the repo's local config, never committed).
8. **Services**: NetworkManager, bluetooth, power-profiles-daemon, greetd with `resi/greetd-config.toml`.
9. **GTK**: dark mode, adw-gtk3 theme, Papirus icons; mpv as default video/audio player.
10. **Greeter**: installs `resi/greeter.toml` for noctalia-greeter and enables passwordless theme sync.

### The `resi-shell` command

Once installed, the same script is available as `resi-shell`:

| Command | What it does |
|---|---|
| `resi-shell install [--dry-run]` | full setup, safe to repeat |
| `resi-shell update [-y]` | asks for confirmation (skip with `-y`), then `git pull` (uncommitted local changes are stashed and re-applied after asking; a diverged branch or a conflict stops with instructions), full pacman + AUR upgrade, new packages, restow, plugin updates, reload Hyprland and Noctalia; offers a reboot when the kernel or Hyprland was replaced. Output is logged to `~/.cache/resi-shell-update.log` |
| `resi-shell doctor` | health check: stow packages, broken links, key files present and pointing into the repo, Noctalia include in `hyprland.lua`, Hyprland/Noctalia/rofi/tmux/zsh configs, repo state |
| `resi-shell packages` | print the package lists |

---

## Repository layout

Each top-level folder is a Stow package mirroring `$HOME`:

| Package | Contents | Stow mode |
|---|---|---|
| `zsh` | `.zshrc`, `.p10k.zsh` | file links |
| `git` | `.gitconfig` (delta pager only, no identity) | file links |
| `alacritty` | `.config/alacritty/alacritty.toml` | plain stow: folder link when `~/.config/alacritty` did not exist yet (then `themes/` is rendered into the repo folder, gitignored), per-file link when it did |
| `tmux` | `.config/tmux/tmux.conf` | same as alacritty (`plugins/` is TPM's, gitignored when it lands in the repo folder) |
| `nvim` | `.config/nvim` (LazyVim + Noctalia theme template) | folder link |
| `rofi` | `.config/rofi/{config,layout}.rasi` | folder link (`noctalia.rasi` is rendered, ignored) |
| `hypr` | `.config/hypr/*.lua`, `bindings/*.lua` | `--no-folding` (real dir) |
| `noctalia` | `.config/noctalia/*.toml`, `templates/` | `--no-folding` (real dir) |
| `gtk` | `.config/gtk-3.0/settings.ini`, `.config/gtk-4.0/settings.ini` (dark mode; colors are rendered by Noctalia) | `--no-folding` |
| `mpv` | `.config/mpv/{mpv.conf,input.conf}` (gpu-next on the compositor GPU, VA-API decode, default player for video/audio) | folder link |
| `bin` | `.local/bin/{hypr-keybindings,hypr-menu,hypr-theme,hypr-theme-carousel,hypr-record,hypr-pkg-install,hypr-tui,rofi-toggle,resi-shell}` | `--no-folding` |
| `claude` | `.claude/skills/*`, `.claude/agents/*` | `--no-folding` |
| `hosts/<hostname>` | machine-specific overlay, see below | `--no-folding`, from `hosts/` |
| `resi/` | installer data: package lists, greeter and greetd templates | not stowed |
| `install.sh` | the installer | not stowed |

Files Noctalia renders from templates are listed in `.gitignore` and never committed. So is Neovim's
`lazy-lock.json`: lazy.nvim rewrites it on every machine, so each machine keeps its own plugin pins instead of
fighting over one file in git.

### Several machines: `hosts/<hostname>/`

Everything generic lives in the packages above and adapts by itself: GPU drivers and driver environment are
detected at install time, the monitor rule is a wildcard, the NVIDIA environment is only applied when NVIDIA
is the sole GPU. Anything tied to one machine goes into `hosts/<hostname>/`, a Stow overlay that the installer
applies **only** when the folder name matches `/etc/hostname`.

On a machine without a matching folder nothing breaks: the installer prints a note that no overlay exists and
continues with the generic config. What you lose is only what is machine-specific, for example the lock screen
login box falls back to Noctalia's default placement (bottom) instead of the centered layout.

`legionarch` (a Lenovo Legion, Ryzen 4800H + GTX 1660 Ti in hybrid mode) carries:

- `.config/noctalia/lockscreen-widgets.toml` — login box layout for its `eDP-2` panel;
- `.config/hypr/local.lua` — Hyprland overrides loaded last (monitors, per-machine rules). Empty for now.

To add a machine:

```sh
cd ~/dotconfigfiles
cp -r hosts/legionarch "hosts/$(cat /etc/hostname)"
hyprctl monitors -j | jq -r '.[].name'                       # find the panel name, e.g. eDP-1
sed -i 's/eDP-2/eDP-1/g' "hosts/$(cat /etc/hostname)/.config/noctalia/lockscreen-widgets.toml"
git add hosts && git commit -m "Add host overlay for $(cat /etc/hostname)" && git push
resi-shell install                                           # or: cd hosts && stow --no-folding -t ~ "$(cat /etc/hostname)"
```

Overlays never interfere with each other: each machine only stows the folder that carries its own hostname.
Per-machine Hyprland tweaks (a second monitor, scale, a device-specific rule) go into that host's `local.lua`.

### Manual stow (without the installer)

```sh
cd ~/dotconfigfiles
stow -t ~ zsh git alacritty tmux nvim rofi mpv
stow --no-folding -t ~ hypr noctalia claude bin gtk
(cd hosts && stow --no-folding -t ~ "$(cat /etc/hostname)")
```

---

## Day-to-day

- Edit configs through their normal paths (`~/.config/hypr/...`) or in the repo; they are the same files.
- Hyprland reloads on save; validate with `hyprctl reload && hyprctl configerrors`.
- Noctalia: `noctalia config validate`, then `noctalia msg config-reload`. Values changed in the Settings GUI are
  stored in `~/.local/state/noctalia/settings.toml` and win over the files here.
- Commit and push from `~/dotconfigfiles`; `resi-shell update` on the other machines.
