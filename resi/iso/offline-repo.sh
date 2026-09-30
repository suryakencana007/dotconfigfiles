#!/usr/bin/env bash
# Mirror offline untuk ISO resi-shell (ala Ryoku offline-repo.sh / mirror Omarchy): closure dependensi penuh
# (target: base, kernel, firmware, Limine, Btrfs, snapper, driver GPU, paket resi) diunduh beserta tanda tangannya,
# paket AUR dibangun dengan makepkg, lalu digabung menjadi repo pacman "resi-offline". Plus tarball vendor untuk
# clone git yang dipakai install.sh (oh-my-zsh, powerlevel10k, fzf-tab, TPM).
#   resi/iso/offline-repo.sh <dir-keluaran> [dir-cache]
#   resi/iso/offline-repo.sh --print-deps [dir-cache]   hanya clone AUR dan cetak depends+makedepends-nya (build.sh
#                                                       memasangnya sebagai root sebelum makepkg; makepkg tidak bisa sudo)
# Jalankan sebagai user biasa (makepkg menolak root); build.sh memanggilnya lewat runuser. Cache dipakai ulang antar
# build; hanya paket yang belum ada yang diunduh. Butuh database sync pacman yang segar (build.sh: pacman -Sy dulu).
set -euo pipefail

PRINT_DEPS=0; [[ ${1:-} == --print-deps ]] && { PRINT_DEPS=1; shift; set -- "${1:-/tmp/resi-offline}" "${1:-}"; }
OUT="$(realpath -m "${1:?usage: offline-repo.sh <out-dir> [cache-dir]}")"; CACHE="$(realpath -m "${2:-$OUT.cache}")"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; REPO="$(cd "$HERE/../.." && pwd)"
[[ $(id -u) -ne 0 ]] || { echo "run offline-repo.sh as a normal user (makepkg refuses root)" >&2; exit 1; }
for t in pacman repo-add makepkg git curl; do command -v "$t" >/dev/null || { echo "$t is required" >&2; exit 1; }; done

c=$'\e[1;34m'; g=$'\e[1;32m'; y=$'\e[1;33m'; o=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c" "$*" "$o"; }; ok() { printf '%s  ✓ %s%s\n' "$g" "$*" "$o"; }; warn() { printf '%s  ! %s%s\n' "$y" "$*" "$o"; }
pkglist() { sed -E 's/#.*//; s/^[[:space:]]+//; s/[[:space:]]+$//' "$1" | grep -v '^$' || true; }

mkdir -p "$CACHE/pkg" "$CACHE/aur" "$CACHE/vendor"
AUR=( yay-bin $(pkglist "$REPO/resi/packages.aur") )
aur_clone() { local p d; for p in "${AUR[@]}"; do d="$CACHE/aur/$p"
  if [[ -d $d/.git ]]; then git -C "$d" pull -q --ff-only 2>/dev/null || true; else git clone -q "https://aur.archlinux.org/$p.git" "$d"; fi; done; }
aur_deps() { local p; for p in "${AUR[@]}"; do ( cd "$CACHE/aur/$p" && makepkg --printsrcinfo 2>/dev/null | awk -F" = " '/^[[:space:]]*(make)?depends = /{print $2}' | sed 's/[<>=].*//' ); done | sort -u; }
missing_deps() { aur_deps | while read -r d; do pacman -Qq "$d" >/dev/null 2>&1 || pacman -Qq "$(pacman -Sp --print-format %n "$d" 2>/dev/null | head -1)" >/dev/null 2>&1 || echo "$d"; done; }
if (( PRINT_DEPS )); then aur_clone >&2; aur_deps | tr '\n' ' '; echo; exit 0; fi
mkdir -p "$OUT"

# ---- 1. closure paket resmi terhadap database lokal KOSONG (supaya dependensi yang sudah ada di host ikut) ----
step "Resolving the package closure"
DB="$CACHE/db"; mkdir -p "$DB/sync" "$DB/local"
cp -u /var/lib/pacman/sync/*.db "$DB/sync/"
TARGETS=( base base-devel linux linux-firmware linux-headers limine btrfs-progs snapper efibootmgr dosfstools
          networkmanager sudo git zsh mesa vulkan-radeon vulkan-intel intel-media-driver libva-mesa-driver
          amd-ucode intel-ucode nvidia-open-dkms nvidia-utils $(pkglist "$REPO/resi/packages.pacman") )
mapfile -t urls < <(pacman -Sp --dbpath "$DB" --logfile /dev/null "${TARGETS[@]}")
ok "${#urls[@]} packages in the closure"

# ---- 2. unduh paket + .sig (paralel, lewati yang sudah ada dan utuh) ----
step "Downloading packages into $CACHE/pkg"
printf '%s\n' "${urls[@]}" | sed 's|^file://||' | while read -r u; do
  f="$CACHE/pkg/$(basename "$u")"
  if [[ $u == /* ]]; then [[ -f $f ]] || cp "$u" "$f"; [[ -f $f.sig ]] || cp "$u.sig" "$f.sig" 2>/dev/null || true; continue; fi
  [[ -f $f ]] || echo "$u"
done | xargs -r -P 8 -I{} sh -c 'cd "$1" && curl -fsSL --retry 3 -O "{}" && curl -fsSL --retry 3 -O "{}.sig" || echo "  ! failed: {}"' _ "$CACHE/pkg"
bad=0; for u in "${urls[@]}"; do f="$CACHE/pkg/$(basename "$u")"; [[ -f $f ]] || { warn "missing: $(basename "$u")"; bad=1; }; done
(( bad )) && { echo "some packages failed to download" >&2; exit 1; }
ok "all packages present"

# ---- 3. paket AUR: makepkg di host (dependensi build harus sudah ada di host) ----
step "Building AUR packages"
aur_clone
miss=$(missing_deps | tr '\n' ' '); [[ -z $miss ]] || warn "build dependencies missing on this host (makepkg cannot sudo here): $miss -> sudo pacman -S --needed --asdeps $miss"
for p in "${AUR[@]}"; do
  d="$CACHE/aur/$p"
  if compgen -G "$d/*.pkg.tar.zst" >/dev/null && [[ $(cd "$d" && makepkg --packagelist 2>/dev/null | head -1) == "$(command ls "$d"/*.pkg.tar.zst | head -1)" ]]; then
    ok "$p (cached)"; continue
  fi
  ( cd "$d" && rm -f ./*.pkg.tar.zst && makepkg -f --noconfirm --skippgpcheck -s >/dev/null 2>"$d/makepkg.log" ) && ok "$p built" || { warn "$p failed to build (see $d/makepkg.log)"; }
done

# ---- 4. repo pacman ----
step "Assembling the repo at $OUT"
rm -rf "$OUT"; mkdir -p "$OUT/repo" "$OUT/vendor"
for u in "${urls[@]}"; do f="$CACHE/pkg/$(basename "$u")"; ln -f "$f" "$OUT/repo/" 2>/dev/null || cp "$f" "$OUT/repo/"; [[ -f $f.sig ]] && { ln -f "$f.sig" "$OUT/repo/" 2>/dev/null || cp "$f.sig" "$OUT/repo/"; }; done
for p in "${AUR[@]}"; do for f in "$CACHE/aur/$p"/*.pkg.tar.zst; do [[ -f $f && $f != *-debug-* ]] && { ln -f "$f" "$OUT/repo/" 2>/dev/null || cp "$f" "$OUT/repo/"; }; done; done   # paket -debug tidak perlu
( cd "$OUT/repo" && repo-add -q -R resi-offline.db.tar.zst ./*.pkg.tar.zst >/dev/null )
ok "$(command ls "$OUT/repo"/*.pkg.tar.zst | wc -l) packages, $(du -sh "$OUT/repo" | cut -f1)"

# ---- 5. vendor clone git untuk install.sh ----
step "Vendoring git clones (oh-my-zsh, powerlevel10k, fzf-tab, tpm)"
while read -r name url; do
  d="$CACHE/vendor/$name"
  if [[ -d $d/.git ]]; then git -C "$d" pull -q --ff-only || true; else git clone -q --depth=1 "$url" "$d"; fi
  tar -C "$CACHE/vendor" -cf "$OUT/vendor/$name.tar" "$name"; ok "$name"
done <<'LIST'
ohmyzsh https://github.com/ohmyzsh/ohmyzsh.git
powerlevel10k https://github.com/romkatv/powerlevel10k.git
fzf-tab https://github.com/Aloxaf/fzf-tab
tpm https://github.com/tmux-plugins/tpm
LIST
printf 'built=%s\npackages=%s\naur=%s\n' "$(date -Is)" "$(command ls "$OUT/repo"/*.pkg.tar.zst | wc -l)" "${AUR[*]}" >"$OUT/manifest"
ok "offline mirror ready: $(du -sh "$OUT" | cut -f1)"
