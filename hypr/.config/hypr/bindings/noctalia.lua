-- Noctalia: pengganti omarchy-menu / omarchy-shell. Referensi: docs.noctalia.dev/noctalia/ipc/
local ipc = "noctalia msg "

o.bind("SUPER + SPACE", "Menu", os.getenv("HOME") .. "/.local/bin/rofi-toggle menu")   -- menu ala Omarchy (rofi); launcher Noctalia: ikon di bar
o.bind("SUPER + S", "Control center", ipc .. "panel-toggle control-center")
o.bind("SUPER + ESCAPE", "Session menu (logout/reboot/shutdown)", ipc .. "panel-toggle session")
o.bind("XF86PowerOff", "Session menu", ipc .. "panel-toggle session", { locked = true })
o.bind("SUPER + CTRL + V", "Clipboard history", ipc .. "panel-toggle clipboard")
o.bind("SUPER + CTRL + SPACE", "Wallpaper picker", ipc .. "panel-toggle wallpaper")
o.bind("SUPER + SHIFT + CTRL + SPACE", "Theme switcher", os.getenv("HOME") .. "/.local/bin/hypr-theme-carousel --toggle")   -- carousel ala omarchy-shell; palet/mode: hypr-theme (menu Style)
o.bind("SUPER + CTRL + ALT + SPACE", "Wallhaven browser", ipc .. "panel-toggle noctalia/wallhaven:browser")
o.bind("SUPER + SHIFT + SPACE", "Toggle bar", ipc .. "bar-toggle")
o.bind("SUPER + SHIFT + comma", "Noctalia settings", ipc .. "settings-toggle")
o.bind("ALT + TAB", "Window switcher", ipc .. "window-switcher")
o.bind("SUPER + CTRL + L", "Lock screen", os.getenv("HOME") .. "/.local/bin/hypr-lock")   -- hyprlock (lock Noctalia dimatikan)

-- Notifikasi
o.bind("SUPER + comma", "Dismiss notifications", ipc .. "notification-clear-active")
o.bind("SUPER + ALT + comma", "Open last notification", ipc .. "notification-invoke-latest")
o.bind("SUPER + CTRL + comma", "Toggle Do Not Disturb", ipc .. "notification-dnd-toggle")

-- Toggle sistem
o.bind("SUPER + CTRL + N", "Toggle nightlight", ipc .. "nightlight-toggle")
o.bind("SUPER + CTRL + I", "Toggle caffeine (no idle lock)", ipc .. "caffeine-toggle")
o.bind("SUPER + CTRL + A", "Audio", ipc .. "panel-toggle control-center audio")
o.bind("SUPER + CTRL + B", "Bluetooth", ipc .. "panel-toggle control-center bluetooth")
o.bind("SUPER + CTRL + W", "Network", ipc .. "panel-toggle control-center network")
