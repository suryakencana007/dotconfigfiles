---
name: noctalia-config
description: Cara mengatur Noctalia v5 (shell desktop native Wayland) di mesin ini, termasuk bar, panel, tema, template warna, IPC, polkit, greeter sync, dan log. Pakai saat user minta ubah bar/launcher/notifikasi/wallpaper/lock/idle atau tema yang menyebar ke aplikasi lain.
---

# Noctalia v5 di mesin ini

Paket `noctalia` (repo extra), dijalankan dari `autostart.lua` Hyprland. Bukan Quickshell (itu v4).

## Dua lapis config, yang GUI menang

File di `~/.config/noctalia/*.toml` adalah symlink per file ke repo dotfiles: edit dengan `sed -i --follow-symlinks`,
Python, atau path repo; `sed -i` biasa mengganti symlink dengan file biasa (perubahan tidak sampai ke repo).

- Tulisan tangan: `~/.config/noctalia/*.toml` (semua file .toml di folder itu digabung; symlink ke repo dotfiles).
  Yang ada: `bar.toml` (bar transparan), `shell.toml` (`corner_radius_scale = 0`, `polkit_agent = true`),
  `nvim.toml` (template user untuk Neovim).
- GUI/state: `~/.local/state/noctalia/settings.toml`. Ditulis Settings dan wizard. **Menang** atas file tulisan
  tangan untuk kunci yang sama. Kalau perubahan file "tidak berpengaruh", cek dulu file state ini.
- Terapkan perubahan file: `noctalia msg config-reload` (biasanya auto-reload juga).
- Menghapus override state (satu-satunya cara selain GUI, tidak ada IPC settings-set): backup dulu,
  `pkill -x noctalia`, hapus baris kunci itu di settings.toml, `setsid -f noctalia`, cek `noctalia config export`.
  Kunci yang wizard tulis ke state: `[shell] font_family` (dihapus 2026-09-23 agar `shell.toml` berlaku),
  `[bar.default]` capsule/padding/radius/thickness, `[theme]`, `[theme.templates] builtin_ids`.
- Sebelum reload: `noctalia config validate` (cek sintaks/kunci). Lihat hasil gabungan semua lapisan:
  `noctalia config export` (yang diset) atau `noctalia config export full` (termasuk default).
- Idle: mendefinisikan satu `[idle.behavior.<nama>]` sendiri mematikan seed bawaan (lock/screen-off/suspend);
  behavior lain harus ditulis eksplisit. Yang ada: `idle.toml` = lock 600 detik.
- Settings GUI: Super+Shift+, (koma) atau `noctalia msg settings-toggle`.

## IPC yang sering dipakai (`noctalia msg ...`)

`panel-toggle launcher|control-center [tab]|session|clipboard|wallpaper`, `settings-toggle`, `window-switcher`,
`session lock|logout|suspend|reboot|shutdown`, `bar-toggle|bar-show|bar-hide`, `volume-up|down|mute [n]`,
`mic-mute`, `brightness-up|down [target] [n]`, `media toggle|next|previous`, `notification-clear-active`,
`notification-dnd-toggle`, `notification-invoke-latest`, `nightlight-toggle`, `caffeine-toggle`,
`wallpaper-set <path>`, `wallpaper-random`, `wallpaper-get`, `greeter-sync`, `status`, `config-reload`.
Referensi lengkap: https://docs.noctalia.dev/noctalia/ipc/

## Tema dan template

Tema dibangkitkan dari wallpaper (`[theme] source = "wallpaper"`, skema m3-tonal-spot). Setiap tema berubah,
Noctalia merender template lalu menjalankan hook:

| Template | Output (JANGAN diedit, di-gitignore) | Efek |
|---|---|---|
| builtin alacritty | `~/.config/alacritty/themes/noctalia.toml` | diimpor `alacritty.toml` baris pertama |
| builtin hyprland | `~/.config/hypr/noctalia.lua` | warna border; `hyprland.lua` memanggil `require("noctalia").apply_theme()` |
| builtin btop/starship/... | aktif via `[theme.templates] builtin_ids` di state | hook gagal kalau app tidak ada (peringatan saja) |
| user `nvim_base16` | `~/.config/nvim/lua/noctalia.lua` dari `lua/noctalia-template.lua` | hook `pkill -SIGUSR1 nvim` |
| builtin `gtk3`, `gtk4` | `~/.config/gtk-{3,4}.0/noctalia.css` (+ `gtk.css` berisi @import) | hook `gtk/apply.sh`: gsettings color-scheme + gtk-theme adw-gtk3(-dark) bila terpasang. Aktif via GUI Settings > Templates (state `builtin_ids`). GTK3 butuh paket `adw-gtk-theme` agar warna masuk; mode gelap GTK3 butuh `gtk-application-prefer-dark-theme=1` di settings.ini (paket stow `gtk`). Ikon: `gsettings set org.gnome.desktop.interface icon-theme Papirus-Dark` |
| user `rofi` | `~/.config/rofi/noctalia.rasi` dari `~/.config/noctalia/templates/rofi.rasi` | rofi membaca saat start, tanpa hook |

Template hanya dirender ulang saat tema berubah, BUKAN saat config-reload atau wallpaper-set dengan gambar yang sama.
Memaksa render setelah mengedit template: `noctalia msg templates-apply` (render ulang semua template aktif tanpa
ganti mode dan tanpa hook shell). Palet: `color-scheme-get`, `color-scheme-set wallpaper m3-tonal-spot|m3-content|...`,
`color-scheme-set community <Nama>`, `color-scheme-set builtin Noctalia`; mode: `theme-mode-set dark|light|auto`.

Template user baru: tambah `[theme.templates.user.<nama>]` dengan `input_path`, `output_path`, `post_hook`
di file .toml mana pun di `~/.config/noctalia/`. Sintaks `{{colors.<token>.default.hex}}`; token Material 3
(primary, secondary, tertiary, error, surface*, on_*, outline) plus `terminal_*`. Referensi:
https://docs.noctalia.dev/noctalia/theming/templates/

Launcher: Super+Space = `hypr-menu` (menu ala Omarchy via rofi), Super+Alt+Space = `rofi -show drun`; tema rofi di
`~/.config/rofi/`. Launcher Noctalia tetap ada di ikon bar. Blur rofi lewat layer rule namespace `^rofi$` di looknfeel.lua.
Supaya program CLI ikut tema: pakai warna ANSI 0-15, bukan indeks 256 (sudah diterapkan di p10k, bat `ansi`, fzf `--color=16`, tmux).

## Lock screen (Super+Ctrl+L)

`lockscreen.toml`: `[lockscreen]` blurred_desktop/blur_intensity/tint_intensity, dan `[lockscreen_widgets]`
(tidak ada di docs tapi dikenal validator; ditulis di file setelah blok yang sama dihapus dari state).
Login box: `cx/cy` (pusat), `box_width`, `settings.layout = "regular" | "compact"` (BUKAN "minimal",
validator menolak), `background_opacity`, `show_unlock_hint`, `show_*`. Nilai enum yang tidak yakin:
uji dengan `noctalia config validate`, yang menyebut "not one of the allowed values" tanpa mendaftar pilihannya.
Editor visual `noctalia msg lockscreen-widgets-edit` menulis ke state (menang atas file).

## Screenshot & rekam layar

`screenshot.toml` = `[shell.screenshot]` (directory ~/Pictures/Screenshots, freeze_screen, annotate, copy_to_clipboard).
IPC: `screenshot-region`, `screenshot-fullscreen [pick|<output>]`; belum ada mode window (hyprshot dipakai untuk itu).
Rekam: skrip `hypr-record` (bin) = toggle gpu-screen-recorder (AUR, parameter ala Omarchy: -k auto -f 60 -fm cfr
-fallback-cpu-encoding yes -a default_output -ac aac; region WxH+X+Y dari slurp), cadangan wl-screenrec/wf-recorder.
Output ~/Videos/screenrecording-*.mp4, log ~/.cache/hypr-record.log, notifikasi `notification-show`; `hypr-record status`.
Indikator bar: saat merekam skrip menulis `~/.config/noctalia/zz-recording.toml` (override lajur `end` + widget
`rec` custom_button merah, klik = berhenti) lalu config-reload; dihapus saat selesai. `hypr-record indicator on|off`
untuk uji tampilan. File runtime ini di luar repo. Catatan: pgrep -x gagal untuk nama proses >15 huruf.

## Theme switcher

`hypr-theme-carousel` (Python GTK4/libadwaita, Super+Shift+Ctrl+Space): carousel wallpaper geser ala omarchy-shell,
kartu tengah = pilihan, Enter -> `wallpaper-set`. `hypr-theme` (rofi, menu Style): galeri wallpaper (thumbnail vipsthumbnail di
`~/.cache/hypr-theme/thumbs`, `wallpaper-set`), daftar palet (`color-scheme-set`), toggle mode. Plugin Wallhaven: widget
`wallhaven` di bar + `panel-toggle noctalia/wallhaven:browser` (Super+Ctrl+Alt+Space); API key hanya via GUI (state).

## Greeter

`noctalia-greeter` (AUR) lewat greetd. Sync butuh polkit: agen Noctalia aktif (`polkit_agent = true`), dan rule
tanpa password sudah dipasang (`sudo noctalia-greeter passwordless-sync enable $USER`). Auto-sync aktif
di state. Manual: `noctalia msg greeter-sync`; hasil di log "synced shell appearance to greeter".

## Diagnosa

Log: `~/.cache/noctalia/noctalia.log` (`grep -vE '\[DBG\]'`). Status: `noctalia msg status`.
Layer di Hyprland: `hyprctl layers | grep noctalia`. Restart: `pkill noctalia; setsid -f noctalia`.
