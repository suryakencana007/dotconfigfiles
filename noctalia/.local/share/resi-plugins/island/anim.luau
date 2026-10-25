--!nonstrict
-- Mesin animasi kecil: satu Track per properti yang dianimasikan.
--
-- Bar widget TIDAK mendapat onFrameTick (host hanya mengirimnya ke desktop widget, panel terbuka,
-- dan layer), jadi nilai tidak boleh dihitung dari delta frame. Semua Track membaca jam dinding
-- noctalia.nowMs() dan menghitung posisinya sendiri, sehingga hasilnya tetap benar walau update()
-- datang tidak teratur atau terlewat.

local Anim = {}

function Anim.linear(t: number): number
  return t
end

function Anim.easeOutCubic(t: number): number
  local u = 1 - t
  return 1 - u * u * u
end

-- Sedikit melewati target lalu kembali: ini yang membuat gerakan terasa "pop" seperti island.
function Anim.easeOutBack(t: number): number
  local c1 = 1.70158
  local u = t - 1
  return 1 + (c1 + 1) * u * u * u + c1 * u * u
end

local Track = {}
Track.__index = Track

function Anim.track(value: number)
  return setmetatable({ from = value, target = value, startMs = 0, durationMs = 0, ease = Anim.linear }, Track)
end

-- Animasikan ke target. Target yang sama diabaikan, supaya event beruntun tidak terus-menerus
-- me-restart animasi yang sudah menuju tempat yang sama.
-- Catatan: field-nya bernama `target`, bukan `to` -- field instance bernama sama dengan method akan
-- menutupi method itu lewat __index, dan `track:to(...)` berubah jadi "attempt to call a number value".
function Track:to(target: number, durationMs: number, ease, nowMs: number)
  if self.target == target then
    return
  end
  self.from = self:value(nowMs)
  self.target = target
  self.startMs = nowMs
  self.durationMs = math.max(0, durationMs)
  self.ease = ease or Anim.easeOutCubic
end

-- Lompat tanpa animasi (dipakai saat render pertama).
function Track:set(value: number)
  self.from = value
  self.target = value
  self.durationMs = 0
end

function Track:value(nowMs: number): number
  if self.durationMs <= 0 then
    return self.target
  end
  local t = (nowMs - self.startMs) / self.durationMs
  if t >= 1 then
    return self.target
  end
  if t < 0 then
    t = 0
  end
  return self.from + (self.target - self.from) * self.ease(t)
end

function Track:done(nowMs: number): boolean
  return self.durationMs <= 0 or (nowMs - self.startMs) >= self.durationMs
end

return Anim
