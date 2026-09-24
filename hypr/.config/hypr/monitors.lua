-- Monitor. Daftar: hyprctl monitors all
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })   -- "auto" memilih 1.5 untuk panel 15.6" 1080p; 1 = ruang kerja penuh 1920x1080
-- Contoh monitor eksternal:
-- hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "auto-right", scale = 1 })

-- Workspace 1-5 selalu ada, supaya indikator workspace Noctalia stabil.
for ws = 1, 5 do
  hl.workspace_rule({ workspace = tostring(ws), persistent = true })
end

-- Layout dari nwg-displays (menu Setup > Monitors, skrip hypr-monitors): file ini ditulis nwg-displays,
-- ada di ~/.config/hypr di luar repo (hypr di-stow --no-folding), dan menimpa aturan umum di atas
-- untuk output yang disebut. Hapus filenya untuk kembali ke aturan umum.
local home = os.getenv("HOME")
for _, name in ipairs({ "nwg-monitors.lua", "nwg-workspaces.lua" }) do
  local f = io.open(home .. "/.config/hypr/" .. name, "r")
  if f then f:close(); pcall(dofile, home .. "/.config/hypr/" .. name) end
end
