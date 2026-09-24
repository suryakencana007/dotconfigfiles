-- Screenshot (Noctalia bawaan, dengan anotator), rekam layar (hypr-record: gpu-screen-recorder), color picker, zoom, daftar keybinding.
o.bind("PRINT", "Screenshot area", "noctalia msg screenshot-region")
o.bind("SHIFT + PRINT", "Screenshot window", "hyprshot -m window -o ~/Pictures/Screenshots")   -- Noctalia belum punya mode window
o.bind("CTRL + PRINT", "Screenshot layar penuh", "noctalia msg screenshot-fullscreen")
o.bind("ALT + PRINT", "Rekam layar: area (toggle)", os.getenv("HOME") .. "/.local/bin/hypr-record")
o.bind("CTRL + ALT + PRINT", "Rekam layar: penuh (toggle)", os.getenv("HOME") .. "/.local/bin/hypr-record screen")
o.bind("SUPER + PRINT", "Color picker", "pkill -x hyprpicker || hyprpicker -a")

o.bind("SUPER + K", "Keybindings", os.getenv("HOME") .. "/.local/bin/hypr-keybindings --toggle")   -- daftar ala Omarchy; tekan lagi untuk menutup

o.bind("SUPER + CTRL + Z", "Zoom in", function()
  local zoom = hl.get_config("cursor.zoom_factor") or 1
  hl.config({ cursor = { zoom_factor = zoom + 1 } })
end)
o.bind("SUPER + CTRL + ALT + Z", "Reset zoom", function()
  hl.config({ cursor = { zoom_factor = 1 } })
end)

-- Lid laptop (ala Omarchy): tutup -> kunci (bila tanpa monitor eksternal) + clamshell; buka -> layar internal kembali.
-- locked = true: tetap berlaku saat layar terkunci (bindl). Tanpa deskripsi supaya tidak muncul di daftar Super+K.
o.bind("switch:on:Lid Switch",  nil, os.getenv("HOME") .. "/.local/bin/hypr-lid-close", { locked = true })
o.bind("switch:off:Lid Switch", nil, os.getenv("HOME") .. "/.local/bin/hypr-clamshell", { locked = true })
