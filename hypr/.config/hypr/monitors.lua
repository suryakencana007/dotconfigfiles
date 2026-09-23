-- Monitor. Daftar: hyprctl monitors all
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })   -- "auto" memilih 1.5 untuk panel 15.6" 1080p; 1 = ruang kerja penuh 1920x1080
-- Contoh monitor eksternal:
-- hl.monitor({ output = "HDMI-A-1", mode = "2560x1440@144", position = "auto-right", scale = 1 })

-- Workspace 1-5 selalu ada, supaya indikator workspace Noctalia stabil.
for ws = 1, 5 do
  hl.workspace_rule({ workspace = tostring(ws), persistent = true })
end
