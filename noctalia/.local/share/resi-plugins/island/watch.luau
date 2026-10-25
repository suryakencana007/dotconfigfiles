--!nonstrict
-- Entry [[service]]: satu proses headless yang mengubah event sistem jadi satu aliran event island.
--
-- Noctalia 5.3.0 tidak punya API host untuk MPRIS, volume, atau notifikasi, jadi sumbernya proses
-- luar lewat runStream. Hasilnya didorong ke noctalia.state sebagai string JSON; widget (dan nanti
-- entry [[layer]]) hanya meng-watch satu kunci itu.

local SEP = "|~|"
local VOLUME_DEBOUNCE_MS = 120
local ART_CACHE_MAX = 50
local ART_PRUNE_EVERY = 10

local seq = 0
local artDir: string? = nil
local artDownloads = 0
local lastVolume = -1
local lastVolumeAtMs = 0
local lastMediaLine = ""
local lastMic = -1
local lastMicAtMs = 0
local lastBrightness = -1
local lastBrightnessAtMs = 0

local function cfg(key, fallback)
  local v = noctalia.getConfig(key)
  if v == nil then
    return fallback
  end
  return v
end

local function emit(ev)
  seq += 1
  ev.seq = seq
  local encoded = noctalia.json.encode(ev)
  if not encoded then
    return
  end
  -- State dulu, baru show: salinan skrip layer yang baru dibuat membaca kunci ini saat start,
  -- jadi ia harus sudah berisi event pemicunya. Kalau layer sudah tampil, state.watch di sana
  -- yang menangani dan show() jadi no-op.
  noctalia.state.set("island.event", encoded)
  if cfg("float_island", true) then
    noctalia.layer.show("float")
  end
end

-- ── Album art ─────────────────────────────────────────────────────────────────────
-- ui.image hanya menerima path berkas lokal. MPRIS memberi URL: Spotify https://, pemutar lokal
-- file://. Yang https diunduh ke direktori data plugin dan dipakai dari sana, jadi album art
-- Spotify ikut tampil -- selama ini ia selalu jatuh ke glyph.
--
-- Diunduh di service, bukan di layer, supaya berkasnya sudah ada sebelum skrip layer lahir.

-- djb2: cukup untuk nama berkas cache, bukan untuk kriptografi.
local function hashString(text: string): string
  local h = 5381
  for i = 1, #text do
    h = (h * 33 + text:byte(i)) % 4294967296
  end
  return string.format("%08x", h)
end

local function ensureArtDir(): string?
  if artDir ~= nil then
    return artDir
  end
  local base = noctalia.pluginDataDir()
  if type(base) ~= "string" or base == "" then
    return nil
  end
  local dir = base .. "/art"
  if not noctalia.mkdirAll(dir) then
    return nil
  end
  artDir = dir
  return artDir
end

-- Buang yang terlama kalau cache tumbuh melewati batas. Dijalankan sesekali, bukan tiap unduhan.
local function pruneArt(dir: string)
  local names = noctalia.listDir(dir)
  if type(names) ~= "table" or #names <= ART_CACHE_MAX then
    return
  end
  local files = {}
  for _, name in ipairs(names) do
    local path = dir .. "/" .. name
    local info = noctalia.fileInfo(path)
    if type(info) == "table" and not info.isDir then
      files[#files + 1] = { path = path, mtime = info.mtime or 0 }
    end
  end
  table.sort(files, function(a, b)
    return a.mtime < b.mtime
  end)
  for i = 1, #files - ART_CACHE_MAX do
    noctalia.removeFile(files[i].path)
  end
end

-- Memanggil `done(path?)` entah sekarang (lokal atau sudah ter-cache) atau nanti (setelah unduh).
local function resolveArt(url: string, done: (string?) -> ())
  if not cfg("show_album_art", true) or url == "" then
    done(nil)
    return
  end

  if url:sub(1, 7) == "file://" then
    done(noctalia.string.urlDecode(url:sub(8)))
    return
  end

  if url:sub(1, 5) ~= "http:" and url:sub(1, 6) ~= "https:" then
    done(nil)
    return
  end

  local dir = ensureArtDir()
  if dir == nil then
    done(nil)
    return
  end

  -- Ekstensi tidak dipercaya dari URL; decoder Noctalia menebak dari isinya.
  local path = dir .. "/" .. hashString(url)
  if noctalia.fileExists(path) then
    done(path)
    return
  end

  noctalia.download(url, path, function(ok)
    if not ok then
      done(nil)
      return
    end
    artDownloads += 1
    if artDownloads % ART_PRUNE_EVERY == 0 then
      pruneArt(dir)
    end
    done(path)
  end)
end

-- ── Media (MPRIS) ───────────────────────────────────────────────────────────
-- playerctl --follow mencetak satu baris tiap metadata atau status berubah, dan diam saat tidak ada
-- pemutar sama sekali. Baris pertama datang segera setelah pemutar muncul.

local function splitFields(line: string)
  local out, from = {}, 1
  while true do
    local s, e = line:find(SEP, from, true)
    if not s then
      out[#out + 1] = line:sub(from)
      break
    end
    out[#out + 1] = line:sub(from, s - 1)
    from = e + 1
  end
  return out
end

local function onMediaLine(line: string)
  if not cfg("watch_media", true) then
    return
  end
  line = noctalia.string.trim(line)
  -- playerctl mengulang baris yang sama saat posisi diperbarui; hanya perubahan nyata yang dipakai.
  if line == "" or line == lastMediaLine then
    return
  end
  lastMediaLine = line

  local f = splitFields(line)
  local status, artist, title = f[1] or "", f[2] or "", f[3] or ""
  local art, length, player = f[4] or "", tonumber(f[5] or "") or 0, f[6] or ""
  if title == "" then
    return
  end

  local text = title
  if artist ~= "" then
    text = `{title} — {artist}`
  end

  -- Art diselesaikan dulu (unduh kalau perlu) supaya kartu tidak sempat menggambar glyph lebih
  -- dahulu lalu berkedip jadi gambar. Lagu yang sama tidak diunduh ulang.
  resolveArt(art, function(path: string?)
    local media = {
      kind = "media",
      glyph = status == "Playing" and "player-play" or "player-pause",
      accent = "primary",
      text = text,
      title = title,
      subtitle = artist ~= "" and artist or nil,
      art = path,
      status = status,
      -- playerctl TANPA -p menyasar pemutar pertama yang tersedia, sedangkan --follow mengikuti
      -- yang sedang aktif. Di mesin ini keduanya berbeda (brave lebih dulu dari spotify), jadi
      -- nama pemutarnya ikut dibawa supaya tombol kartu menyasar yang sedang ditampilkan.
      player = player ~= "" and player or nil,
      -- MPRIS melaporkan panjang lagu dalam mikrodetik.
      lengthSec = length > 0 and math.floor(length / 1000000) or nil,
    }

    -- Kartu media harus bisa dibuka kapan saja, termasuk lama setelah lagu berganti, jadi
    -- snapshot media terakhir disimpan terpisah dari event pemicu yang sifatnya sekali pakai.
    local encodedMedia = noctalia.json.encode(media)
    if encodedMedia then
      noctalia.state.set("island.media", encodedMedia)
    end

    emit(media)
  end)
end

-- ── Volume (PipeWire lewat PulseAudio shim) ─────────────────────────────────
-- `pactl subscribe` hanya memberi tahu BAHWA ada perubahan, tanpa nilainya, jadi nilainya diambil
-- menyusul dengan wpctl. Baris sink-input (volume per aplikasi) sengaja dilewati.

local function onVolumeValue(result)
  if not result or result.exitCode ~= 0 then
    return
  end
  local out = result.stdout or ""
  local value = tonumber(out:match("Volume:%s*([%d%.]+)"))
  if not value then
    return
  end
  local muted = out:find("MUTED", 1, true) ~= nil

  -- Hanya kirim saat nilainya benar-benar berubah: pactl memancarkan beberapa event per geseran.
  local key = muted and -2 or value
  if key == lastVolume then
    return
  end
  lastVolume = key

  local glyph = "volume"
  if muted then
    glyph = "volume-off"
  elseif value < 0.01 then
    glyph = "volume-3"
  elseif value < 0.5 then
    glyph = "volume-2"
  end

  emit({
    kind = "volume",
    glyph = glyph,
    accent = muted and "outline" or "primary",
    text = muted and "Muted" or `{math.floor(value * 100 + 0.5)}%`,
    progress = muted and 0 or math.min(1, value),
  })
end

-- ── Mikrofon ────────────────────────────────────────────────────────────────
-- Sumbernya stream pactl yang sama; yang membedakan hanya baris "on source #" dan perangkat yang
-- ditanyakan ke wpctl. Mute jauh lebih sering dipakai daripada levelnya, jadi itu yang ditonjolkan.

local function onMicValue(result)
  if not result or result.exitCode ~= 0 then
    return
  end
  local out = result.stdout or ""
  local value = tonumber(out:match("Volume:%s*([%d%.]+)"))
  if not value then
    return
  end
  local muted = out:find("MUTED", 1, true) ~= nil

  local key = muted and -2 or value
  if key == lastMic then
    return
  end
  lastMic = key

  emit({
    kind = "mic",
    glyph = muted and "microphone-off" or "microphone",
    accent = muted and "outline" or "primary",
    text = muted and "Mic muted" or `{math.floor(value * 100 + 0.5)}%`,
    progress = not muted and math.min(1, value) or nil,
  })
end

local function onMicEvent(line: string)
  -- "on source-output #..." adalah stream per aplikasi, bukan perangkatnya.
  if not line:find("on source #", 1, true) then
    return
  end
  local nowMs = noctalia.nowMs()
  if nowMs - lastMicAtMs < VOLUME_DEBOUNCE_MS then
    return
  end
  lastMicAtMs = nowMs
  noctalia.runAsync({ "wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@" }, onMicValue, 1000)
end

local function onVolumeEvent(line: string)
  if cfg("watch_mic", true) then
    onMicEvent(line)
  end
  if not cfg("watch_volume", true) then
    return
  end
  -- "Event 'change' on sink #52" dipakai; "on sink-input #..." tidak.
  if not line:find("on sink #", 1, true) then
    return
  end
  local nowMs = noctalia.nowMs()
  if nowMs - lastVolumeAtMs < VOLUME_DEBOUNCE_MS then
    return
  end
  lastVolumeAtMs = nowMs
  noctalia.runAsync({ "wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@" }, onVolumeValue, 1000)
end

-- ── Kecerahan layar ─────────────────────────────────────────────────────────
-- Tombol kecerahan memanggil `noctalia msg brightness-*`, jadi tidak ada yang bisa di-watch dari
-- sisi tombolnya. Yang bisa: kernel memancarkan uevent "change" di subsystem backlight setiap kali
-- nilainya ditulis, siapa pun yang menulisnya. udevadm sudah ada (systemd), inotify-tools tidak.
--
-- Nama perangkatnya diambil dari baris uevent, bukan dipatok: mesin ini punya amdgpu_bl2 DAN
-- nvidia_0, dan yang benar-benar berubah itulah yang dilaporkan udev.

local function onBrightnessValue(result)
  if not result or result.exitCode ~= 0 then
    return
  end
  -- `cat a b` mencetak nilai lalu maksimum, masing-masing satu baris.
  local value, maxValue = (result.stdout or ""):match("(%d+)%s+(%d+)")
  value, maxValue = tonumber(value), tonumber(maxValue)
  if not value or not maxValue or maxValue <= 0 then
    return
  end

  local ratio = math.min(1, value / maxValue)
  local pct = math.floor(ratio * 100 + 0.5)
  if pct == lastBrightness then
    return
  end
  lastBrightness = pct

  emit({
    kind = "brightness",
    glyph = ratio < 0.34 and "sun-low" or (ratio < 0.67 and "brightness" or "sun-high"),
    accent = "primary",
    text = `{pct}%`,
    progress = ratio,
  })
end

local function onBacklightEvent(line: string)
  if not cfg("watch_brightness", true) then
    return
  end
  local device = line:match("/([^/%s]+)%s+%(backlight%)")
  -- Dipakai menyusun path, jadi dijaga tetap satu segmen nama perangkat -- bukan "..".
  if not device or not device:match("^[%w_%-]+$") then
    return
  end
  local nowMs = noctalia.nowMs()
  if nowMs - lastBrightnessAtMs < VOLUME_DEBOUNCE_MS then
    return
  end
  lastBrightnessAtMs = nowMs

  local dir = "/sys/class/backlight/" .. device .. "/"
  noctalia.runAsync({ "cat", dir .. "brightness", dir .. "max_brightness" }, onBrightnessValue, 1000)
end

-- ── Start ───────────────────────────────────────────────────────────────────
-- Service ini tidak perlu tick sendiri; semuanya digerakkan oleh stream.
noctalia.setUpdateInterval(60000)

if noctalia.commandExists("playerctl") then
  -- Dirangkai dengan concat, bukan interpolasi Luau: format playerctl penuh kurung kurawal.
  local fmt = "{{status}}" .. SEP .. "{{artist}}" .. SEP .. "{{title}}" .. SEP .. "{{mpris:artUrl}}"
    .. SEP .. "{{mpris:length}}" .. SEP .. "{{playerName}}"
  -- `exec` supaya sh digantikan playerctl, bukan jadi induknya: runStream membunuh proses yang
  -- ia jalankan, dan tanpa exec yang terbunuh hanya sh-nya sementara playerctl jadi yatim.
  noctalia.runStream("exec playerctl --follow --format '" .. fmt .. "' metadata", onMediaLine)
else
  noctalia.log("island: playerctl not found, media events disabled")
end

if noctalia.commandExists("udevadm") then
  noctalia.runStream("exec udevadm monitor --udev --subsystem-match=backlight", onBacklightEvent)
else
  noctalia.log("island: udevadm not found, brightness events disabled")
end

if noctalia.commandExists("pactl") and noctalia.commandExists("wpctl") then
  noctalia.runStream("exec pactl subscribe", onVolumeEvent)
else
  noctalia.log("island: pactl/wpctl not found, volume events disabled")
end
