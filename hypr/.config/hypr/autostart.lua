-- Proses saat Hyprland mulai (hanya saat start, bukan saat reload).
hl.on("hyprland.start", function()
  -- Supaya service user systemd & D-Bus tahu variabel sesi Wayland (portal, app launch cepat).
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  -- Shell desktop: bar, launcher, notifikasi, lock, idle, wallpaper, OSD, polkit agent.
  hl.exec_cmd("noctalia")

  -- Automount USB (Thunar sudah bisa mount manual lewat gvfs).
  if o.cmd_present("udiskie") then
    hl.exec_cmd("udiskie --automount --no-notify --no-tray")
  end
end)
