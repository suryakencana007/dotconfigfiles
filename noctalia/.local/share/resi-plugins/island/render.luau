--!nonstrict
-- Modul bersama: mengubah satu snapshot jadi pohon ui.*.
--
-- Sengaja TIDAK memanggil barWidget maupun layer. Entry-lah yang menyerahkan pohonnya ke host,
-- sehingga satu modul ini melayani dua entry sekaligus: [[widget]] di dalam bar (Render.build)
-- dan [[layer]] yang melayang di atas jendela (Render.buildFloat).

local Render = {}

Render.ICON = 18 -- sisi ikon/album art, dan juga lebar kolom ikon
Render.GAP = 6

-- Versi melayang punya ruangnya sendiri, jadi semuanya lebih besar dan diberi bantalan.
Render.FLOAT_ICON = 30
Render.FLOAT_GAP = 12
Render.FLOAT_PAD_H = 16
Render.FLOAT_PAD_V = 10
-- Menyamakan diri dengan kapsul bar (bar.toml: radius = 4), bukan pil penuh: mesin ini memakai
-- sudut kotak di mana-mana (corner_radius_scale = 0, rounding Hyprland 0).
Render.FLOAT_RADIUS = 4

-- Lebar saat menciut penuh: hanya muat ikon.
function Render.collapsedWidth(): number
  return Render.ICON
end

-- Idem untuk versi melayang; bantalan kiri-kanan ikut dihitung karena ada di dalam containernya.
function Render.floatCollapsedWidth(): number
  return Render.FLOAT_ICON + Render.FLOAT_PAD_H * 2
end

-- Tinggi kapsul melayang saat menciut. Surface layer menyesuaikan isinya, jadi angka ini yang
-- menentukan tinggi jendelanya sendiri -- dan titik awal animasi saat kartu membuka.
function Render.floatCollapsedHeight(): number
  return Render.FLOAT_ICON + Render.FLOAT_PAD_V * 2
end

-- snap: { glyph, accent, text, art, progress, width, textOpacity, vertical }
function Render.build(snap): any
  local accent = snap.accent or "on_surface"

  -- Bar vertikal tidak punya ruang melebar ke samping: cukup ikonnya saja.
  if snap.vertical then
    return ui.column({ align = "center" }, {
      ui.glyph({ name = snap.glyph or "music", size = Render.ICON, color = accent }),
    })
  end

  local width = math.max(Render.collapsedWidth(), math.floor(snap.width or 0))
  local children = {}

  if snap.art then
    children[#children + 1] = ui.image({
      path = snap.art,
      width = Render.ICON,
      height = Render.ICON,
      radius = 2,
      fit = "cover",
    })
  else
    children[#children + 1] = ui.glyph({ name = snap.glyph or "music", size = Render.ICON, color = accent })
  end

  -- Sisa ruang setelah ikon. Di bawah ambang ini teks/progress belum pantas digambar: label dengan
  -- maxWidth sangat kecil hanya jadi satu huruf terpotong.
  local rest = width - Render.ICON - Render.GAP
  local opacity = snap.textOpacity or 1

  if rest >= 16 and opacity > 0.02 then
    if snap.progress ~= nil then
      children[#children + 1] = ui.progress({
        progress = snap.progress,
        width = rest,
        height = 4,
        radius = 2,
        fill = accent,
        track = "outline",
        opacity = opacity,
      })
    elseif snap.text and snap.text ~= "" then
      children[#children + 1] = ui.label({
        text = snap.text,
        maxWidth = rest,
        maxLines = 1,
        textAlign = "start",
        fontWeight = "medium",
        color = accent,
        opacity = opacity,
      })
    end
  end

  return ui.row({ width = width, gap = Render.GAP, align = "center" }, children)
end

-- snap: sama seperti Render.build, minus `vertical` (layer selalu horizontal).
--
-- Bedanya dengan versi bar: punya latar sendiri (di bar ia menumpang kapsul milik grup), ikon dan
-- teks lebih besar, dan `width` di sini lebar containernya -- bantalan sudah termasuk.
function Render.buildFloat(snap): any
  local accent = snap.accent or "on_surface"
  local width = math.max(Render.floatCollapsedWidth(), math.floor(snap.width or 0))
  local children = {}

  if snap.art then
    children[#children + 1] = ui.image({
      path = snap.art,
      width = Render.FLOAT_ICON,
      height = Render.FLOAT_ICON,
      radius = Render.FLOAT_RADIUS,
      fit = "cover",
    })
  else
    children[#children + 1] = ui.glyph({ name = snap.glyph or "music", size = Render.FLOAT_ICON, color = accent })
  end

  local rest = width - Render.FLOAT_ICON - Render.FLOAT_GAP - Render.FLOAT_PAD_H * 2
  local opacity = snap.textOpacity or 1

  if rest >= 24 and opacity > 0.02 then
    if snap.progress ~= nil then
      -- Bar dan angkanya berdampingan seperti OSD bawaan yang digantikan island ini. Angkanya
      -- dapat jatah tetap supaya bar tidak ikut berkedut saat 9% jadi 100%.
      local numberWidth = 44
      children[#children + 1] = ui.progress({
        progress = snap.progress,
        width = math.max(16, rest - numberWidth - Render.FLOAT_GAP),
        height = 6,
        radius = 3,
        fill = accent,
        track = "outline",
        opacity = opacity,
      })
      if snap.text and snap.text ~= "" then
        children[#children + 1] = ui.label({
          text = snap.text,
          width = numberWidth,
          maxLines = 1,
          textAlign = "end",
          fontSize = 14,
          fontWeight = "medium",
          color = accent,
          opacity = opacity,
        })
      end
    elseif snap.subtitle and snap.subtitle ~= "" and snap.title and snap.title ~= "" then
      -- Island melayang punya tinggi yang bar tidak punya: judul dan artis ditumpuk, bukan
      -- disambung dengan em-dash lalu dipotong di tengah judul.
      children[#children + 1] = ui.column({ gap = 2, align = "stretch", flexGrow = 1 }, {
        ui.label({
          text = snap.title,
          maxWidth = rest,
          maxLines = 1,
          textAlign = "start",
          fontSize = 14,
          fontWeight = "medium",
          color = accent,
          opacity = opacity,
        }),
        ui.label({
          text = snap.subtitle,
          maxWidth = rest,
          maxLines = 1,
          textAlign = "start",
          fontSize = 12,
          color = "on_surface_variant",
          opacity = opacity,
        }),
      })
    elseif snap.text and snap.text ~= "" then
      children[#children + 1] = ui.label({
        text = snap.text,
        maxWidth = rest,
        maxLines = 1,
        textAlign = "start",
        fontSize = 14,
        fontWeight = "medium",
        color = accent,
        opacity = opacity,
      })
    end
  end

  -- Surface layer menyusut mengikuti isinya, jadi lebar container inilah yang menggerakkan lebar
  -- jendelanya sendiri. `fill` memakai alpha supaya blur layer rule Hyprland kelihatan.
  return ui.row({
    key = "island-capsule",
    width = width,
    height = snap.height,
    gap = Render.FLOAT_GAP,
    align = "center",
    paddingH = Render.FLOAT_PAD_H,
    paddingV = Render.FLOAT_PAD_V,
    radius = Render.FLOAT_RADIUS,
    fill = "surface/0.78",
    border = "outline",
    borderWidth = 1,
    onHover = snap.onHover,
  }, children)
end

-- ── Kartu media ─────────────────────────────────────────────────────────────

Render.CARD_ART = 56
Render.CARD_GAP = 10
Render.CARD_BTN = 30
-- Tinggi yang diukur sendiri oleh ui.slider untuk controlSize = "sm" (Style::controlHeightSm).
-- Dipatok di sini karena tinggi kartu dihitung sebelum isinya pernah diukur.
Render.CARD_SEEK = 32
-- Bantalan tegak baris seek. Bukan hiasan: slider MENCURI hover dari kartu (ia punya InputArea
-- sendiri dan `onHover` bukan prop yang dikenalnya), jadi baris yang memuatnya harus memagarinya
-- di keempat sisi supaya pointer yang menuju slider selalu melapor lewat baris ini lebih dulu.
-- Sisi kiri-kanan dipagari angka waktu, yang bukan InputArea dan karena itu melapor ke barisnya.
Render.CARD_SEEK_PAD = 5
Render.CARD_META = Render.CARD_SEEK + Render.CARD_SEEK_PAD * 2 -- tinggi baris seek

-- Tinggi kartu dihitung, bukan diukur: layer menganimasikan tingginya sendiri, jadi ia harus tahu
-- target angkanya sebelum isinya pernah digambar.
function Render.floatOpenHeight(): number
  return Render.FLOAT_PAD_V * 2
    + Render.CARD_ART
    + Render.CARD_GAP
    + Render.CARD_META
    + Render.CARD_GAP
    + Render.CARD_BTN
end

local function clockText(seconds: number?): string
  local total = math.max(0, math.floor(seconds or 0))
  return string.format("%d:%02d", math.floor(total / 60), total % 60)
end

-- snap: { title, subtitle, art, status, positionSec, lengthSec, width, height,
--         contentOpacity, onHover, onPrev, onPlayPause, onNext, onSeek, onSeekEnd }
--
-- Isinya diturunkan dari `width`/`height` yang SEDANG dianimasikan, bukan dari ukuran mati. Itu
-- syaratnya supaya isi dan panel bergerak sebagai satu benda: tidak ada prop clip di ui.*, jadi
-- anak berukuran tetap di dalam induk yang menyusut akan meluber keluar dan terlihat seperti
-- bayangan yang tertinggal. Baris dilepas dari bawah begitu tingginya tidak lagi cukup, dan album
-- art ikut mengecil -- kapsul toast sudah lama bekerja begini.
--
-- Semua handler diserahkan sebagai NAMA fungsi global, bukan closure: pohon ini dibangun ulang tiap
-- frame, dan closure baru tiap frame berarti host harus merangkai ulang handler 60x/detik.
function Render.buildFloatOpen(snap): any
  local width = math.floor(snap.width or 0)
  local height = math.floor(snap.height or 0)
  local innerW = width - Render.FLOAT_PAD_H * 2
  local innerH = height - Render.FLOAT_PAD_V * 2

  local opacity = snap.contentOpacity or 1
  local playing = snap.status == "Playing"
  local hasMedia = snap.title ~= nil and snap.title ~= ""
  local children = {}

  -- Album art mengecil mengikuti tinggi yang tersisa; di bawah ini tidak ada lagi yang pantas.
  local artSize = math.min(Render.CARD_ART, innerH)
  local textWidth = innerW - artSize - Render.FLOAT_GAP

  if opacity > 0.02 and artSize >= 12 then
    local header = {}
    if snap.art then
      header[#header + 1] = ui.image({
        path = snap.art,
        width = artSize,
        height = artSize,
        radius = Render.FLOAT_RADIUS,
        fit = "cover",
      })
    else
      header[#header + 1] = ui.glyph({ name = "disc", size = artSize, color = "on_surface_variant" })
    end

    -- Teks baru muat setelah album art mengambil jatahnya.
    local showText = textWidth >= 40
    if showText then
      header[#header + 1] = ui.column({ gap = 3, align = "stretch", flexGrow = 1 }, {
        ui.label({
          text = hasMedia and snap.title or "Nothing playing",
          maxWidth = textWidth,
          maxLines = 1,
          textAlign = "start",
          fontSize = 15,
          fontWeight = "medium",
          color = hasMedia and "on_surface" or "on_surface_variant",
        }),
        ui.label({
          text = snap.subtitle or "",
          maxWidth = textWidth,
          maxLines = 1,
          textAlign = "start",
          fontSize = 12,
          color = "on_surface_variant",
          visible = snap.subtitle ~= nil and snap.subtitle ~= "",
        }),
      })
    end

    -- Tanpa teks, album art harus DI TENGAH baris, bukan rata kiri. Baris tetap selebar panel, jadi
    -- art yang rata kiri meninggalkan panel kosong di kanannya yang menyusut dengan irama sendiri --
    -- itu yang terbaca sebagai kotak tertinggal saat kartu menciut.
    children[#children + 1] = ui.row({
      height = artSize,
      gap = Render.FLOAT_GAP,
      align = "center",
      justify = showText and "start" or "center",
    }, header)

    -- Durasi tidak selalu dilaporkan (beberapa stream mengirim mpris:length = 0); tanpa itu bar
    -- posisi tidak punya arti, jadi barisnya dilepas daripada menampilkan 0:00 palsu.
    local length = snap.lengthSec or 0
    local position = math.min(snap.positionSec or 0, length)
    local roomForMeta = innerH >= Render.CARD_ART + Render.CARD_GAP + Render.CARD_META

    if roomForMeta and hasMedia and length > 0 then
      local meta = {}
      -- Angka waktu dilepas lebih dulu daripada barnya saat lebar menipis.
      local showClocks = innerW >= 240
      if showClocks then
        meta[#meta + 1] = ui.label({
          text = clockText(position),
          width = 42,
          maxLines = 1,
          textAlign = "start",
          fontSize = 11,
          color = "on_surface_variant",
        })
      end
      -- Slider, bukan ui.progress: bar yang hanya bisa dilihat tidak ada gunanya di permukaan yang
      -- menerima pointer penuh. Nilainya didorong tiap render (kontrol value-driven), dan host
      -- menahan diri menerapkannya selagi gagangnya diseret, jadi polling 1 Hz tidak merebut
      -- gagang dari tangan pengguna.
      meta[#meta + 1] = ui.slider({
        key = "seekbar",
        min = 0,
        max = length,
        step = 1,
        value = position,
        controlSize = "sm",
        flexGrow = 1,
        onChange = snap.onSeek,
        onDragEnd = snap.onSeekEnd,
      })
      if showClocks then
        meta[#meta + 1] = ui.label({
          text = "-" .. clockText(length - position),
          width = 42,
          maxLines = 1,
          textAlign = "end",
          fontSize = 11,
          color = "on_surface_variant",
        })
      end
      -- Barisnya membawa onHover sendiri dan bantalan tegak: lihat CARD_SEEK_PAD. Tanpa itu pointer
      -- yang menyentuh slider membuat kartu melapor "keluar" tanpa ada yang melapor "masuk", dan
      -- kartunya menutup tepat saat pengguna hendak menggeser.
      children[#children + 1] = ui.row({
        key = "seek",
        height = Render.CARD_META,
        paddingV = Render.CARD_SEEK_PAD,
        gap = 8,
        align = "center",
        onHover = snap.onHover,
      }, meta)
    end

    -- Tiap tombol membawa onHover sendiri: hanya elemen terdalam yang melaporkan hover, jadi tanpa
    -- ini pointer yang mampir ke tombol membuat kapsul melaporkan "keluar" dan kartu menutup.
    local roomForButtons = innerH >= Render.floatOpenHeight() - Render.FLOAT_PAD_V * 2
    if roomForButtons and innerW >= 160 then
      children[#children + 1] = ui.row({ height = Render.CARD_BTN, gap = 14, align = "center", justify = "center" }, {
        ui.button({
          key = "prev",
          glyph = "player-skip-back",
          glyphSize = 16,
          variant = "ghost",
          controlSize = "sm",
          enabled = hasMedia,
          onClick = snap.onPrev,
          onHover = snap.onHover,
        }),
        ui.button({
          key = "playpause",
          glyph = playing and "player-pause" or "player-play",
          glyphSize = 18,
          variant = "primary",
          controlSize = "sm",
          enabled = hasMedia,
          onClick = snap.onPlayPause,
          onHover = snap.onHover,
        }),
        ui.button({
          key = "next",
          glyph = "player-skip-forward",
          glyphSize = 16,
          variant = "ghost",
          controlSize = "sm",
          enabled = hasMedia,
          onClick = snap.onNext,
          onHover = snap.onHover,
        }),
      })
    end
  end

  -- Opacity ditaruh di wadah dalam, bukan di akar: `opacity` memudarkan container BESERTA anaknya,
  -- jadi di akar ia ikut memudarkan latar kapsulnya -- latar yang justru harus tetap utuh.
  return ui.column({
    key = "island-card",
    width = width,
    height = snap.height,
    align = "stretch",
    paddingH = Render.FLOAT_PAD_H,
    paddingV = Render.FLOAT_PAD_V,
    radius = Render.FLOAT_RADIUS,
    fill = "surface/0.78",
    border = "outline",
    borderWidth = 1,
    onHover = snap.onHover,
  }, {
    -- Sama untuk sumbu tegak: saat baris progress dan tombol sudah dilepas, sisa isinya dipusatkan
    -- supaya tidak menggantung di atas dengan ruang kosong di bawahnya.
    ui.column({
      gap = Render.CARD_GAP,
      align = "stretch",
      justify = "center",
      flexGrow = 1,
      opacity = opacity,
    }, children),
  })
end

-- Surface dipaku seukuran kartu terbesar (lihat [[layer]] width/height di plugin.toml), lalu panel
-- yang beranimasi dipusatkan di dalamnya. Alasannya: saat surface di-anchor ke "top" saja, lebarnya
-- menentukan x-nya; mengubah lebar tiap frame membuat x tertinggal satu frame dari ukurannya, dan
-- area yang ditinggalkan tidak dicat ulang -- terlihat sebagai kotak basi di sisi kanan panel.
function Render.floatStage(child): any
  return ui.column({ flexGrow = 1, align = "center", justify = "start" }, { child })
end

return Render
