#!/usr/bin/env bash
# Boot splash "Resi Arch" ala Omarchy. Dijalankan root oleh `resi-shell install` (langkah boot_splash); idempoten.
#   1. tema Plymouth resi → /usr/share/plymouth/themes/resi, dijadikan default
#   2. hook `plymouth` di HOOKS mkinitcpio (tepat setelah systemd/udev, jadi sebelum encrypt/sd-encrypt)
#   3. `quiet splash` di cmdline kernel: baris `cmdline:` limine.conf dan /etc/kernel/cmdline (UKI)
#   4. branding Limine: interface_branding + judul entry "Resi Arch" (blok bertanda di atas limine.conf)
#   5. splash UKI (systemd-stub): preset mkinitcpio yang memakai --splash diarahkan ke splash.bmp kita
#   6. mkinitcpio -P bila ada yang berubah (tema ikut masuk initramfs)
#   sudo resi/boot/setup-boot-splash.sh            pasang
#   sudo resi/boot/setup-boot-splash.sh --check    hanya lapor keadaan (exit 1 bila belum lengkap), tidak mengubah apa pun
#   sudo resi/boot/setup-boot-splash.sh --remove   lepas: hook, `splash`, branding, tema default kembali ke bawaan
# File yang diubah dicadangkan sekali sebagai <file>.resi-bak. /etc/os-release tidak disentuh (tetap Arch).
# Uji tanpa root: RESI_BOOT_ROOT=/dir/palsu (berisi etc/, boot/) → semua path di bawahnya, plymouth/mkinitcpio tidak dipanggil.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="${RESI_BOOT_ROOT:-}"
THEME_SRC="$HERE/plymouth/resi"; THEME_PATH=/usr/share/plymouth/themes/resi; THEME_DST="$ROOT$THEME_PATH"
MODE=install; case "${1:-}" in --check) MODE=check ;; --remove) MODE=remove ;; "") ;; *) echo "usage: setup-boot-splash.sh [--check|--remove]" >&2; exit 2 ;; esac
BRAND_BEGIN="# >>> resi-shell branding (managed by resi/boot/setup-boot-splash.sh)"; BRAND_END="# <<< resi-shell branding"

say()  { printf '  %s\n' "$*"; }
changed=0; missing=0
backup() { [[ -e $1.resi-bak ]] || cp "$1" "$1.resi-bak"; }      # cp polos: /boot (vfat) tidak bisa menyimpan pemilik
# rewrite <file> <program awk>: tulis ulang file lewat awk hanya bila hasilnya berbeda (cadangan dulu)
rewrite() {
  local f=$1 tmp; shift; tmp=$(mktemp)
  awk "$@" "$f" >"$tmp"
  if cmp -s "$f" "$tmp"; then rm -f "$tmp"; return 1; fi
  if [[ $MODE == check ]]; then rm -f "$tmp"; return 0; fi
  backup "$f"; cat "$tmp" >"$f"; rm -f "$tmp"; return 0      # cat, bukan mv: pertahankan pemilik/izin (vfat di /boot)
}

if [[ -n $ROOT ]]; then      # mode uji: tema default disimpan di file, initramfs tidak dibangun
  theme_current() { cat "$ROOT/etc/plymouth-theme" 2>/dev/null || echo bgrt; }
  theme_set() { if [[ $1 == -r ]]; then rm -f "$ROOT/etc/plymouth-theme"; else echo "$1" >"$ROOT/etc/plymouth-theme"; fi; }
  rebuild() { say "(test root: mkinitcpio -P skipped)"; }
else
  (( EUID == 0 )) || { echo "run as root (sudo)" >&2; exit 1; }       # /boot hanya terbaca root, jadi --check pun butuh root
  command -v plymouth-set-default-theme >/dev/null || { echo "plymouth is not installed (pacman -S plymouth)" >&2; exit 1; }
  theme_current() { plymouth-set-default-theme; }
  theme_set() { plymouth-set-default-theme "$@" >/dev/null; }
  rebuild() { mkinitcpio -P; }
fi
KCMDLINE="$ROOT/etc/kernel/cmdline"

mapfile -t LIMINE_CONFS < <(find "$ROOT/boot" "$ROOT/efi" -maxdepth 4 -name limine.conf 2>/dev/null | sort -u)
mapfile -t HOOK_FILES < <(grep -lE '^HOOKS=' "$ROOT/etc/mkinitcpio.conf" "$ROOT"/etc/mkinitcpio.conf.d/*.conf 2>/dev/null || true)
mapfile -t PRESETS < <(grep -lE -- '--splash' "$ROOT"/etc/mkinitcpio.d/*.preset 2>/dev/null || true)
# awk: buang blok branding lama (dan satu baris kosong sesudahnya) supaya blok bisa ditulis ulang / dilepas
STRIP_BRAND='$0 == b { skip = 1; next } $0 == e { skip = 0; eat = 1; next } skip { next } eat { eat = 0; if ($0 == "") next }'

# ---------- lepas ----------
if [[ $MODE == remove ]]; then
  for f in "${HOOK_FILES[@]}"; do rewrite "$f" '/^HOOKS=/ { gsub(/ plymouth/, "") } { print }' && { say "removed the plymouth hook from $f"; changed=1; }; done
  for f in "${LIMINE_CONFS[@]}" "$KCMDLINE"; do
    [[ -f $f ]] || continue
    rewrite "$f" -v b="$BRAND_BEGIN" -v e="$BRAND_END" "$STRIP_BRAND"'
      /^\/Resi Arch/ { sub(/^\/Resi Arch/, "/Arch Linux") }
      { gsub(/ splash( |$)/, " "); sub(/ +$/, ""); print }' && { say "removed splash/branding from $f"; changed=1; }
  done
  for f in "${PRESETS[@]}"; do rewrite "$f" -v t="$THEME_PATH/splash.bmp" '{ gsub(t, "/usr/share/systemd/bootctl/splash-arch.bmp"); print }' && { say "UKI splash back to the Arch default in $f"; changed=1; }; done
  if [[ $(theme_current) == resi ]]; then theme_set -r; say "plymouth theme reset to the default"; changed=1; fi
  rm -rf "$THEME_DST"
  if (( changed )); then say "rebuilding the initramfs"; rebuild; else say "nothing to remove"; fi
  exit 0
fi

# ---------- 1. tema ----------
if ! diff -rq "$THEME_SRC" "$THEME_DST" >/dev/null 2>&1; then
  if [[ $MODE == check ]]; then say "theme not installed (or outdated): $THEME_DST"; missing=1
  else rm -rf "$THEME_DST"; install -d -m755 "$THEME_DST"; install -m644 "$THEME_SRC"/* "$THEME_DST"/; say "plymouth theme installed: $THEME_DST"; changed=1; fi
fi
if [[ $(theme_current) != resi ]]; then
  if [[ $MODE == check ]]; then say "default plymouth theme is '$(theme_current)', not resi"; missing=1
  else theme_set resi; say "default plymouth theme: resi"; changed=1; fi
fi

# ---------- 2. hook mkinitcpio ----------
(( ${#HOOK_FILES[@]} )) || { say "no HOOKS= line found in /etc/mkinitcpio.conf(.d); plymouth hook not added"; missing=1; }
for f in "${HOOK_FILES[@]}"; do
  # sisipkan setelah systemd (initramfs systemd) atau udev (busybox); kalau keduanya tidak ada, setelah base
  rewrite "$f" '/^HOOKS=/ && $0 !~ /[( ]plymouth[ )]/ {
      if      ($0 ~ /[( ]systemd[ )]/) sub(/systemd/, "systemd plymouth")
      else if ($0 ~ /[( ]udev[ )]/)    sub(/udev/, "udev plymouth")
      else                             sub(/base/, "base plymouth") } { print }' \
    && { if [[ $MODE == check ]]; then say "plymouth hook missing in $f"; missing=1; else say "plymouth hook added: $(grep -E '^HOOKS=' "$f")"; changed=1; fi; }
done

# ---------- 3 + 4. cmdline dan branding Limine ----------
add_params='{ if ($0 !~ /(^|[[:space:]])quiet([[:space:]]|$)/) $0 = $0 " quiet"; if ($0 !~ /(^|[[:space:]])splash([[:space:]]|$)/) $0 = $0 " splash" }'
(( ${#LIMINE_CONFS[@]} )) || [[ -f $KCMDLINE ]] || { say "no limine.conf under /boot or /efi and no /etc/kernel/cmdline: add 'quiet splash' to the kernel command line by hand"; missing=1; }
for f in "${LIMINE_CONFS[@]}"; do
  rewrite "$f" "/^[[:space:]]*(cmdline|kernel_cmdline):/ $add_params { print }" \
    && { if [[ $MODE == check ]]; then say "'quiet splash' missing in $f"; missing=1; else say "kernel cmdline: quiet splash ($f)"; changed=1; fi; }
  # blok branding di paling atas (opsi global Limine harus sebelum entry pertama); blok lama dibuang dulu supaya bisa diperbarui
  rewrite "$f" -v b="$BRAND_BEGIN" -v e="$BRAND_END" '
    BEGIN { print b; print "interface_branding: Resi Arch"; print "interface_branding_colour: e6e6ea"; print "interface_help_hidden: yes"
            print "term_background: 000000"; print "term_foreground: e6e6ea"; print "backdrop: 000000"; print e; print "" }'"$STRIP_BRAND"'
    /^\/Arch Linux/ { sub(/^\/Arch Linux/, "/Resi Arch") }
    { print }' \
    && { if [[ $MODE == check ]]; then say "Limine branding missing in $f"; missing=1; else say "Limine branding: Resi Arch ($f)"; fi; }
done
if [[ -f $KCMDLINE ]]; then
  rewrite "$KCMDLINE" "NF $add_params { print }" \
    && { if [[ $MODE == check ]]; then say "'quiet splash' missing in /etc/kernel/cmdline"; missing=1; else say "kernel cmdline: quiet splash (/etc/kernel/cmdline, UKI)"; changed=1; fi; }
fi

# ---------- 5. splash UKI ----------
for f in "${PRESETS[@]}"; do
  rewrite "$f" -v t="$THEME_PATH/splash.bmp" '{ gsub(/--splash[= ]+[^ "\047)]+/, "--splash " t); print }' \
    && { if [[ $MODE == check ]]; then say "UKI splash in $f is not the Resi one"; missing=1; else say "UKI splash: $THEME_PATH/splash.bmp ($f)"; changed=1; fi; }
done

# ---------- 6. initramfs ----------
if [[ $MODE == check ]]; then (( missing )) && exit 1; say "boot splash fully set up"; exit 0; fi
if (( changed )); then say "rebuilding the initramfs (mkinitcpio -P)"; rebuild; else say "nothing to change"; fi
