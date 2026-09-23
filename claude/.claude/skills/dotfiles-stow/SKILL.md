---
name: dotfiles-stow
description: Alur kerja repo dotfiles user (~/dotconfigfiles, GNU Stow, GitHub suryakencana007/dotconfigfiles). Pakai saat menambah/mengubah file config apa pun, menambah paket stow baru, atau commit dan push config.
---

# Dotfiles dengan GNU Stow

Repo: `~/dotconfigfiles` (remote `git@github.com:suryakencana007/dotconfigfiles.git`, branch `main`,
identitas git diset lokal di repo). Tiap folder tingkat pertama = satu paket stow yang meniru struktur `$HOME`.

| Paket | Isi | Cara stow |
|---|---|---|
| zsh | `.zshrc`, `.p10k.zsh` | file |
| git | `.gitconfig` | file |
| alacritty | `.config/alacritty/alacritty.toml` | file (folder `themes/` render tetap di luar) |
| tmux | `.config/tmux/tmux.conf` | file (folder `plugins/` TPM tetap di luar) |
| nvim | seluruh `.config/nvim` | folder (symlink folder utuh) |
| hypr, noctalia | `.config/hypr/*`, `.config/noctalia/*` | `--no-folding` (folder nyata, supaya overlay host dan file render Noctalia bisa masuk tanpa ke repo) |
| hosts/<hostname> | overlay khas mesin (lockscreen-widgets.toml, hypr/local.lua) | `--no-folding`, dari dir `hosts/`, otomatis oleh installer |
| claude | `.claude/skills/*`, `.claude/agents/*` | `--no-folding` (per file, karena `~/.claude` punya isi lain) |
| rofi | `.config/rofi/config.rasi`, `layout.rasi` (noctalia.rasi = render, ignored) | folder |
| bin | `.local/bin/*` skrip (hypr-keybindings, hypr-menu, rofi-toggle, resi-shell) | `--no-folding` (supaya `~/.local/bin` tetap folder nyata untuk pipx dll) |

## Installer: resi-shell

`install.sh` di root repo (= perintah `resi-shell`): `install [--dry-run]`, `update`, `doctor`, `packages`.
Daftar paket di `resi/packages.pacman` dan `resi/packages.aur`; greeter di `resi/greeter.toml`. Menambah paket
sistem baru = tambah barisnya di daftar itu. `resi-shell doctor` = audit cepat (stow, symlink, config, program).

## Aturan

1. Edit config lewat path di home (symlink) atau langsung di repo; sama saja.
2. File HASIL RENDER Noctalia: `nvim/.config/nvim/lua/noctalia.lua` dan `rofi/.config/rofi/noctalia.rasi` ada di dalam
   folder yang di-symlink utuh dan di-gitignore (jangan dihapus/dipindah); `~/.config/hypr/noctalia.lua` berada di luar
   repo karena hypr di-stow `--no-folding`.
3. Backup lama ada di `~/.config-backups/`, bukan di repo. Pola `*.bak` dan `*.bak.*` di-gitignore.
4. Menambah file ke paket yang sudah ada: taruh di repo, lalu `cd ~/dotconfigfiles && stow -t ~ <paket>`.
   Paket baru: buat `<paket>/<path seperti di home>`, pindahkan file asli ke sana (bukan copy), lalu stow.
   Kalau target di home sudah ada sebagai file biasa, stow menolak: pindahkan dulu.
5. Melepas paket: `stow -D -t ~ <paket>`. Cek symlink: `ls -la <path>`.
6. Setelah perubahan: verifikasi program yang memakainya (hyprctl reload/configerrors, noctalia msg
   config-reload, uji zsh/tmux/nvim), baru `git add -A && git commit` dengan pesan singkat, lalu `git push`.
   Commit hanya kalau user minta atau sudah jadi alur yang disepakati.
7. Jangan memasukkan rahasia: `.gitconfig` di repo sengaja tanpa identitas; identitas ada di config lokal repo.
