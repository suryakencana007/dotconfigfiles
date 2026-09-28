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
  `greeter.toml` (auto-sync greeter), `nvim.toml` (template user untuk Neovim), `control-center.toml` (control center
  lebar 760, kartu event kalender mati, dan `[shell.panel]` control center/session/wallpaper `floating`, offset 10),
  `notifications.toml` (`[notification]` kaca 0.78, offset 10/10, `max_visible = 3`, filter `spotify` tanpa toast/riwayat;
  `[osd]` kaca 0.78, offset_y 10; offset = jarak dari tepi layar, toast otomatis mulai di bawah area bar; max_visible
  menyingkirkan toast TERLAMA dari layar, bukan menahan yang baru; riwayat: `~/.local/state/noctalia/notification_history.json`,
  bersihkan notifikasi uji dengan `noctalia msg notification-clear-history` setelah memastikan isinya hanya uji),
  `shell.toml` juga memuat `date_format` dan `[location] address = "Jakarta"` (cuaca + jadwal night light).
  Tabel yang sama di beberapa file (mis. `[shell.panel]` di launcher.toml dan control-center.toml) DIGABUNG per kunci;
  array tabel (`[[bar.default.capsule_group]]`) justru DIGANTI utuh oleh file yang dimuat belakangan.
  JANGAN kembalikan panel ke `attached` selama `transparency_mode = "glass"`: panel attached tampil tembus tanpa blur
  (teks jendela di belakang terbaca), panel floating diblur layer rule Hyprland.
- GUI/state: `~/.local/state/noctalia/settings.toml`. Ditulis Settings dan wizard. **Menang** atas file tulisan
  tangan untuk kunci yang sama. Kalau perubahan file "tidak berpengaruh", cek dulu file state ini.
- Terapkan perubahan file: `noctalia msg config-reload` (biasanya auto-reload juga).
- Menghapus override state (satu-satunya cara selain GUI, tidak ada IPC settings-set): backup dulu,
  `pkill -x noctalia`, hapus baris kunci itu di settings.toml, `setsid -f noctalia`, cek `noctalia config export`.
  Kunci yang wizard tulis ke state: `[shell] font_family` (dihapus 2026-09-23 agar `shell.toml` berlaku),
  `[bar.default]` capsule/padding/radius/thickness, `[theme]`, `[theme.templates] builtin_ids`, dan `[lockscreen_widgets]`
  (dihapus dari state di dynarch 2026-09-24 supaya overlay host dan `templates.toml` berlaku; kalau wizard/GUI menulisnya
  lagi, overlay lock screen dan daftar template dari repo ikut tertimpa).
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

`templates.toml` (repo) menyetel `[theme.templates] builtin_ids` untuk mesin baru; kalau state (wizard/GUI) punya
kunci yang sama, state menang (list tidak digabung). Gejala template tidak aktif: border Hyprland/alacritty/GTK tidak
ikut ganti warna saat wallpaper diganti -> cek Settings > Templates atau `noctalia config export | grep builtin_ids`.
Template hanya dirender ulang saat tema berubah, BUKAN saat config-reload atau wallpaper-set dengan gambar yang sama.
Memaksa render setelah mengedit template: `noctalia msg templates-apply` (render ulang semua template aktif tanpa
ganti mode dan tanpa hook shell). Palet: `color-scheme-get`, `color-scheme-set wallpaper m3-tonal-spot|m3-content|...`,
`color-scheme-set community <Nama>`, `color-scheme-set builtin Noctalia`; mode: `theme-mode-set dark|light|auto`.

Template user baru: tambah `[theme.templates.user.<nama>]` dengan `input_path`, `output_path`, `post_hook`
di file .toml mana pun di `~/.config/noctalia/`. Sintaks `{{colors.<token>.default.hex}}`; token Material 3
(primary, secondary, tertiary, error, surface*, on_*, outline) plus `terminal_*`. Referensi:
https://docs.noctalia.dev/noctalia/theming/templates/

Launcher Noctalia (ikon di bar, `launcher.toml`): `categories = false`, `list_item_background = false`, `transparency_mode = "glass"`
(berlaku untuk semua panel melayang), `pinned = [ "Alacritty", "brave-browser", ... ]` dengan ID desktop TANPA `.desktop`
(dengan akhiran pin diam-diam tidak berefek; app yang tidak terpasang dilewati tanpa error). Entri sampah disembunyikan
lewat override `NoDisplay=true` di paket bin (`~/.local/share/applications/<id>.desktop`). Indeks app Noctalia bisa
melewatkan file .desktop yang baru dibuat (2026-09-27: rofi.desktop tetap tampil): setelah menambah override jalankan
`hypr-restart-shell`. Uji pencarian tanpa mengetik: `noctalia msg panel-open launcher "<kata>"` lalu screenshot.
Launcher: Super+Space = `hypr-menu` (menu ala Omarchy via rofi; submenu Install > Package/AUR dan Remove > Package = `hypr-tui --class hypr-pkg-install hypr-pkg-install repo|aur|remove` (fzf + pratinjau pacman/yay, rule float 1000x800 di windows.lua), Update > Resi shell = `hypr-tui resi-shell update`, Update > Firmware = `hypr-tui hypr-update-firmware` (fwupd, dipasang saat pertama dipakai), Install > Development dan Remove > Development = daftar bahasa yang sama (`dev_items install|remove`; remove hanya menampilkan yang terpasang, grup hanya bila ada anggotanya, placeholder "Nothing installed yet" beraksi back) -> `hypr-tui hypr-dev-env install|remove <env>` (mise, dipasang saat pertama dipakai; ✓ = terpasang via `hypr-dev-env installed`); Remove > AUR = `hypr-pkg-install remove-aur` (pacman -Qqm), Install/Remove > Development > Docker DB = `hypr-docker-db install|remove` (fzf multi; engine Podman rootless ditawarkan saat pertama dipakai, Docker dipakai bila sudah ada; `installed` untuk syarat tampil di Remove), Install > Web App = `hypr-tui hypr-webapp install` (launcher .desktop dengan Exec `hypr-webapp launch URL` = browser default --app; ikon di ~/.local/share/icons/hicolor/256x256/apps), Remove > Web App hanya bila `hypr-webapp list` tidak kosong, Setup > Containers = `hypr-containers` di TUI.large (podman-tui, AUR, ditawarkan saat pertama dipakai), Setup > Power profile = `hypr-power profile <p>` (diingat per ac/battery di ~/.local/state/resi/power/profile-<src>; ✓ = aktif), Setup > Monitors = `hypr-monitors` (nwg-displays, -m/-w ke nwg-*.conf/.lua; tawarkan install bila belum ada), Update > Process > Shell = `hypr-tui hypr-restart-shell` (kill noctalia lalu exec ulang lewat hyprctl; menolak bila `noctalia msg status` .locked) (konfirmasi tombol horizontal Yes/No murni bash, log ~/.cache/resi-shell-update.log; semua teks ke pengguna wajib bahasa Inggris). `hypr-tui` = terminal mengambang TUI.float + prompt "Done, press any key" ala omarchy-show-done, plus `--confirm "Q?"` (tombol Yes/No horizontal) dan `--box baris...`; Remove memakai keduanya sebelum pacman -Rns. BackSpace di submenu saat filter kosong = Back; entri beraksi `menu:*` otomatis diberi 󰅂 rata kanan oleh `menu()`, jadi aksi launcher jangan memakai prefix menu:), Super+Alt+Space = `rofi -show drun`; tema rofi di
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
`rec` custom_button merah, klik = berhenti) lalu config-reload; dihapus saat selesai. `hypr-record indicator on|off`. Indikator update paket: `hypr-updates` menulis `~/.config/noctalia/zy-updates.toml` (custom_button "updates", glyph package, label = jumlah) dengan pola lane `end` yang sama; nama `zy-` sengaja sebelum `zz-recording` supaya REC yang sementara menang saat keduanya ada
untuk uji tampilan. File runtime ini di luar repo. Catatan: pgrep -x gagal untuk nama proses >15 huruf.

Template user `folder_color` (`folder-color.toml`): render `{{colors.primary.default.hex}}` ke
`~/.cache/resi/folder-color-primary.txt`, post_hook `hypr-folder-color apply` memilih varian folder Papirus terdekat
(rona diutamakan; `hypr-folder-color pick #hex` untuk cek) dan membangun `~/.local/share/icons/Papirus-Dark-Resi`
(symlink ikon folder ke varian warna itu, mewarisi Papirus-Dark), lalu gsettings icon-theme. Diuji: wallpaper merah
-> pink dalam 5 dtk. `templates-apply` merender tanpa hook: jalankan `hypr-folder-color apply` manual setelahnya.
Night light: `[nightlight] enabled = true` di shell.toml, jadwal dari `[location]` (log `[gamma] target ...K`).

## Theme switcher

`hypr-theme-carousel` (Python GTK4/libadwaita, Super+Shift+Ctrl+Space): carousel wallpaper geser ala omarchy-shell,
kartu tengah = pilihan, Enter -> `wallpaper-set`. `hypr-theme` (rofi, menu Style): galeri wallpaper (thumbnail vipsthumbnail di
`~/.cache/hypr-theme/thumbs`, `wallpaper-set`), daftar palet (`color-scheme-set`), toggle mode. Plugin Wallhaven:
`panel-toggle noctalia/wallhaven:browser` (Super+Ctrl+Alt+Space); widget bar-nya sengaja dilepas (2026-09-27), panel
plugin tetap bisa dibuka tanpa widget. API key hanya via GUI (state).

## Bar (bar.toml)

Island, sudut kotak (`capsule_radius`/grup `radius` = 4), kaca: kapsul `opacity 0.78` harus di atas `ignore_alpha 0.5`
layer rule Hyprland (looknfeel.lua), kalau pekat blur tidak terlihat. Geometri grid 10 px = gaps_out Hyprland:
`thickness 30`, `capsule_thickness 1.0`, `margin_edge 10`, `margin_ends 0`, `padding 10`. `[[capsule_group]]` TIDAK
mewarisi `capsule_*` dari `[bar.default]`: opacity/border/radius/padding ditulis per grup. Array `capsule_group` di file
yang dimuat belakangan menggantikan seluruh array (bukan digabung per id), jadi override uji (`zz-*.toml`) harus memuat
semua grup. Kunci widget yang dipakai: media `hide_when_no_media`, network/volume/brightness `show_label = false`,
workspaces `labels_only_when_occupied`, clock `format`/`tooltip_format`. Role warna `outline_variant` DITOLAK validator
5.1 untuk `capsule_border`; `outline` diterima. Referensi kunci: repo noctalia-dev/noctalia `docs/user/bar/` (URL
docs.noctalia.dev untuk bar/widgets 404). Cek hasil: `grim -g "0,0 1920x64" bar.png`.

## Greeter

`noctalia-greeter` (AUR) lewat greetd. Sync butuh polkit: agen Noctalia aktif (`polkit_agent = true`), dan rule
tanpa password sudah dipasang (`sudo noctalia-greeter passwordless-sync enable $USER`, rule di
`/etc/polkit-1/rules.d/49-noctalia-greeter-sync.rules`, folder itu root-only: cek status pakai sudo).
Auto-sync: `[shell.greeter_sync] auto_sync = true` di `greeter.toml` (repo; sebelumnya hanya via GUI dan default false).
Auto-sync hanya terpicu saat wallpaper/palet/mode/font berubah, jadi mesin baru tetap tampil bawaan sampai sync
pertama: `noctalia msg greeter-sync` (installer melakukannya). Hasil di log "[greeter-sync] synced shell appearance
to greeter" dan jurnal `pkexec ... noctalia-greeter-apply-appearance --sync /run/user/<uid>/noctalia-greeter-sync`
(staging bisa dibaca user: sync.toml + wallpaper). Yang disinkron: wallpaper per output, palet, mode, font, radius,
layout/scale monitor -> `/var/lib/noctalia-greeter/sync.toml` (root-only). `greeter.toml` (dari `resi/greeter.toml`,
`scheme = "Synced"`) selalu menang atas sync.toml.

## Diagnosa

Log: `~/.cache/noctalia/noctalia.log` (`grep -vE '\[DBG\]'`). Status: `noctalia msg status`.
Layer di Hyprland: `hyprctl layers | grep noctalia`. Restart: `pkill noctalia; setsid -f noctalia`.
