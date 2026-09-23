---
name: terminal-stack
description: Peta stack terminal user (zsh + oh-my-zsh + powerlevel10k, alacritty, tmux, neovim LazyVim, tool CLI modern) dan cara mengubah atau memverifikasinya. Pakai saat user minta ubah prompt, alias, keybinding tmux, font/opacity alacritty, plugin atau tema nvim.
---

# Stack terminal di mesin ini (Arch)

Semua file di bawah adalah symlink ke `~/dotconfigfiles` (skill dotfiles-stow).

## zsh
- `~/.zshrc`: oh-my-zsh, tema powerlevel10k, plugin git, sudo (Esc Esc), extract, fzf-tab, zsh-autosuggestions,
  zsh-syntax-highlighting (dua terakhir symlink dari paket pacman ke `~/.oh-my-zsh/custom/plugins`).
  fzf (Ctrl+R/T, Alt+C, `--color=16`), zoxide (`--cmd cd`), eza (alias ls/ll/la/lt), bat (`cat` = `bat -pp`,
  `BAT_THEME=ansi`, MANPAGER), alias `t` (tmux main), `reload`.
- `~/.p10k.zsh`: lean, satu baris, transient prompt, `nerdfont-v3`, warna ANSI 0-15 supaya ikut tema terminal.
  Ganti gaya: `p10k configure` (akan menimpa warna ANSI itu).
- Uji tanpa mengganggu: `script -qec "zsh -ic 'alias ls; exit'" /dev/null`. Startup normal ~80 ms.

## alacritty
`~/.config/alacritty/alacritty.toml`: baris pertama `[general] import` tema Noctalia; font MesloLGS Nerd Font Mono;
`[terminal] shell = /usr/bin/zsh` (sesi lama masih SHELL=bash); `[window] opacity 0.8, padding 12/10`.
Live reload saat file disimpan. Validasi: `python3 -c "import tomllib; tomllib.load(open(f,'rb'))"`.

## tmux
`~/.config/tmux/tmux.conf` (gaya Omarchy): prefix Ctrl+Space (Ctrl+b cadangan), Alt+Enter split, Alt+angka
window, Ctrl+Alt+panah pane, status bar atas dengan warna palet terminal. TPM di `~/.config/tmux/plugins`
(resurrect + continuum, autosave 15 menit). Uji: `tmux -L cektest -f ~/.config/tmux/tmux.conf new -d && tmux -L cektest kill-server`.
`~/.tmux.conf` sengaja TIDAK ada (kalau ada, tmux mengabaikan file XDG).

## neovim
LazyVim (config asal Omarchy) di `~/.config/nvim`. Tema: `lua/plugins/theme.lua` memakai RRethy/base16-nvim
dengan warna dari `lua/noctalia.lua` (render Noctalia, jangan edit; template di `lua/noctalia-template.lua`).
SIGUSR1 dari Noctalia memicu ganti warna live. `plugin/after/transparency.lua` menghapus bg.
Semua tema lain ada di `lua/plugins/all-themes.lua` (lazy). Uji headless:
`nvim --headless "+lua vim.schedule(function() print(vim.g.colors_name); vim.cmd('messages'); vim.cmd('qa!') end)"`.
`lazy-lock.json` lokal per mesin (tidak di repo). Plugin hilang: `nvim --headless "+Lazy! install" +qa` dengan `GIT_TERMINAL_PROMPT=0`.

## mpv
`~/.config/mpv/mpv.conf`: vo=gpu-next, `gpu-api=opengl` (EGL = GPU compositor/AMD; Vulkan hanya melihat NVIDIA tanpa
vulkan-radeon), `hwdec=vaapi` (auto-safe memilih vulkan-copy di NVIDIA). Default player via `xdg-mime default mpv.desktop`
untuk video/* dan audio/*. Uji decode: `mpv --length=2 --really-quiet --msg-level=vd=v <file> 2>&1 | grep "hardware decoding"`.

## Sistem
- sudo butuh password dan Claude Code tidak punya TTY: berikan perintah `sudo pacman -S ...` untuk dijalankan
  user di alacritty, lalu verifikasi dengan `pacman -Q`. AUR lewat `yay`/`paru`.
- Sesi desktop login sebelum `chsh`, jadi `$SHELL` masih bash sampai re-login; alacritty dipaksa zsh.
- `man` (man-db) terpasang; `hostname` tidak (paket inetutils), tidak masalah.
