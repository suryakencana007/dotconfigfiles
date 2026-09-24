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
| alacritty | `.config/alacritty/alacritty.toml` | stow biasa, hasilnya TERGANTUNG MESIN: kalau `~/.config/alacritty` sudah ada sebelum stow -> symlink per file, `themes/` render di home (legionarch); kalau belum -> dilipat jadi symlink folder, `themes/` ada di dalam folder repo, di-gitignore (dynarch). Cek: `ls -ld ~/.config/alacritty` |
| tmux | `.config/tmux/tmux.conf` | sama seperti alacritty: per file (folder sudah ada) atau symlink folder dengan `plugins/` TPM di dalam folder repo, di-gitignore (dynarch) |
| nvim | seluruh `.config/nvim` | folder (symlink folder utuh) |
| mpv | `.config/mpv/{mpv.conf,input.conf}` | folder |
| hypr, noctalia | `.config/hypr/*`, `.config/noctalia/*` | `--no-folding` (folder nyata, supaya overlay host dan file render Noctalia bisa masuk tanpa ke repo) |
| hosts/<hostname> | overlay khas mesin (lockscreen-widgets.toml, hypr/local.lua) | `--no-folding`, dari dir `hosts/`, otomatis oleh installer |
| claude | `.claude/skills/*`, `.claude/agents/*` | `--no-folding` (per file, karena `~/.claude` punya isi lain) |
| rofi | `.config/rofi/config.rasi`, `layout.rasi` (noctalia.rasi = render, ignored) | folder |
| gtk | `.config/gtk-3.0/settings.ini`, `.config/gtk-4.0/settings.ini` (render noctalia.css/gtk.css tinggal di ~/.config, di luar repo) | `--no-folding` |
| bin | `.local/share/applications/nwg-displays.desktop` (override entri launcher -> hypr-monitors) + `.local/bin/*` skrip (hypr-keybindings, hypr-menu, hypr-theme, hypr-theme-carousel, hypr-record, hypr-pkg-install, hypr-tui, hypr-update-firmware, hypr-restart-shell, hypr-monitors, hypr-clamshell, hypr-lid-close, hypr-power, hypr-dev-env, hypr-updates, rofi-toggle, resi-shell) | `--no-folding` (supaya `~/.local/bin` tetap folder nyata untuk pipx dll) |

## Installer: resi-shell

`install.sh` di root repo (= perintah `resi-shell`): `install [--dry-run]`, `update`, `doctor`, `packages`.
Daftar paket di `resi/packages.pacman` dan `resi/packages.aur`; greeter di `resi/greeter.toml`. Menambah paket
sistem baru = tambah barisnya di daftar itu. `resi-shell doctor` = audit cepat (stow, symlink, config, program).

## Aturan

0. JANGAN `sed -i` langsung pada path di home yang berupa symlink per file (paket `--no-folding`: hypr, noctalia,
   gtk, claude, bin): sed -i menulis file baru dan MENGGANTI symlink dengan file biasa, sehingga perubahan tidak
   sampai ke repo (terjadi 2026-09-23 pada bindings/noctalia.lua). Pakai `sed -i --follow-symlinks`, edit path di
   repo (`~/dotconfigfiles/...`), atau Python open/write (mengikuti symlink). Setelah mengedit, `resi-shell doctor`
   mendeteksi ini sebagai konflik stow ("cannot stow ... over existing target").

1. Edit config lewat path di home (symlink) atau langsung di repo; sama saja.
2. `nvim/.config/nvim/lazy-lock.json` TIDAK dilacak (gitignore): lazy.nvim menulis ulang per mesin, melacaknya membuat
   konflik pull antar mesin (terjadi 2026-09-24). Jangan `git add -f` file itu.
3. File HASIL RENDER Noctalia: `nvim/.config/nvim/lua/noctalia.lua` dan `rofi/.config/rofi/noctalia.rasi` ada di dalam
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
8. Paket yang terlipat (nvim, rofi, mpv; alacritty dan tmux di mesin yang melipat): file di dalamnya terlihat sebagai FILE BIASA lewat symlink
   folder, padahal itu file repo. Jangan pernah `mv`/hapus "file biasa" di path home tanpa cek `realpath` dulu:
   2026-09-24 installer lama memindahkan `tmux.conf` dan `alacritty.toml` ke `.pre-resi` di dalam repo saat dijalankan
   ulang (tmux jalan tanpa config, alacritty ditulis ulang Noctalia). Installer sekarang punya guard `in_repo`, dan
   `resi-shell doctor` memeriksa file kunci ada dan mengarah ke repo, serta baris `require("noctalia")` di hyprland.lua.
