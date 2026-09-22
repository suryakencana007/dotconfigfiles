-- Dari Omarchy default/hypr/envs.lua, tanpa bagian khusus Omarchy.
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Paksa semua app memakai Wayland.
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Screen sharing (Meet, Discord) butuh ini.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.config({
  xwayland = { force_zero_scaling = true },
  ecosystem = { no_update_news = true },
})
