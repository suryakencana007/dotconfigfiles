-- Aplikasi. Dasar: Omarchy bindings/applications.lua, diarahkan ke app di mesin ini.
o.bind("SUPER + RETURN", "Terminal", "alacritty")
o.bind("SUPER + ALT + RETURN", "Terminal + tmux", "alacritty -e tmux new-session -A -s main")
o.bind("SUPER + SHIFT + RETURN", "Browser", "brave")
o.bind("SUPER + SHIFT + B", "Browser", "brave")
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", "brave --incognito")
o.bind("SUPER + SHIFT + F", "File manager", "thunar")
o.bind("SUPER + SHIFT + N", "Editor (nvim)", "alacritty -e nvim")
o.bind("SUPER + CTRL + T", "Activity (btop)", "alacritty --class TUI.float -e btop")

-- Web app (jendela tanpa tab) lewat Brave
o.bind("SUPER + SHIFT + A", "ChatGPT", "brave --app=https://chatgpt.com")
o.bind("SUPER + SHIFT + Y", "YouTube", "brave --app=https://youtube.com/")
o.bind("SUPER + SHIFT + ALT + G", "WhatsApp", "brave --app=https://web.whatsapp.com/")
