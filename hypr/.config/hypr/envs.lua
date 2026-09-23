-- Dari Omarchy default/hypr/envs.lua, tanpa bagian khusus Omarchy.
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

-- Paksa semua app memakai Wayland.
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "gtk3")
hl.env("MOZ_ENABLE_WAYLAND", "1")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
hl.env("OZONE_PLATFORM", "wayland")
hl.env("XDG_SESSION_TYPE", "wayland")

-- Screen sharing (Meet, Discord) butuh ini.
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

hl.config({
  xwayland = { force_zero_scaling = true },
  ecosystem = { no_update_news = true },
})

-- ~/.local/bin ke PATH Hyprland, supaya skrip sendiri (mis. hypr-keybindings) bisa dipanggil dari binding.
-- Sesi greetd tidak menjalankan .zshrc, jadi PATH Hyprland tidak memuatnya.
do
  local bin = os.getenv("HOME") .. "/.local/bin"
  local kept = {}
  for entry in (os.getenv("PATH") or "/usr/local/bin:/usr/bin"):gmatch("[^:]+") do
    if entry ~= bin then table.insert(kept, entry) end
  end
  table.insert(kept, 1, bin)
  hl.env("PATH", table.concat(kept, ":"))
end

-- NVIDIA (GTX 1660 Ti, driver nvidia-open). Hanya aktif kalau NVIDIA adalah satu-satunya GPU
-- (BIOS mode diskrit). Di mode hybrid, GPU AMD (amdgpu) yang jadi utama untuk Hyprland, jadi variabel
-- ini justru salah arah dan dilewati. Nilai sama seperti Omarchy nvidia.lua.
do
  local function exists(path) local f = io.open(path, "r"); if f then f:close(); return true end; return false end
  if exists("/proc/driver/nvidia/version") and not exists("/sys/module/amdgpu/initstate") then
    hl.env("NVD_BACKEND", "direct")
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")
  elseif exists("/sys/module/amdgpu/initstate") then
    -- Mode hybrid: paksa Mesa/VA-API AMD. Ditulis eksplisit (bukan hanya dilewati) karena hl.env tidak pernah
    -- menghapus variabel yang pernah diset sampai Hyprland restart; tanpa ini libva mencoba driver nvidia.
    hl.env("LIBVA_DRIVER_NAME", "radeonsi")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "mesa")
    hl.env("NVD_BACKEND", "")
  end
end
