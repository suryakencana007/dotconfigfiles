-- Proses saat Hyprland mulai (hanya saat start, bukan saat reload).
hl.on("hyprland.start", function()
  -- Supaya service user systemd & D-Bus tahu variabel sesi Wayland (portal, app launch cepat).
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  -- Shell desktop: bar, launcher, notifikasi, lock, idle, wallpaper, OSD, polkit agent.
  hl.exec_cmd("noctalia")

  -- Mode baterai otomatis: power-saver + brightness dibatasi saat charger dicabut (hypr-power).
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/hypr-power watch")
  -- Indikator update paket di bar: cek repo + AUR tiap 6 jam (hypr-updates).
  hl.exec_cmd(os.getenv("HOME") .. "/.local/bin/hypr-updates watch")

  -- Automount USB (Thunar sudah bisa mount manual lewat gvfs).
  if o.cmd_present("udiskie") then
    hl.exec_cmd("udiskie --automount --no-notify --no-tray")
  end
end)
