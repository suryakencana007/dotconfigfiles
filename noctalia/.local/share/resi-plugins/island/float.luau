--!nonstrict
-- Entry [[layer]]: island melayang di atas jendela (plugin API 36).
--
-- Layer bersifat malas. Tidak ada apa pun sampai entry lain dari plugin ini memanggil
-- noctalia.layer.show("float"); host lalu membuat satu surface dan satu salinan skrip ini, dan
-- noctalia.layer.hide("float") memusnahkan keduanya. Jadi daur hidup skrip ini = satu kali tampil.
--
-- Dua wajah dalam satu surface:
--   toast  kapsul satu baris yang muncul karena event, menahan, lalu pergi sendiri
--   open   kartu media dengan tombol sungguhan, dibuka dengan hover atau klik widget bar
--
--   layer.render(tree)            ganti pohon UI surface ini
--   layer.setNeedsFrameTick(on)   onFrameTick(deltaMs) tiap frame selama tampil
--   layer.outputName()            konektor output tempat salinan ini menggambar

local Anim = require("./anim.luau")
local Render = require("./render.luau")

-- Pointer yang berdiam di tepi membuat surface tumbuh lalu menyusut di bawahnya, dan tanpa jeda
-- ini enter/leave akan saling susul dan island berkedip. Jeda juga menutupi satu frame kosong saat
-- pohon berganti dari kapsul ke kartu: node lamanya melaporkan "keluar" sebelum node baru
-- melaporkan "masuk".
local HOVER_GRACE_MS = 280
local CARD_FADE_MS = 140
local POSITION_POLL_MS = 1000
-- Selagi geometri bergerak, tiap frame harus digambar. Setelah diam, satu-satunya yang masih
-- berubah adalah bar posisi -- yang bergeser satu piksel beberapa detik sekali.
--
-- Meremnya tidak cukup dengan melewatkan render: selama setNeedsFrameTick menyala, layer meminta
-- frame 60x/detik dan surface-nya ikut dikomposisi ulang sebanyak itu juga. Jadi saat semua Track
-- selesai, frame tick DIMATIKAN dan update() yang mengambil alih -- termasuk untuk menghitung
-- tenggat hover, yang 100 ms sudah lebih dari cukup presisinya.
local IDLE_UPDATE_MS = 100

local widthTrack = Anim.track(Render.floatCollapsedWidth())
local heightTrack = Anim.track(Render.floatCollapsedHeight())
local fadeTrack = Anim.track(0) -- isi kapsul
local cardTrack = Anim.track(0) -- isi kartu

local snapshot = { glyph = "music", accent = "on_surface", text = "", art = nil, progress = nil }
local media = nil
local positionSec = 0
local positionAtMs = 0

local mode = "toast"
-- Pohon yang digambar. Dipisah dari `mode` karena saat menutup dari kartu, yang menyusut harus
-- tetap kartu itu -- berganti ke kapsul di frame pertama penutupan akan terlihat seperti kedipan.
local view = "capsule"
local holdUntilMs = 0
local hoverGraceUntilMs = 0
local hoveredKeys = {}
local hoverCount = 0
local lastSeq = -1
local lastDrawMs = 0
local lastPositionMs = 0
local lastRequest = ""
local frameTickOn = false
local intervalMs = 0
local hidden = false

-- Keduanya menjadwal ulang sesuatu di host, jadi hanya dipanggil saat nilainya benar-benar berubah.
local function setFrameTick(on: boolean)
  if frameTickOn ~= on then
    frameTickOn = on
    layer.setNeedsFrameTick(on)
  end
end

local function setInterval(ms: number)
  if intervalMs ~= ms then
    intervalMs = ms
    noctalia.setUpdateInterval(ms)
  end
end

local function cfg(key, fallback)
  local v = noctalia.getConfig(key)
  if v == nil then
    return fallback
  end
  return v
end

local function capsuleWidth(): number
  return math.max(Render.floatCollapsedWidth() + 48, cfg("float_width", 340))
end

local function cardWidth(): number
  return math.max(capsuleWidth(), cfg("open_width", 420))
end

-- Surface hanya diubah saat berpindah mode, tidak pernah per frame. Keduanya memperBESAR; surface
-- tidak pernah dikecilkan selagi tampil, karena hide() yang memusnahkannya.
local function fitSurface(w: number, h: number)
  noctalia.layer.configure("float", { width = math.floor(w), height = math.floor(h) })
end

-- ── Posisi pemutaran ────────────────────────────────────────────────────────
-- Tidak ada stream posisi, jadi kartu memolling sendiri -- dan hanya selagi terbuka. Di antara dua
-- polling nilainya dimajukan dari jam dinding, supaya barnya bergerak mulus, bukan melompat 1x/detik.

local function displayedPosition(nowMs: number): number
  if media == nil then
    return 0
  end
  if media.status ~= "Playing" then
    return positionSec
  end
  return positionSec + (nowMs - positionAtMs) / 1000
end

-- Tiap perintah menyasar pemutar yang kartunya tampilkan, bukan pemutar pertama yang kebetulan
-- ada di bus.
local function playerctl(...): { string }
  local argv = { "playerctl" }
  if media ~= nil and media.player then
    argv[#argv + 1] = "-p"
    argv[#argv + 1] = media.player
  end
  for _, arg in ipairs({ ... }) do
    argv[#argv + 1] = arg
  end
  return argv
end

local function requestPosition()
  if media == nil or (media.lengthSec or 0) <= 0 then
    return
  end
  lastPositionMs = noctalia.nowMs()
  noctalia.runAsync(playerctl("position"), function(result)
    if not result or result.exitCode ~= 0 then
      return
    end
    local value = tonumber(noctalia.string.trim(result.stdout or ""))
    if value then
      positionSec = value
      positionAtMs = noctalia.nowMs()
    end
  end)
end

-- ── Menggambar ──────────────────────────────────────────────────────────────

local function draw(nowMs: number)
  lastDrawMs = nowMs
  if view == "card" then
    layer.render(Render.floatStage(Render.buildFloatOpen({
      title = media and media.title or nil,
      subtitle = media and media.subtitle or nil,
      art = media and media.art or nil,
      status = media and media.status or nil,
      positionSec = displayedPosition(nowMs),
      lengthSec = media and media.lengthSec or nil,
      width = widthTrack:value(nowMs),
      height = heightTrack:value(nowMs),
      contentOpacity = cardTrack:value(nowMs),
      onHover = "onIslandHover",
      onPrev = "onIslandPrev",
      onPlayPause = "onIslandPlayPause",
      onNext = "onIslandNext",
    })))
    return
  end

  layer.render(Render.floatStage(Render.buildFloat({
    glyph = snapshot.glyph,
    accent = snapshot.accent,
    text = snapshot.text,
    title = snapshot.title,
    subtitle = snapshot.subtitle,
    art = snapshot.art,
    progress = snapshot.progress,
    width = widthTrack:value(nowMs),
    height = heightTrack:value(nowMs),
    textOpacity = fadeTrack:value(nowMs),
    onHover = cfg("media_controls", true) and "onIslandHover" or nil,
  })))
end

-- ── Perpindahan mode ────────────────────────────────────────────────────────

local function openCard(nowMs: number)
  if mode == "open" then
    return
  end
  mode = "open"
  view = "card"
  holdUntilMs = 0
  setFrameTick(true)
  fitSurface(cardWidth(), Render.floatOpenHeight())
  local ms = cfg("expand_ms", 260)
  widthTrack:to(cardWidth(), ms, Anim.easeOutCubic, nowMs)
  heightTrack:to(Render.floatOpenHeight(), ms, Anim.easeOutCubic, nowMs)
  fadeTrack:to(0, math.floor(ms * 0.4), Anim.easeOutCubic, nowMs)
  -- Isi muncul bersamaan dengan panel yang membesar, tidak menunggu geometrinya diam.
  cardTrack:to(1, CARD_FADE_MS, Anim.easeOutCubic, nowMs)
  -- Dibuka tanpa pointer di atasnya (klik widget bar atau IPC): tidak akan pernah ada "pointer
  -- keluar" yang menutupnya, jadi ia diberi tenggat seperti toast. Hover yang datang kemudian
  -- membatalkan tenggat itu, dan kartu bertahan selama pointer masih di sana.
  hoverGraceUntilMs = hoverCount > 0 and 0 or (nowMs + cfg("hold_ms", 3000))
  requestPosition()
end

-- Isi dan geometri bergerak sebagai satu benda: isi kartu diturunkan dari lebar/tinggi yang sedang
-- dianimasikan (lihat Render.buildFloatOpen), jadi ia ikut mengecil alih-alih meluber keluar.
-- Memisahkan keduanya -- apa pun urutannya -- justru yang membuat panel terlihat tertinggal dari
-- isinya, atau sebaliknya.
local function startClosing(nowMs: number)
  mode = "closing"
  holdUntilMs = 0
  setFrameTick(true)
  local ms = cfg("expand_ms", 260)
  widthTrack:to(Render.floatCollapsedWidth(), ms, Anim.easeOutCubic, nowMs)
  heightTrack:to(Render.floatCollapsedHeight(), ms, Anim.easeOutCubic, nowMs)
  -- Isi kapsul memudar lebih cepat dari geometrinya; isi kartu memudar bersamaan dengannya,
  -- sehingga keduanya sampai di garis akhir pada saat yang sama.
  fadeTrack:to(0, math.floor(ms * 0.6), Anim.easeOutCubic, nowMs)
  cardTrack:to(0, ms, Anim.easeOutCubic, nowMs)
end

-- ── Hover ───────────────────────────────────────────────────────────────────
-- Hanya elemen TERDALAM yang melaporkan hover: pointer yang mampir ke tombol transport membuat
-- kartu melaporkan "keluar". Karena itu tiap node interaktif membawa handler yang sama dengan key
-- berbeda, dan yang dihitung di sini jumlah node yang sedang di-hover, bukan satu flag.

function onIslandHover(state, key)
  local id = (type(key) == "string" and key ~= "") and key or "root"
  local entered = state == "true"
  if entered and not hoveredKeys[id] then
    hoveredKeys[id] = true
    hoverCount += 1
  elseif not entered and hoveredKeys[id] then
    hoveredKeys[id] = nil
    hoverCount -= 1
  end

  local nowMs = noctalia.nowMs()
  if hoverCount > 0 then
    hoverGraceUntilMs = 0
    if mode ~= "closing" and cfg("media_controls", true) then
      openCard(nowMs)
    end
  elseif mode == "open" then
    hoverGraceUntilMs = nowMs + HOVER_GRACE_MS
  end
end

-- ── Tombol transport ────────────────────────────────────────────────────────
-- Tidak ada API MPRIS untuk plugin, jadi lewat playerctl. Status dibalik di tempat supaya glyph
-- langsung bereaksi; service akan mengirim status sebenarnya sepersekian detik kemudian.

function onIslandPlayPause()
  if media == nil then
    return
  end
  noctalia.runAsync(playerctl("play-pause"))
  if media.status == "Playing" then
    positionSec = displayedPosition(noctalia.nowMs())
    media.status = "Paused"
  else
    media.status = "Playing"
  end
  positionAtMs = noctalia.nowMs()
end

function onIslandPrev()
  noctalia.runAsync(playerctl("previous"))
end

function onIslandNext()
  noctalia.runAsync(playerctl("next"))
end

-- ── Event masuk ─────────────────────────────────────────────────────────────

local function applyMedia(raw: string?)
  if type(raw) ~= "string" or raw == "" then
    return
  end
  local ev = noctalia.json.decode(raw)
  if type(ev) ~= "table" then
    return
  end
  media = ev
  positionSec = 0
  positionAtMs = noctalia.nowMs()
  requestPosition()
end

-- Event baru saat surface sudah tampil: isinya diganti dan tahanannya dihitung ulang dari nol,
-- tanpa menciut dulu -- persis seperti island asli yang berganti konten di tempat.
local function applyEvent(raw: string?): boolean
  if type(raw) ~= "string" or raw == "" then
    return false
  end
  local ev = noctalia.json.decode(raw)
  if type(ev) ~= "table" or ev.seq == lastSeq then
    return false
  end
  lastSeq = ev.seq

  snapshot.glyph = ev.glyph or "music"
  snapshot.accent = ev.accent or "on_surface"
  snapshot.text = ev.text or ""
  snapshot.title = ev.title
  snapshot.subtitle = ev.subtitle
  snapshot.progress = ev.progress
  snapshot.art = cfg("show_album_art", true) and ev.art or nil

  -- Kartu yang sedang terbuka tidak diusir oleh event: ia hanya memperbarui isinya kalau eventnya
  -- memang tentang media. Volume dan kecerahan sudah punya OSD sendiri saat kartu terbuka.
  if mode == "open" then
    return false
  end

  local nowMs = noctalia.nowMs()
  local ms = cfg("expand_ms", 260)
  mode = "toast"
  view = "capsule"
  setFrameTick(true)
  widthTrack:to(capsuleWidth(), ms, Anim.easeOutBack, nowMs)
  heightTrack:to(Render.floatCollapsedHeight(), ms, Anim.easeOutCubic, nowMs)
  fadeTrack:to(1, ms, Anim.easeOutCubic, nowMs)
  holdUntilMs = nowMs + cfg("hold_ms", 3000)
  return true
end

noctalia.state.watch("island.event", function(value)
  if applyEvent(value) then
    draw(noctalia.nowMs())
  end
end)

noctalia.state.watch("island.media", function(value)
  applyMedia(value)
end)

-- Klik widget bar saat surface sudah tampil: show() jadi no-op, jadi permintaannya lewat sini.
noctalia.state.watch("island.request", function(value)
  if type(value) ~= "string" or value == "" or value == lastRequest then
    return
  end
  lastRequest = value
  if mode ~= "closing" then
    openCard(noctalia.nowMs())
  end
end)

-- ── Loop ─────────────────────────────────────────────────────────────────────

-- Satu badan loop, dua pemanggil: onFrameTick selagi ada yang bergerak, update() setelah diam.
-- Track membaca jam dinding noctalia.nowMs() sendiri (lihat anim.luau), jadi loop ini tidak peduli
-- seberapa sering ia dipanggil -- itu yang membuat perpindahan antara keduanya mulus.
local function tick()
  if hidden then
    return
  end
  local nowMs = noctalia.nowMs()
  local skipDraw = false

  if mode == "toast" then
    if holdUntilMs > 0 and nowMs >= holdUntilMs then
      startClosing(nowMs)
    end
  elseif mode == "open" then
    if hoverCount == 0 and hoverGraceUntilMs > 0 and nowMs >= hoverGraceUntilMs then
      startClosing(nowMs)
    elseif widthTrack:done(nowMs) and heightTrack:done(nowMs) and cardTrack:done(nowMs) then
      -- Diam: cukup digambar ulang 10x/detik untuk menggeser bar posisi.
      skipDraw = nowMs - lastDrawMs < IDLE_UPDATE_MS
      if nowMs - lastPositionMs >= POSITION_POLL_MS then
        requestPosition()
      end
    end
  elseif widthTrack:done(nowMs) and heightTrack:done(nowMs) and fadeTrack:done(nowMs) and cardTrack:done(nowMs) then
    -- Keluar selesai: hapus surface-nya, jangan sekadar biarkan transparan. hide() memusnahkan
    -- skrip ini, jadi tidak boleh ada render setelahnya.
    hidden = true
    noctalia.layer.hide("float")
    return
  end

  if not skipDraw then
    draw(nowMs)
  end

  -- Selama frame tick menyala, layer meminta frame 60x/detik dan surface-nya dikomposisi ulang
  -- sebanyak itu pula, entah isinya berubah atau tidak. Jadi ia dimatikan begitu semua Track
  -- selesai, dan update() yang meneruskan.
  local moving = not (widthTrack:done(nowMs) and heightTrack:done(nowMs) and fadeTrack:done(nowMs) and cardTrack:done(nowMs))
  setFrameTick(moving)
  setInterval(moving and POSITION_POLL_MS or IDLE_UPDATE_MS)
end

function onFrameTick(deltaMs)
  tick()
end

function update()
  tick()
end

-- Saat surface dibuat, pemicunya sudah ada di state: service menulisnya sebelum show().
-- float_width bisa diubah pengguna, sedangkan manifest hanya bisa memuat angka tetap.
fitSurface(capsuleWidth(), Render.floatCollapsedHeight())
setFrameTick(true)
setInterval(POSITION_POLL_MS)
applyMedia(noctalia.state.get("island.media"))

local request = noctalia.state.get("island.request")
local requestedAtMs = tonumber(request) or 0
if requestedAtMs > 0 and noctalia.nowMs() - requestedAtMs < 1500 then
  -- Dibuka dari widget bar. Permintaan lama diabaikan: nilainya bertahan di state sampai plugin
  -- berhenti, dan tanpa batas waktu ini tiap event berikutnya akan membuka kartu, bukan toast.
  lastRequest = request
  openCard(noctalia.nowMs())
else
  if type(request) == "string" then
    lastRequest = request
  end
  applyEvent(noctalia.state.get("island.event"))
end

draw(noctalia.nowMs())
