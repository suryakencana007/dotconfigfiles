#!/usr/bin/env bash
# Membuat ulang aset logo "Resi Arch" (seni ASCII di resi/boot/logo.txt, dirender dengan JetBrains Mono) untuk boot splash. Hasilnya di-commit, jadi instalasi tidak butuh
# alat ini; jalankan hanya bila desain berubah. Butuh: python3, rsvg-convert (librsvg), font JetBrainsMono Nerd Font,
# ffmpeg (untuk BMP UKI).
#   resi/boot/make-assets.sh
# Keluaran di resi/boot/plymouth/resi/: logo.png (2x), prompt.png, entry.png, bullet.png, progress_box.png,
# progress_bar.png, splash.bmp (splash UKI systemd-stub), dan resi/boot/iso-splash.png (menu boot ISO mode BIOS, 640x480).
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; OUT="$HERE/plymouth/resi"; TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
command -v rsvg-convert >/dev/null || { echo "rsvg-convert not found (pacman -S librsvg)" >&2; exit 1; }
mkdir -p "$OUT"

python3 - "$TMP" "$HERE/logo.txt" <<'PY'
import sys
from xml.sax.saxutils import escape
tmp = sys.argv[1]
FG, DIM, BG = "#e6e6ea", "#3a3a42", "#000000"
ART = [l.rstrip("\n") for l in open(sys.argv[2])]          # seni ASCII "RESI ARCH" (figlet doom), sumber tunggal logo
while ART and not ART[-1].strip(): ART.pop()
COLS = max(len(l) for l in ART)
FONT = "JetBrainsMono Nerd Font Mono, JetBrains Mono, monospace"
def wordmark(x0, y0, fs, fg=FG):
    # satu <text> per karakter, di tengah selnya (lebar sel 0.6em): kisi tetap lurus apa pun advance font-nya
    # (librsvg tidak mendukung daftar x per glyph, dan spasi beruntun dilipat tanpa xml:space)
    adv, lh, out = fs * 0.6, fs * 1.22, []
    out.append(f'<g font-family="{FONT}" font-weight="700" font-size="{fs}" fill="{fg}" text-anchor="middle">')
    for r, row in enumerate(ART):
        for c, ch in enumerate(row):
            if ch != " ": out.append(f'<text x="{x0 + (c + 0.5) * adv:.2f}" y="{y0 + fs + r * lh:.2f}">{escape(ch)}</text>')
    out.append("</g>")
    return "\n".join(out)
def size(fs): return COLS * fs * 0.6, len(ART) * fs * 1.22 + fs * 0.35
def text(cx, y, fs, spacing, body, fill=FG):
    return (f'<text x="{cx}" y="{y}" text-anchor="middle" font-family="{FONT}" font-weight="500" font-size="{fs}" '
            f'letter-spacing="{spacing}" fill="{fill}" opacity="0.72">{body}</text>')
def svg(w, h, body, bg=None):
    rect = f'<rect width="{w}" height="{h}" fill="{bg}"/>' if bg else ""
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w:.0f}" height="{h:.0f}" viewBox="0 0 {w:.0f} {h:.0f}">{rect}{body}</svg>'
def write(name, s): open(f"{tmp}/{name}.svg", "w").write(s)

FS = 48                                            # aset 2x untuk 1080p: di layar ~778 px lebar
W, H = size(FS)
write("logo", svg(W, H, wordmark(0, 0, FS)))
def centered(cw, ch, fs):                          # splash UKI / ISO: logo di tengah kanvas hitam
    w, h = size(fs)
    return svg(cw, ch, wordmark((cw - w) / 2, (ch - h) / 2, fs), BG)
write("splash", centered(640, 320, 18))
write("iso-splash", centered(640, 480, 18))
write("prompt", svg(560, 44, text(280, 32, 28, 3, "Enter disk passphrase")))
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
