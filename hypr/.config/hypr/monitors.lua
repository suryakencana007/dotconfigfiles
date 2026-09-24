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

-- Mode baterai (skrip hypr-power): refresh panel diturunkan saat di baterai, bila panel punya mode lebih rendah.
local powerflag = home .. "/.local/state/resi/hypr/power.lua"
do
  local f = io.open(powerflag, "r")
  if f then f:close(); pcall(dofile, powerflag) end
end

-- Clamshell mode (skrip hypr-clamshell): lid tertutup + monitor eksternal aktif -> layar internal dimatikan.
-- Keadaannya file Lua kecil di luar repo yang dimuat paling akhir supaya menang atas aturan di atas.
local clamshell = home .. "/.local/state/resi/hypr/clamshell.lua"
do
  local f = io.open(clamshell, "r")
  if f then f:close(); pcall(dofile, clamshell) end
end
-- Sinkronkan ulang saat monitor dicolok/dicabut (ala omarchy-hyprland-monitor-watch). Langganan lama
-- dilepas dulu supaya tidak menumpuk tiap reload.
if _G.__resi_clamshell_subs then
  for _, sub in ipairs(_G.__resi_clamshell_subs) do pcall(function() sub:remove() end) end
end
_G.__resi_clamshell_subs = {}
for _, ev in ipairs({ "monitor.added", "monitor.removed" }) do
  table.insert(_G.__resi_clamshell_subs, hl.on(ev, function() hl.exec_cmd(home .. "/.local/bin/hypr-clamshell") end))
end
