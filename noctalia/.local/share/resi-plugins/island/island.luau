--!nonstrict
-- Entry [[widget]]: island di dalam bar.
--
-- Bar widget tidak punya frame tick, jadi loop animasinya adalah update() yang dipercepat
-- sementara: 16 ms (plafon host) selama bergerak, 120 ms selama menahan, 1000 ms saat diam.
-- Tanpa penurunan itu widget akan merender 60x/detik selamanya untuk gambar yang sama.

local Anim = require("./anim.luau")
local Render = require("./render.luau")

local FAST_MS = 16 -- host meng-clamp setUpdateInterval ke >= 16
local HOLD_MS = 120
local IDLE_MS = 1000

local widthTrack = Anim.track(Render.collapsedWidth())
local fadeTrack = Anim.track(0)

local snapshot = { glyph = "music", accent = "on_surface", text = "", art = nil, progress = nil }
local holdUntilMs = 0
local hovering = false
local vertical = false
local interval = 0
local lastSeq = -1

local function cfg(key, fallback)
  local v = noctalia.getConfig(key)
  if v == nil then
    return fallback
  end
  return v
end

local function expandedWidth(): number
  return math.max(Render.collapsedWidth() + 24, cfg("expanded_width", 220))
end

local function expand(nowMs: number, hold: boolean)
  local ms = cfg("expand_ms", 260)
  widthTrack:to(expandedWidth(), ms, Anim.easeOutBack, nowMs)
  fadeTrack:to(1, ms, Anim.easeOutCubic, nowMs)
  if hold then
    holdUntilMs = nowMs + cfg("hold_ms", 3000)
  end
end

local function collapse(nowMs: number)
  local ms = cfg("expand_ms", 260)
  widthTrack:to(Render.collapsedWidth(), ms, Anim.easeOutCubic, nowMs)
  -- Teks memudar lebih cepat dari lebarnya, supaya tidak terlihat terpotong saat menyempit.
  fadeTrack:to(0, math.floor(ms * 0.6), Anim.easeOutCubic, nowMs)
  holdUntilMs = 0
end

-- Interval hanya diubah saat nilainya berbeda: setiap panggilan menjadwal ulang timer di host.
local function setInterval(ms: number)
  if interval ~= ms then
    interval = ms
    noctalia.setUpdateInterval(ms)
  end
end

local function draw(nowMs: number)
  local width = widthTrack:value(nowMs)
  local fade = fadeTrack:value(nowMs)

  barWidget.render(Render.build({
    glyph = snapshot.glyph,
    accent = snapshot.accent,
    text = snapshot.text,
    art = snapshot.art,
    progress = snapshot.progress,
    width = width,
    textOpacity = fade,
    vertical = vertical,
  }))

  if snapshot.text ~= "" then
    barWidget.setTooltip(snapshot.text)
  end
end

function update()
  local nowMs = noctalia.nowMs()
  vertical = barWidget.isVertical()

  if holdUntilMs > 0 and nowMs >= holdUntilMs and not hovering then
    collapse(nowMs)
  end

  draw(nowMs)

  local animating = not (widthTrack:done(nowMs) and fadeTrack:done(nowMs))
  if animating then
    setInterval(FAST_MS)
  elseif hovering or holdUntilMs > 0 then
    setInterval(HOLD_MS)
  else
    setInterval(IDLE_MS)
  end
end

-- Island melayang hanya ada saat ada event, jadi tanpa pintu ini kartu media tidak bisa dipanggil
-- sewaktu-waktu. Klik, bukan hover: ada celah 10 px antara bar dan island, dan pointer yang
-- menyeberanginya pasti melewati daerah kosong dan memicu "keluar".
local function openFloat()
  if not cfg("float_island", true) or not cfg("media_controls", true) then
    return
  end
  -- Stempel waktu, bukan flag: dua klik beruntun harus terbaca sebagai dua permintaan, dan skrip
  -- layer yang baru lahir memakainya untuk tahu permintaannya masih segar.
  noctalia.state.set("island.request", tostring(noctalia.nowMs()))
  noctalia.layer.show("float")
end

function onClick()
  openFloat()
end

-- Jalan kedua, supaya kartu bisa dipasang ke keybind:
--   noctalia msg plugin resi/island:island focused open
function onIpc(event, payload)
  if event == "open" then
    openFloat()
  end
end

function onHover(entered: boolean)
  hovering = entered
  local nowMs = noctalia.nowMs()
  if entered then
    if cfg("expand_on_hover", true) then
      expand(nowMs, false)
    end
  elseif holdUntilMs == 0 then
    collapse(nowMs)
  else
    -- Pointer pergi saat masih menahan: hitung ulang tahanannya dari sekarang.
    holdUntilMs = nowMs + cfg("hold_ms", 3000)
  end
  setInterval(FAST_MS)
end

-- Service mendorong event sebagai string JSON (nilai antar VM paling aman berupa string).
-- `seq` naik tiap event, supaya dua event identik beruntun tetap terbaca sebagai event baru.
noctalia.state.watch("island.event", function(value)
  if type(value) ~= "string" or value == "" then
    return
  end
  local ev = noctalia.json.decode(value)
  if type(ev) ~= "table" or ev.seq == lastSeq then
    return
  end
  lastSeq = ev.seq

  snapshot.glyph = ev.glyph or "music"
  snapshot.accent = ev.accent or "on_surface"
  snapshot.text = ev.text or ""
  snapshot.progress = ev.progress
  snapshot.art = cfg("show_album_art", true) and ev.art or nil

  local nowMs = noctalia.nowMs()
  -- Island melayang yang menampilkan event; di sini cukup ikon berganti warna supaya tidak ada
  -- dua animasi yang menyuarakan hal yang sama. Expand-on-hover tetap jalan.
  if cfg("float_island", true) then
    draw(nowMs)
    return
  end
  expand(nowMs, true)
  setInterval(FAST_MS)
  draw(nowMs)
end)

widthTrack:set(Render.collapsedWidth())
fadeTrack:set(0)
setInterval(IDLE_MS)
