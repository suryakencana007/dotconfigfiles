#!/usr/bin/env bash
# Membuat ulang aset logo "Resi Arch" (wordmark piksel) untuk boot splash. Hasilnya di-commit, jadi instalasi tidak butuh
# alat ini; jalankan hanya bila desain berubah. Butuh: python3, rsvg-convert (librsvg), ffmpeg (untuk BMP UKI).
#   resi/boot/make-assets.sh
# Keluaran di resi/boot/plymouth/resi/: logo.png (2x), prompt.png, entry.png, bullet.png, progress_box.png,
# progress_bar.png, splash.bmp (splash UKI systemd-stub), dan resi/boot/iso-splash.png (menu boot ISO mode BIOS, 640x480).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; OUT="$HERE/plymouth/resi"; TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
command -v rsvg-convert >/dev/null || { echo "rsvg-convert not found (pacman -S librsvg)" >&2; exit 1; }
mkdir -p "$OUT"

python3 - "$TMP" <<'PY'
import sys
tmp = sys.argv[1]
FG, DIM, BG = "#e6e6ea", "#3a3a42", "#000000"
# Font piksel 7 baris, tebal goresan 1 sel persegi, jarak antar huruf 2 sel (lebih terbaca daripada blok ANSI 5 baris)
GLYPHS = {"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
          "E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
          "S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
          "I": ["#", "#", "#", "#", "#", "#", "#"]}
ART = ["..".join(GLYPHS[ch][r] for ch in "RESI") for r in range(7)]
U = 40                      # satu sel = U x U; aset dirender 2x untuk 1080p
W, H = len(ART[0]) * U, len(ART) * U
def wordmark(x0=0, y0=0, u=U, fg=FG):
    out = []
    for r, row in enumerate(ART):          # gabungkan sel berurutan jadi satu rect supaya tidak ada garis tipis antar sel
        c = 0
        while c < len(row):
            if row[c] == "#":
                e = c
                while e < len(row) and row[e] == "#": e += 1
                out.append(f'<rect x="{x0 + c*u}" y="{y0 + r*u}" width="{(e-c)*u}" height="{u}" fill="{fg}"/>')
                c = e
            else: c += 1
    return "\n".join(out)
def sub(cx, y, size, spacing, fill=FG, text="arch"):
    return (f'<text x="{cx}" y="{y}" text-anchor="middle" font-family="JetBrainsMono Nerd Font, JetBrains Mono, monospace" '
            f'font-weight="500" font-size="{size}" letter-spacing="{spacing}" fill="{fill}" opacity="0.72">{text}</text>')
def svg(w, h, body, bg=None):
    rect = f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}">{rect}{body}</svg>'
def write(name, s): open(f"{tmp}/{name}.svg", "w").write(s)

gap, fs = 104, 60                                   # jarak wordmark → "arch", ukuran huruf (letter-spacing digeser setengah supaya tetap di tengah)
LH = H + gap + 20
write("logo", svg(W, LH, wordmark() + sub(W/2 + fs*0.45, H + gap, fs, fs*0.9)))
# splash UKI / ISO: logo di tengah kanvas hitam
def centered(cw, ch, scale):
    u = U * scale; w, h = len(ART[0]) * u, len(ART) * u
    x0, y0 = (cw - w) / 2, (ch - h) / 2 - 20 * scale
    return svg(cw, ch, wordmark(x0, y0, u) + sub(cw/2 + fs*scale*0.45, y0 + h + gap*scale, fs*scale, fs*scale*0.9), BG)
write("splash", centered(640, 320, 0.45))
write("iso-splash", centered(640, 480, 0.45))
write("prompt", svg(560, 44, sub(280, 32, 28, 3, text="Enter disk passphrase")))
write("entry", svg(640, 84, f'<rect x="2" y="2" width="636" height="80" rx="14" fill="none" stroke="{DIM}" stroke-width="3"/>'))
write("bullet", svg(24, 24, f'<circle cx="12" cy="12" r="9" fill="{FG}"/>'))
write("progress_box", svg(16, 16, f'<rect width="16" height="16" fill="{DIM}"/>'))
write("progress_bar", svg(16, 16, f'<rect width="16" height="16" fill="{FG}"/>'))
PY

for n in logo prompt entry bullet progress_box progress_bar; do rsvg-convert "$TMP/$n.svg" -o "$OUT/$n.png"; done
rsvg-convert "$TMP/iso-splash.svg" -o "$HERE/iso-splash.png"
rsvg-convert "$TMP/splash.svg" -o "$TMP/splash.png"
if command -v ffmpeg >/dev/null; then ffmpeg -loglevel error -y -i "$TMP/splash.png" -pix_fmt bgr24 "$OUT/splash.bmp"
else echo "ffmpeg not found: splash.bmp (UKI splash) not regenerated" >&2; fi
cp "$TMP/logo.svg" "$HERE/logo.svg"
ls -la "$OUT" "$HERE/iso-splash.png"
