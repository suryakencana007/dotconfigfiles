-- Window rules. Dasar: Omarchy default/hypr/windows.lua + apps/system.lua + apps/terminals.lua.
-- Sintaks rule: https://wiki.hypr.land/Configuring/Basics/Window-Rules/

o.window(".*", { suppress_event = "maximize" })

-- Semua window dapat tag default-opacity; app tertentu melepasnya di bawah.
o.window(".*", { tag = "+default-opacity" })

-- Perbaiki drag di XWayland.
o.window({ class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false }, { no_focus = true })

-- Tag terminal (dipakai binding clipboard universal).
o.window("(Alacritty|kitty|com.mitchellh.ghostty|foot|wezterm|TUI\\..*)", { tag = "+terminal" })

-- Window mengambang di tengah.
o.window({ tag = "floating-window" }, { float = true })
o.window({ tag = "floating-window" }, { center = true })
o.window({ tag = "floating-window" }, { size = { 875, 600 } })
o.window("(TUI.float|imv|mpv|org.gnome.Evince|org.pulseaudio.pavucontrol|nm-connection-editor|blueman-manager)", { tag = "+floating-window" })

-- Dialog portal (file picker, screen share) selalu mengambang.
o.window("xdg-desktop-portal-gtk", { tag = "+floating-window" })
o.window({ class = "(thunar|Thunar|brave-browser)", title = "^(Open.*Files?|Open [F|f]older.*|Save.*Files?|Save.*As|Save|All Files|[C|c]hoose.*)" }, { tag = "+floating-window" })

-- Jendela daftar keybinding (Super+K): class sendiri supaya ukurannya tidak ditimpa tag floating-window.
o.window("^hypr-keybindings$", { float = true })
o.window("^hypr-keybindings$", { center = true })
o.window("^hypr-keybindings$", { size = { 900, 860 } })
o.window("^hypr-keybindings$", { tag = "+terminal" })

-- Jendela Settings Noctalia (dari docs Noctalia).
o.window("dev.noctalia.Noctalia", { float = true })
o.window("dev.noctalia.Noctalia", { size = { 1080, 920 } })

-- Media tanpa transparansi.
local media = "^(zoom|vlc|mpv|org.kde.kdenlive|com.obsproject.Studio|imv)$"
o.window(media, { tag = "-default-opacity" })
o.window(media, { opacity = "1 1" })

-- Spotify selalu dibuka di workspace 5 (fokus ikut pindah; pakai "5 silent" kalau tidak mau pindah).
o.window("^(Spotify|spotify)$", { workspace = "5" })

-- Cegah idle/lock saat window bertag noidle terbuka.
o.window({ tag = "noidle" }, { idle_inhibit = "always" })

-- Opacity default, diterapkan terakhir setelah app sempat opt-out.
o.window({ tag = "default-opacity" }, { opacity = "0.985 0.96" })
