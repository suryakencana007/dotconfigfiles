---
name: hyprland-config
description: Cara mengubah config Hyprland (Lua) di mesin ini, gaya Omarchy dengan shell Noctalia. Pakai saat user minta ubah keybinding, window rule, tampilan (gaps, border, blur, animasi), input, monitor, autostart, atau scratchpad di Hyprland.
---

# Hyprland (Lua) di mesin ini

Hyprland 0.56+ membaca `~/.config/hypr/hyprland.lua` (Lua native, bukan hyprland.conf). Folder itu symlink ke
`~/dotconfigfiles/hypr/.config/hypr` (lihat skill dotfiles-stow). Strukturnya meniru Omarchy:

| File | Isi |
|---|---|
| `hyprland.lua` | pemuat: set `package.path`, hapus cache modul `hypr.*` dan `noctalia`, `require` semua modul |
| `helpers.lua` | `o.bind(keys, desc, cmd|dispatcher|function, opts)`, `o.rebind`, `o.window(match, rules)`, `o.cmd_present`, `o.exec_on_start` |
| `looknfeel.lua` | gaps 5/10, border 2, rounding 0, blur 8/3, shadow, animasi Omarchy, dwindle, misc, layer rule blur Noctalia |
| `input.lua` | keyboard us, repeat 40/250, numlock, touchpad clickfinger, gesture 3 jari |
| `monitors.lua` | `hl.monitor` auto, workspace 1-5 persistent |
| `windows.lua` | suppress maximize, tag `default-opacity` (0.985/0.96), tag `floating-window`, tag `terminal`, rule dialog portal, media tanpa opacity |
| `qconsole.lua` | scratchpad ala Quake console (disalin dari Omarchy), Super+` |
| `autostart.lua` | import env ke systemd/dbus, `noctalia`, `udiskie` |
| `bindings/tiling.lua` | fokus/swap/workspace/resize/group, semua `hl.dsp.*` |
| `bindings/apps.lua` | alacritty, brave, thunar, nvim, btop, web app brave `--app=`, Super+Alt+Space = `rofi -show drun` (Apps) |
| `bindings/noctalia.lua` | semua yang lewat `noctalia msg ...` (control center, session, clipboard, lock, notifikasi, toggle), Super+Shift+Ctrl+Space = `hypr-theme-carousel --toggle` (carousel GTK4, class `hypr-theme-carousel` dengan rule float/center/pin/dim_around di windows.lua; palet/mode lewat `hypr-theme` di menu Style), Super+Ctrl+Alt+Space = panel Wallhaven. Super+Space = `hypr-menu` (menu ala Omarchy via rofi; launcher Noctalia tidak diikat tombol, ada di ikon bar) |
| `bindings/media.lua` | tombol XF86 volume/brightness/media lewat `noctalia msg` |
| `bindings/clipboard.lua` | Super+C/V/X/A universal (disalin dari Omarchy, butuh tag `terminal`) |
| `bindings/utilities.lua` | screenshot hyprshot/satty, hyprpicker, zoom, Super+K = `hypr-keybindings` (skrip di paket bin, format ala Omarchy; `--print` untuk cek di terminal) |
| `noctalia.lua` | **HASIL RENDER Noctalia** (warna border dari tema). Jangan diedit, jangan dipindah, sudah di-gitignore |

## Aturan kerja

0. File di `~/.config/hypr/` adalah symlink per file ke `~/dotconfigfiles/hypr/...`: edit dengan
   `sed -i --follow-symlinks`, Python, atau langsung path repo. `sed -i` biasa mengganti symlink dengan file biasa.

1. Edit modul yang relevan, bukan `hyprland.lua`, kecuali menambah modul baru.
2. Binding baru: `o.bind("SUPER + SHIFT + X", "Deskripsi", "perintah")`. Ganti binding yang ada: `o.rebind(...)`
   dan beri tahu user apa yang tergantikan. Cek dulu: `hyprctl binds -j | python3 -c '...'` atau `hyprctl binds | grep -i <key>`.
3. Nama tombol: angka pakai `code:10`..`code:19` (1..0), minus/equal `code:20`/`code:21`, koma `comma`, backtick `grave`.
4. Window rule: pakai `o.window("class-regex", { rules })` atau `o.window({ class=, title=, tag= }, {...})`.
   Sintaks rule sering berubah antar versi; kalau ragu cek https://wiki.hypr.land/Configuring/Basics/Window-Rules/
   atau contoh di `windows.lua`.
5. Setelah SETIAP perubahan wajib validasi:
   ```
   luac5.4 -p <file>            # sintaks
   hyprctl reload && hyprctl configerrors   # harus kosong
   ```
   Kalau configerrors berisi error, perbaiki sampai bersih. Hyprland juga auto-reload saat file disimpan.
6. Tombol yang sudah dipakai rofi, Noctalia dan tmux: Super+Space, Super+Alt+Space (rofi), Super+S, Super+Esc, Alt+Tab (Noctalia); Alt+Enter,
   Alt+panah, Alt+angka, Ctrl+Alt+panah (tmux, tanpa prefix). Jangan bentrok.
7. Baris `pcall(function() require("noctalia").apply_theme() end)` di akhir `hyprland.lua` harus tetap mengandung
   teks `require("noctalia")`, karena hook template Noctalia mencarinya.
8. Dispatcher yang terbukti ada di 0.56: `hl.dsp.focus({ workspace = "N" | direction = "l" | monitor = "+1" })`,
   `hl.dsp.window.move({ workspace = "N", follow = false })`, `hl.dsp.window.close()`, `hl.dsp.exec_cmd("cmd")`.
   Tidak ada `hl.dsp.workspace.go`. Window rule ke workspace: `o.window("^Class$", { workspace = "5" })`,
   tambah ` silent` untuk tanpa pindah fokus. Cek class jendela: `hyprctl clients -j`.
   Rule `size`/`float`/`center` dievaluasi saat jendela pertama muncul: cocokkan lewat `class` (beri app
   `--class` sendiri), bukan `title`, karena judul belum terbaca saat itu. Contoh: jendela Super+K
   memakai class `hypr-keybindings` dengan rule sendiri agar tidak ditimpa ukuran tag `floating-window`.
   Pola toggle panel (buka/tutup dengan satu tombol): skrip mencari jendela via
   `hyprctl clients -j | jq '.[] | select(.class == "X") | .pid'` lalu `kill $pid`, kalau tidak ada baru launch.
   JANGAN `pkill -f <teks>`: mencocokkan baris perintah proses apa pun, termasuk shell yang sedang menguji.
9. Perubahan `autostart.lua` hanya berlaku saat Hyprland start, bukan saat reload. Untuk menjalankan sekarang (mode Lua, bukan `dispatch exec`): `hyprctl dispatch 'hl.dsp.exec_cmd("<cmd>")'`.

## Hal yang sengaja berbeda dari Omarchy

Tidak ada skrip `omarchy-*`, tidak ada uwsm (sesi lewat greetd), Caps Lock bukan compose key, blur aktif,
Super+S untuk control center Noctalia (scratchpad hanya Super+`), Alt+Tab window switcher Noctalia.
