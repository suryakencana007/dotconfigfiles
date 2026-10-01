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
# Termasuk dependensi runtime paket AUR (spotify butuh libcurl-gnutls/libayatana-*, noctalia-greeter wlroots0.20):
# tanpa ini pacman di chroot menolak seluruh transaksi AUR (pelajaran dari VM 2026-09-30).
step "Resolving the package closure"
DB="$CACHE/db"; mkdir -p "$DB/sync" "$DB/local"
cp -u /var/lib/pacman/sync/*.db "$DB/sync/"
aur_clone
aur_runtime_deps() { local p; for p in "${AUR[@]}"; do ( cd "$CACHE/aur/$p" && makepkg --printsrcinfo 2>/dev/null | awk -F" = " '/^[[:space:]]*depends = /{print $2}' | sed 's/[<>=].*//' ); done | sort -u; }
official_aur_deps=(); for d in $(aur_runtime_deps); do pacman -Sp --dbpath "$DB" --logfile /dev/null "$d" >/dev/null 2>&1 && official_aur_deps+=("$d"); done
TARGETS=( base base-devel linux linux-firmware linux-headers limine btrfs-progs snapper efibootmgr dosfstools
          networkmanager sudo git zsh mesa vulkan-radeon vulkan-intel intel-media-driver libva-mesa-driver
          amd-ucode intel-ucode nvidia-open-dkms nvidia-utils $(pkglist "$REPO/resi/packages.pacman") "${official_aur_deps[@]}" )
mapfile -t urls < <(pacman -Sp --dbpath "$DB" --logfile /dev/null "${TARGETS[@]}")
ok "${#urls[@]} packages in the closure (incl. ${#official_aur_deps[@]} runtime deps of the AUR packages)"

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

# ---- 2b. verifikasi tanda tangan: installer memakai SigLevel = Never (keyring target kosong saat pacstrap -K dan tanpa
# jaringan kunci tidak bisa diambil), jadi di sinilah satu-satunya pemeriksaan paket resmi. gpgv terhadap keyring pacman host.
step "Verifying package signatures (gpgv, host pacman keyring)"
KEYRING=/etc/pacman.d/gnupg/pubring.gpg
if [[ -r $KEYRING ]] && command -v gpgv >/dev/null; then
  failed=$(for u in "${urls[@]}"; do basename "$u"; done | xargs -r -P 8 -I{} sh -c 'cd "$1" && gpgv --keyring "$2" "{}.sig" "{}" >/dev/null 2>&1 || echo "{}"' _ "$CACHE/pkg" "$KEYRING")
  if [[ -n $failed ]]; then warn "bad or missing signature:"; printf '%s\n' "$failed" | head -10 | sed 's/^/    /'; echo "delete these from $CACHE/pkg and run again" >&2; exit 1; fi
  ok "${#urls[@]} signatures good"
else warn "gpgv or $KEYRING not available: package signatures NOT verified"; fi

# ---- 3. paket AUR: makepkg di host (dependensi build harus sudah ada di host) ----
step "Building AUR packages"
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
# ---- 5b. plugin Noctalia yang aktif (noctalia/.config/noctalia/plugins.toml) ----
# Noctalia mengunduh plugin dari GitHub saat diaktifkan; tanpa jaringan widget/panelnya hilang. Kita bawa state yang sama
# dengan yang dibuat Noctalia sendiri: plugins/sources/official/repo (klon blob:none tanpa checkout; blob katalog dan
# plugin sudah terambil, FETCH_HEAD ada) dan plugins/materialized/official/<plugin> (ekspor direktori plugin pada HEAD).
step "Vendoring Noctalia plugins"
mapfile -t nplugins < <(sed -n 's/^enabled *= *\[\(.*\)\]/\1/p' "$REPO/noctalia/.config/noctalia/plugins.toml" | tr -d '" ' | tr ',' '\n' | grep . || true)
NP="$CACHE/vendor/noctalia-plugins"; NR="$NP/plugins/sources/official/repo"
rm -rf "$NP"; mkdir -p "$NP/plugins/sources/official" "$NP/plugins/materialized/official"
git clone -q --no-checkout --filter=blob:none https://github.com/noctalia-dev/official-plugins "$NR"
git -C "$NR" fetch -q origin; git -C "$NR" show HEAD:catalog.toml >/dev/null
for p in "${nplugins[@]}"; do
  if [[ $p == noctalia/* ]] && git -C "$NR" cat-file -e "HEAD:${p#noctalia/}/plugin.toml" 2>/dev/null; then
    git -C "$NR" archive HEAD "${p#noctalia/}" | tar -x -C "$NP/plugins/materialized/official/"; ok "$p $(sed -n 's/^version *= *"\(.*\)"/\1/p' "$NP/plugins/materialized/official/${p#noctalia/}/plugin.toml")"
  else warn "$p is not an official plugin; not vendored (Noctalia fetches it when online)"; fi
done
tar -C "$NP" -cf "$OUT/vendor/noctalia-plugins.tar" plugins

# ---- 6. verifikasi: semua target + paket AUR harus terpasang HANYA dari repo offline (seperti di chroot tanpa jaringan) ----
step "Verifying the closure against the offline repo alone"
VDB="$CACHE/verify-db"; rm -rf "$VDB"; mkdir -p "$VDB/sync" "$VDB/local"; cp "$OUT/repo/resi-offline.db" "$VDB/sync/resi-offline.db"
printf '[options]\nArchitecture = auto\n\n[resi-offline]\nSigLevel = Never\nServer = file://%s/repo\n' "$OUT" >"$CACHE/verify.conf"
if pacman -Sp --config "$CACHE/verify.conf" --dbpath "$VDB" --logfile /dev/null "${TARGETS[@]}" "${AUR[@]}" >/dev/null 2>"$CACHE/verify.log"; then ok "every target resolves from the offline repo"
else warn "unresolvable from the offline repo (installation would fail offline):"; grep -iE "error|unable|not found" "$CACHE/verify.log" | head -10 | sed 's/^/    /'; exit 1; fi
printf 'built=%s\npackages=%s\naur=%s\n' "$(date -Is)" "$(command ls "$OUT/repo"/*.pkg.tar.zst | wc -l)" "${AUR[*]}" >"$OUT/manifest"
ok "offline mirror ready: $(du -sh "$OUT" | cut -f1)"
