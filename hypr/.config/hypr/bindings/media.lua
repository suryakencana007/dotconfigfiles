-- Tombol media/brightness lewat Noctalia (OSD ikut tampil).
local ipc = "noctalia msg "
local hold = { locked = true, repeating = true }
o.bind("XF86AudioRaiseVolume", "Volume up", ipc .. "volume-up", hold)
o.bind("XF86AudioLowerVolume", "Volume down", ipc .. "volume-down", hold)
o.bind("XF86AudioMute", "Mute", ipc .. "volume-mute", { locked = true })
o.bind("XF86AudioMicMute", "Mute microphone", ipc .. "mic-mute", { locked = true })
o.bind("XF86MonBrightnessUp", "Brightness up", ipc .. "brightness-up", hold)
o.bind("XF86MonBrightnessDown", "Brightness down", ipc .. "brightness-down", hold)
o.bind("ALT + XF86AudioRaiseVolume", "Volume up precise", ipc .. "volume-up 1", hold)
o.bind("ALT + XF86AudioLowerVolume", "Volume down precise", ipc .. "volume-down 1", hold)
o.bind("ALT + XF86MonBrightnessUp", "Brightness up precise", ipc .. "brightness-up current 1", hold)
o.bind("ALT + XF86MonBrightnessDown", "Brightness down precise", ipc .. "brightness-down current 1", hold)

o.bind("XF86AudioNext", "Next track", ipc .. "media next", { locked = true })
o.bind("XF86AudioPrev", "Previous track", ipc .. "media previous", { locked = true })
o.bind("XF86AudioPlay", "Play/pause", ipc .. "media toggle", { locked = true })
o.bind("XF86AudioPause", "Play/pause", ipc .. "media toggle", { locked = true })
