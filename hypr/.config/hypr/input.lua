-- Input. Dasar: Omarchy default/hypr/input.lua. Caps Lock TIDAK diubah jadi compose key
-- (Omarchy melakukannya; kalau mau: kb_options = "compose:caps,shift:both_capslock_cancel").
hl.config({
  input = {
    kb_layout = "us",
    kb_variant = "",
    kb_model = "",
    kb_options = "",
    kb_rules = "",
    follow_mouse = 1,
    sensitivity = 0,
    repeat_rate = 40,
    repeat_delay = 250,
    numlock_by_default = true,
    touchpad = {
      natural_scroll = false,
      clickfinger_behavior = true,   -- klik 2 jari = klik kanan
      scroll_factor = 0.4,
    },
  },
  misc = {
    key_press_enables_dpms = true,
    mouse_move_enables_dpms = true,
  },
})

-- Gesture 3 jari geser = ganti workspace (dari config lamamu).
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Scroll lebih cepat di terminal.
o.window("(Alacritty|kitty)", { scroll_touchpad = 1.5 })
