-- Proses saat Hyprland mulai (hanya saat start, bukan saat reload).
hl.on("hyprland.start", function()
  -- Supaya service user systemd & D-Bus tahu variabel sesi Wayland (portal, app launch cepat).
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  -- Shell desktop: bar, launcher, notifikasi, lock, idle, wallpaper, OSD, polkit agent.
  hl.exec_cmd("noctalia")

  -- Kait lock screen: loginctl lock-session -> hyprlock, dan kunci sebelum suspend (hypridle.conf; waktu idle oleh Noctalia).
  if o.cmd_present("hypridle") then
    hl.exec_cmd("hypridle")
  end

  -- Mode baterai otomatis: power-saver + brightness dibatasi saat charger dicabut (hypr-power).
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/hypr-power watch")
  -- Indikator update paket di bar: cek repo + AUR tiap 6 jam (hypr-updates).
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/hypr-updates watch")
  -- Toast "Copied" saat teks diblok di terminal (alacritty/tmux menyalin diam-diam ke clipboard).
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/hypr-clipboard-toast watch")

  -- Instalasi dari ISO: selesaikan langkah yang ditunda (tema GTK, sinkron greeter) sekali; no-op bila tidak ada penanda.
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/resi-shell first-login")

  -- Automount USB (Thunar sudah bisa mount manual lewat gvfs).
  if o.cmd_present("udiskie") then
    hl.exec_cmd("udiskie --automount --no-notify --no-tray")
  end
end)
