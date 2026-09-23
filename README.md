# dotconfigfiles

Config Arch + Hyprland (Lua) + Noctalia v5, dikelola dengan GNU Stow. Tiap folder = satu paket.

| Paket | Isi |
|---|---|
| zsh | .zshrc (oh-my-zsh, fzf, zoxide, eza, bat), .p10k.zsh (lean, satu baris, warna ANSI) |
| git | .gitconfig (delta) |
| alacritty | alacritty.toml (Nerd Font, opacity, padding, import tema Noctalia) |
| tmux | tmux.conf (gaya Omarchy, TPM + resurrect/continuum) |
| hypr | hyprland.lua + modul (gaya Omarchy, binding Noctalia) |
| noctalia | bar.toml, shell.toml, nvim.toml (template) |
| nvim | LazyVim + tema base16 dari Noctalia |
| bin | skrip di ~/.local/bin: hypr-keybindings (Super+K), hypr-menu (menu ala Omarchy lewat rofi, Super+Alt+Space) |
| rofi | config.rasi + layout.rasi; warna dari noctalia.rasi (render Noctalia) |
| claude | skills & agents Claude Code (hyprland-config, noctalia-config, terminal-stack, dotfiles-stow) |

## Pasang di mesin baru

```sh
git clone git@github.com:suryakencana007/dotconfigfiles.git ~/dotconfigfiles
cd ~/dotconfigfiles
stow -t ~ zsh git alacritty tmux hypr noctalia nvim rofi
stow --no-folding -t ~ claude bin
```

Paket sistem yang dibutuhkan: zsh oh-my-zsh powerlevel10k ttf-meslo-nerd eza bat fd fzf zoxide git-delta
tmux neovim alacritty hyprland noctalia rofi hyprshot satty hyprpicker wl-clipboard xdg-desktop-portal-gtk udiskie.
