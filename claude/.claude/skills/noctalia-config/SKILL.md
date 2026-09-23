---
name: noctalia-config
description: Cara mengatur Noctalia v5 (shell desktop native Wayland) di mesin ini, termasuk bar, panel, tema, template warna, IPC, polkit, greeter sync, dan log. Pakai saat user minta ubah bar/launcher/notifikasi/wallpaper/lock/idle atau tema yang menyebar ke aplikasi lain.
---

# Noctalia v5 di mesin ini

Paket `noctalia` (repo extra), dijalankan dari `autostart.lua` Hyprland. Bukan Quickshell (itu v4).

## Dua lapis config, yang GUI menang

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
| user `rofi` | `~/.config/rofi/noctalia.rasi` dari `~/.config/noctalia/templates/rofi.rasi` | rofi membaca saat start, tanpa hook |

Template hanya dirender ulang saat tema berubah, BUKAN saat config-reload atau wallpaper-set dengan gambar yang sama.
Memaksa render setelah mengedit template: `noctalia msg theme-mode-set light` lalu `theme-mode-set dark` (semua
template + greeter sync ikut jalan dua kali; tema berkedip sebentar).

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

## Greeter

`noctalia-greeter` (AUR) lewat greetd. Sync butuh polkit: agen Noctalia aktif (`polkit_agent = true`), dan rule
tanpa password sudah dipasang (`sudo noctalia-greeter passwordless-sync enable surya-legion`). Auto-sync aktif
di state. Manual: `noctalia msg greeter-sync`; hasil di log "synced shell appearance to greeter".

## Diagnosa

Log: `~/.cache/noctalia/noctalia.log` (`grep -vE '\[DBG\]'`). Status: `noctalia msg status`.
Layer di Hyprland: `hyprctl layers | grep noctalia`. Restart: `pkill noctalia; setsid -f noctalia`.
