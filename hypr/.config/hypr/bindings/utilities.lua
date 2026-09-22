-- Screenshot, color picker, zoom, daftar keybinding.
local shots = "~/Pictures/Screenshots"
o.bind("PRINT", "Screenshot area", "hyprshot -m region -o " .. shots)
o.bind("SHIFT + PRINT", "Screenshot window", "hyprshot -m window -o " .. shots)
o.bind("CTRL + PRINT", "Screenshot layar penuh", "hyprshot -m output -o " .. shots)
o.bind("ALT + PRINT", "Screenshot area ke clipboard saja", "hyprshot -m region --clipboard-only")
o.bind("SUPER + SHIFT + S", "Screenshot area + edit (satty)", "hyprshot -m region --raw | satty --filename - --output-filename " .. shots .. "/satty-$(date +%Y%m%d-%H%M%S).png")
o.bind("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")

o.bind("SUPER + K", "Daftar keybinding", "alacritty --class TUI.float -e sh -c 'hyprctl binds | less'")

o.bind("SUPER + CTRL + Z", "Zoom in", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)
o.bind("SUPER + CTRL + ALT + Z", "Reset zoom", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)
