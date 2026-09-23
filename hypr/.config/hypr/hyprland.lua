-- ~/.config/hypr/hyprland.lua
-- Struktur meniru Omarchy (basecamp/omarchy), tanpa skrip omarchy-*. Shell desktop: Noctalia v5.
-- Validasi setiap perubahan:  hyprctl reload && hyprctl configerrors
-- Config bawaan lama: hyprland.lua.autogen.bak

local home = os.getenv("HOME")

-- Hyprland memakai satu state Lua lintas reload; buang cache modul "hypr.*" supaya
-- file yang diedit benar-benar dibaca ulang.
for module in pairs(package.loaded) do
  if module == "hypr" or module == "noctalia" or module:sub(1, 5) == "hypr." then
    package.loaded[module] = nil
  end
end
package.path = home .. "/.config/?.lua;" .. package.path

require("hypr.helpers")      -- o.bind, o.window, dll
require("hypr.envs")         -- variabel lingkungan Wayland
require("hypr.looknfeel")    -- gaps, border, blur, animasi, layer rule Noctalia
require("hypr.input")        -- keyboard, touchpad, gesture
require("hypr.monitors")     -- monitor + workspace persisten
require("hypr.windows")      -- window rules
require("hypr.qconsole")     -- scratchpad ala Quake console (Super + `)

require("hypr.bindings.tiling")
require("hypr.bindings.apps")
require("hypr.bindings.noctalia")
require("hypr.bindings.media")
require("hypr.bindings.clipboard")
require("hypr.bindings.utilities")

require("hypr.autostart")

-- Override khusus mesin ini (opsional): hosts/<hostname>/.config/hypr/local.lua di repo dotfiles.
pcall(require, "hypr.local")

-- Override pribadi tambahan bisa ditaruh di bawah sini.

-- Warna border dari tema Noctalia (file noctalia.lua dirender Noctalia; hook-nya mencari
-- teks require("noctalia") di file ini, jadi jangan diubah). pcall: aman kalau belum dirender.
pcall(function() require("noctalia").apply_theme() end)
