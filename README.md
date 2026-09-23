# resi-shell

An opinionated Arch Linux desktop in one command: **Hyprland** (Lua config, Omarchy-style keybindings and
window rules) + **Noctalia v5** (bar, launcher panels, notifications, lock screen, idle, wallpaper, greeter)
+ **rofi** (app launcher and a hierarchical menu) + a modern terminal stack (zsh, Powerlevel10k, alacritty,
tmux, Neovim/LazyVim). Every color follows the wallpaper: Noctalia generates a Material 3 palette and renders
it into alacritty, rofi, Neovim, the Hyprland borders, the shell prompt and the login screen.

The whole thing is a [GNU Stow](https://www.gnu.org/software/stow/) dotfiles repo plus an idempotent
installer, so a wiped machine is back to 100% with:

```sh
git clone git@github.com:suryakencana007/dotconfigfiles.git ~/dotconfigfiles
~/dotconfigfiles/install.sh
```

Heavily inspired by [Omarchy](https://omarchy.org) (bindings, menu, tmux and window rules were ported from
its Lua config) and built on [Noctalia](https://noctalia.dev).

---

## What you get

| Area | Details |
|---|---|
| **Compositor** | Hyprland 0.56+ with the native Lua config, split into modules (`looknfeel`, `input`, `windows`, `bindings/*`). Omarchy defaults: gaps 5/10, `Super+W` close, `Super+arrows` focus, `Super+1..0` workspaces, groups, resize, universal `Super+C/V/X/A` clipboard, Quake-style scratchpad on ``Super+` ``. Blur, subtle window opacity, Noctalia-themed borders. |
| **Shell** | Noctalia v5: transparent bar with island-style capsule groups, control center, notifications, clipboard history, wallpaper picker, OSD, polkit agent, idle lock (10 min) and screen-off (11 min), blurred lock screen with a centered compact login box. |
| **Launcher & menu** | rofi 2.0 (Wayland). `Super+Alt+Space` = app launcher, `Super+Space` = Omarchy-style hierarchical menu (Apps, Learn, Trigger, Toggle, Style, Setup, About, System). Both toggle: press again to close. |
| **Login** | greetd + noctalia-greeter; wallpaper, palette, font and corner radius are synced from the desktop without a password prompt. |
| **GTK apps** | Thunar and other GTK3/GTK4 apps use adw-gtk3 + Papirus icons in dark mode, colored by Noctalia's GTK templates. |
| **Terminal** | alacritty (MesloLGS Nerd Font, opacity, Noctalia colors), zsh + oh-my-zsh + Powerlevel10k (lean, one line, ANSI colors so it follows the theme), fzf/fzf-tab, zoxide, eza, bat, fd, ripgrep, delta, dust, duf, btop, tldr, lazygit. |
| **tmux** | Omarchy's config: `Ctrl+Space` prefix, `Alt+Enter` split, `Alt+1..9` windows, status bar on top, TPM with resurrect + continuum (sessions survive reboots). |
| **Neovim** | LazyVim with a base16 colorscheme rendered by Noctalia (live reload on theme change), transparent background. |
| **Helpers** | `hypr-keybindings` (`Super+K`, searchable list formatted like Omarchy's), `hypr-menu`, `hypr-theme` (`Super+Shift+Ctrl+Space`: wallpaper gallery with thumbnails, Noctalia palettes, dark/light toggle), `rofi-toggle`, `resi-shell`. |
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
| Screenshot area / window / screen | `Print` / `Shift+Print` / `Ctrl+Print` |
| All key bindings | `Super+K` |

---

## Installation

### 1. Base system

Install Arch Linux the way you like (`archinstall` is fine). You need a regular user with `sudo`, a working
network connection and `git`. Nothing else: the installer brings in every other package.

### 2. Run the installer

```sh
git clone git@github.com:suryakencana007/dotconfigfiles.git ~/dotconfigfiles
~/dotconfigfiles/install.sh --dry-run   # optional: print the plan without changing anything
~/dotconfigfiles/install.sh             # asks for sudo once, then runs unattended
```

The installer is **idempotent**: running it again on a configured machine is safe and only fills in what is
missing. It performs these steps in order:

1. **Packages** from the official repos, listed in `resi/packages.pacman` (Hyprland, Noctalia, rofi, terminal
   tools, fonts, audio, network, greetd, ...).
2. **AUR**: installs `yay` if needed, then `resi/packages.aur` (Brave, Spotify, noctalia-greeter).
3. **GPU drivers by detection**: NVIDIA (`nvidia-open-dkms` + `linux-headers` + early KMS in mkinitcpio),
   AMD (mesa, vulkan-radeon), Intel (mesa, vulkan-intel), plus CPU microcode.
4. **Shell**: oh-my-zsh, Powerlevel10k, fzf-tab, links the distro's zsh plugins, `chsh` to zsh.
5. **Stow**: links every package into `$HOME`. Existing plain files are moved aside as `*.pre-resi`.
6. **tmux** plugins (TPM) and **Neovim** plugins (lazy.nvim, headless).
7. **Folders** (`~/Pictures/Screenshots`, `~/Pictures/Wallpapers`) and your **git identity** (asked once,
   stored in the repo's local config, never committed).
8. **Services**: NetworkManager, bluetooth, power-profiles-daemon, greetd with `resi/greetd-config.toml`.
9. **Greeter**: installs `resi/greeter.toml` for noctalia-greeter and enables passwordless theme sync.

### 3. After the first boot

- **Reboot** so the GPU driver, greetd and the login shell take effect.
- Log in. Noctalia's setup wizard opens: pick a wallpaper (put images in `~/Pictures/Wallpapers`) and a theme.
  Every template (alacritty, rofi, Neovim, Hyprland borders) is rendered the first time a theme is chosen.
- In Noctalia Settings (`Super+Shift+,`) enable **Security → Auto-Sync Greeter** and, under **Templates**, turn on
  **GTK 3** and **GTK 4** so Thunar and other GTK apps pick up the palette.
- Generate an SSH key and add it to GitHub so `git push` works; sign in to Brave and Spotify.
- Laptops with a dGPU: set the BIOS to **hybrid** graphics so the iGPU drives the panel.

### The `resi-shell` command

Once installed, the same script is available as `resi-shell`:

| Command | What it does |
|---|---|
| `resi-shell install [--dry-run]` | full setup, safe to repeat |
| `resi-shell update` | `git pull`, new packages, restow, plugin updates, reload Hyprland and Noctalia |
| `resi-shell doctor` | health check: stow packages, broken links, Hyprland/Noctalia/rofi/tmux/zsh configs, repo state |
| `resi-shell packages` | print the package lists |

---

## Repository layout

Each top-level folder is a Stow package mirroring `$HOME`:

| Package | Contents | Stow mode |
|---|---|---|
| `zsh` | `.zshrc`, `.p10k.zsh` | file links |
| `git` | `.gitconfig` (delta pager only, no identity) | file links |
| `alacritty` | `.config/alacritty/alacritty.toml` | file links (`themes/` is rendered, outside the repo) |
| `tmux` | `.config/tmux/tmux.conf` | file links (`plugins/` is TPM's, outside the repo) |
| `nvim` | `.config/nvim` (LazyVim + Noctalia theme template) | folder link |
| `rofi` | `.config/rofi/{config,layout}.rasi` | folder link (`noctalia.rasi` is rendered, ignored) |
| `hypr` | `.config/hypr/*.lua`, `bindings/*.lua` | `--no-folding` (real dir) |
| `noctalia` | `.config/noctalia/*.toml`, `templates/` | `--no-folding` (real dir) |
| `gtk` | `.config/gtk-3.0/settings.ini`, `.config/gtk-4.0/settings.ini` (dark mode; colors are rendered by Noctalia) | `--no-folding` |
| `bin` | `.local/bin/{hypr-keybindings,hypr-menu,hypr-theme,rofi-toggle,resi-shell}` | `--no-folding` |
| `claude` | `.claude/skills/*`, `.claude/agents/*` | `--no-folding` |
| `hosts/<hostname>` | machine-specific overlay, see below | `--no-folding`, from `hosts/` |
| `resi/` | installer data: package lists, greeter and greetd templates | not stowed |
| `install.sh` | the installer | not stowed |

Files Noctalia renders from templates are listed in `.gitignore` and never committed.

### Several machines: `hosts/<hostname>/`

Everything generic lives in the packages above. Anything tied to one machine goes into `hosts/<hostname>/`,
which the installer stows automatically when the folder name matches `/etc/hostname`. `legionarch` (a Lenovo
Legion, Ryzen 4800H + GTX 1660 Ti in hybrid mode) carries:

- `.config/noctalia/lockscreen-widgets.toml` — login box layout for its `eDP-2` panel;
- `.config/hypr/local.lua` — Hyprland overrides loaded last (monitors, per-machine rules).

For a new machine, copy `hosts/legionarch` to `hosts/<its-hostname>`, adjust, commit, then run the installer.
GPU drivers are detected at install time and the NVIDIA environment is only applied when NVIDIA is the sole GPU.

### Manual stow (without the installer)

```sh
cd ~/dotconfigfiles
stow -t ~ zsh git alacritty tmux nvim rofi
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
