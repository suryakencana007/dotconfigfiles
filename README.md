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

## Pasang di mesin baru: resi-shell

Setelah Arch dasar terpasang (user dengan sudo, internet):

```sh
git clone git@github.com:suryakencana007/dotconfigfiles.git ~/dotconfigfiles
~/dotconfigfiles/install.sh            # atau: install.sh --dry-run untuk melihat rencananya
```

Installer idempotent (aman diulang): paket repo (`resi/packages.pacman`), yay + AUR (`resi/packages.aur`),
driver GPU sesuai hardware (NVIDIA open + early KMS / AMD / Intel), zsh + oh-my-zsh + p10k + fzf-tab, stow semua
paket, TPM, plugin nvim, greetd + noctalia-greeter (`resi/greeter.toml`) + passwordless sync, folder, identitas git.
Setelah terpasang, perintah `resi-shell install|update|doctor|packages` tersedia (paket bin).

Yang manual: reboot, wizard Noctalia (wallpaper, tema, Auto-Sync Greeter), kunci SSH GitHub, login Brave/Spotify,
BIOS mode GPU hybrid.

### Per mesin: `hosts/<hostname>/`

Overlay stow (`--no-folding`) yang dipasang otomatis kalau namanya = `/etc/hostname`. Isinya hanya yang khas mesin:
`hosts/legionarch/.config/noctalia/lockscreen-widgets.toml` (layout kotak login untuk panel eDP-2) dan
`hosts/legionarch/.config/hypr/local.lua` (override Hyprland, dimuat terakhir). Mesin baru: salin folder ini dengan
nama hostnamenya lalu sesuaikan.

Manual tanpa installer:

```sh
cd ~/dotconfigfiles
stow -t ~ zsh git alacritty tmux nvim rofi
stow --no-folding -t ~ hypr noctalia claude bin
(cd hosts && stow --no-folding -t ~ "$(cat /etc/hostname)")
```

Paket sistem yang dibutuhkan: zsh oh-my-zsh powerlevel10k ttf-meslo-nerd eza bat fd fzf zoxide git-delta
tmux neovim alacritty hyprland noctalia rofi hyprshot satty hyprpicker wl-clipboard xdg-desktop-portal-gtk udiskie.
