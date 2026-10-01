# Repository layout

The repo is a set of [GNU Stow](https://www.gnu.org/software/stow/) packages. Each top-level folder
mirrors your home directory, and Stow links its files into place. A config in `~/.config/...` and the
file in the repo are therefore the same file: edit either one.

## Folders

| Folder | Contents |
|---|---|
| `hypr` | Hyprland config in Lua: `looknfeel`, `input`, `windows`, `monitors`, `bindings/*`, `autostart` |
| `noctalia` | Noctalia config (`*.toml`) and color templates |
| `rofi` | launcher and menu layout |
| `alacritty`, `tmux`, `zsh`, `nvim`, `git` | terminal stack |
| `gtk`, `mpv`, `brave` | app settings |
| `bin` | [helper scripts](/reference/helpers) in `~/.local/bin` and a few launcher entries |
| `claude` | Claude Code skills and agents that know this setup |
| `hosts/<hostname>` | [per-machine overlay](/guide/machines) |
| `resi/` | installer data: package lists, login-screen templates, boot splash (`resi/boot`), ISO builder (`resi/iso`) |
| `docs/` | this website |
| `install.sh` | the installer, also installed as `resi-shell` |

## What is not in git

- Files that Noctalia renders from templates (colors for alacritty, rofi, GTK, Hyprland). They are
  listed in `.gitignore`.
- Neovim's `lazy-lock.json`. Each machine keeps its own plugin versions instead of fighting over one
  file.
- The ISO build folders `resi/iso/work`, `out` and `cache`.

## How Stow is used

`hypr`, `noctalia`, `gtk`, `bin`, `claude` and the host overlays are stowed with `--no-folding`: the
folders in your home stay real folders with one link per file. That lets a machine overlay add files to
the same folder and lets rendered files sit next to the repo files without ending up inside the repo.

The other packages are stowed normally.

By hand, without the installer:

```sh
cd ~/dotconfigfiles
stow -t ~ zsh git alacritty tmux nvim rofi mpv brave
stow --no-folding -t ~ hypr noctalia claude bin gtk
(cd hosts && stow --no-folding -t ~ "$(cat /etc/hostname)")
```

## Working on the configs

- Hyprland reloads on save. Check with `hyprctl reload && hyprctl configerrors`.
- Noctalia: `noctalia config validate`, then `noctalia msg config-reload`.
- Values changed in Noctalia's Settings window are stored in `~/.local/state/noctalia/settings.toml`
  and win over the files in the repo. `noctalia-drift` lists them.
- Before editing, read the
  [design notes](https://github.com/suryakencana007/dotconfigfiles/blob/main/NOTES.md). They record the
  reasons behind the decisions and the traps already found.

## This website

The site is built with [VitePress](https://vitepress.dev) from `docs/` and deployed to GitHub Pages by
`.github/workflows/docs.yml` on every push that changes `docs/`.

```sh
cd ~/dotconfigfiles/docs
npm install
npm run dev        # local preview with live reload
npm run build      # the same build the workflow runs
```
