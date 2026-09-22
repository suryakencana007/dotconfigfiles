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

Template user baru: tambah `[theme.templates.user.<nama>]` dengan `input_path`, `output_path`, `post_hook`
di file .toml mana pun di `~/.config/noctalia/`. Sintaks `{{colors.<token>.default.hex}}`; token Material 3
(primary, secondary, tertiary, error, surface*, on_*, outline) plus `terminal_*`. Referensi:
https://docs.noctalia.dev/noctalia/theming/templates/

Supaya program CLI ikut tema: pakai warna ANSI 0-15, bukan indeks 256 (sudah diterapkan di p10k, bat `ansi`, fzf `--color=16`, tmux).

## Greeter

`noctalia-greeter` (AUR) lewat greetd. Sync butuh polkit: agen Noctalia aktif (`polkit_agent = true`), dan rule
tanpa password sudah dipasang (`sudo noctalia-greeter passwordless-sync enable surya-legion`). Auto-sync aktif
di state. Manual: `noctalia msg greeter-sync`; hasil di log "synced shell appearance to greeter".

## Diagnosa

Log: `~/.cache/noctalia/noctalia.log` (`grep -vE '\[DBG\]'`). Status: `noctalia msg status`.
Layer di Hyprland: `hyprctl layers | grep noctalia`. Restart: `pkill noctalia; setsid -f noctalia`.
