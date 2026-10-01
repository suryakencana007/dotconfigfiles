#!/usr/bin/env bash
# Bangun ISO installer resi-shell di atas profil "releng" archiso (ISO resmi Arch) + overlay kita.
# Butuh: paket archiso, root (mkarchiso), ~10 GB ruang kerja, internet (mkarchiso mengunduh paket live).
#   sudo resi/iso/build.sh              -> resi/iso/out/resi-shell-<tanggal>-x86_64.iso (+ SHA256SUMS)
#   RESI_ISO_WORK=/path  RESI_ISO_OUT=/path   ubah lokasi kerja/keluaran
#   RESI_ISO_ONLINE=1                       lewati mirror offline (ISO kecil, instalasi butuh internet)
# Mirror offline (offline-repo.sh, dijalankan sebagai user pemanggil sudo karena makepkg menolak root) di-cache di
# resi/iso/cache/ dan dibakar ke /usr/share/resi-shell/{repo,vendor}. Instalasi dari ISO offline tidak butuh internet.
# Isi ISO: live Arch (releng) + archinstall + repo dotfiles ini (git archive HEAD) di /usr/share/resi-shell/.
# Installer live (resi-iso-install) berjalan otomatis di tty1 setelah boot.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$HERE/../.." && pwd)"
WORK="${RESI_ISO_WORK:-$HERE/work}"
OUT="${RESI_ISO_OUT:-$HERE/out}"
RELENG=/usr/share/archiso/configs/releng
PROFILE="$WORK/profile"

[[ $(id -u) -eq 0 ]] || { echo "run as root: sudo $0" >&2; exit 1; }
command -v mkarchiso >/dev/null || { echo "archiso is not installed: pacman -S archiso" >&2; exit 1; }
[[ -d $RELENG ]] || { echo "releng profile not found at $RELENG" >&2; exit 1; }

version="$(git -C "$REPO" describe --tags --always 2>/dev/null || date +%Y%m%d)"
stamp="$(date +%Y.%m.%d)"
echo "==> Staging profile ($PROFILE)"
rm -rf "$PROFILE"; mkdir -p "$PROFILE" "$OUT"
cp -a "$RELENG"/. "$PROFILE"/

# Paket tambahan di live ISO (installer): archinstall + alat kita
cat "$HERE/packages.extra" | sed -E 's/#.*//; /^\s*$/d' >>"$PROFILE/packages.x86_64"
sort -u -o "$PROFILE/packages.x86_64" "$PROFILE/packages.x86_64"

# Overlay airootfs: installer, motd, autostart di tty1
cp -a "$HERE/airootfs"/. "$PROFILE/airootfs"/

# Repo dotfiles dibakar ke ISO: file TERLACAK apa adanya di working tree (perubahan belum di-commit ikut, supaya
# skrip installer di airootfs dan install.sh di tarball selalu satu versi). File untracked tidak ikut: commit/add dulu.
mkdir -p "$PROFILE/airootfs/usr/share/resi-shell"
dirty=""; [[ -z $(git -C "$REPO" status --porcelain --untracked-files=no) ]] || dirty="-dirty"
untracked=$(git -C "$REPO" ls-files --others --exclude-standard | grep -v "^resi/iso/" || true)
[[ -z $untracked ]] || { echo "==> WARNING: untracked files are NOT baked into the ISO (git add them first):"; printf '    %s\n' $untracked; }
( cd "$REPO" && git ls-files -z | tar --null -T - -cf "$PROFILE/airootfs/usr/share/resi-shell/dotconfigfiles.tar" --transform 's|^|dotconfigfiles/|' )
cp "$REPO/resi/packages.pacman" "$PROFILE/airootfs/usr/share/resi-shell/dotconfigfiles.packages"
printf 'version=%s\nbuilt=%s\ncommit=%s\n' "$version$dirty" "$(date -Is)" "$(git -C "$REPO" rev-parse HEAD 2>/dev/null || echo unknown)$dirty" \
  >"$PROFILE/airootfs/usr/share/resi-shell/version"

# Mirror offline: closure paket + AUR (makepkg) + vendor clone; dibangun sebagai $SUDO_USER, lalu hardlink ke airootfs
if [[ ${RESI_ISO_ONLINE:-} != 1 ]]; then
  echo "==> Offline mirror (pacman -Sy, then offline-repo.sh as ${SUDO_USER:-root})"
  pacman -Sy >/dev/null
  mkdir -p "$HERE/cache"; [[ -n ${SUDO_USER:-} ]] && chown "$SUDO_USER:" "$HERE/cache"
  if [[ -n ${SUDO_USER:-} ]]; then
    # dependensi build paket AUR dipasang di sini (root); makepkg di bawah berjalan sebagai user tanpa sudo
    deps=$(runuser -u "$SUDO_USER" -- bash "$HERE/offline-repo.sh" --print-deps "$HERE/cache" 2>/dev/null)
    [[ -z $deps ]] || pacman -S --needed --noconfirm --asdeps $deps >/dev/null
    runuser -u "$SUDO_USER" -- bash "$HERE/offline-repo.sh" "$HERE/cache/offline" "$HERE/cache"
  else echo "offline-repo.sh must run as a normal user (makepkg); set RESI_ISO_ONLINE=1 or run build.sh via sudo from your user" >&2; exit 1; fi
  cp -al "$HERE/cache/offline/repo" "$PROFILE/airootfs/usr/share/resi-shell/repo" 2>/dev/null || cp -a "$HERE/cache/offline/repo" "$PROFILE/airootfs/usr/share/resi-shell/repo"
  cp -a "$HERE/cache/offline/vendor" "$PROFILE/airootfs/usr/share/resi-shell/vendor"
  cp "$HERE/cache/offline/manifest" "$PROFILE/airootfs/usr/share/resi-shell/offline-manifest"
  echo "    offline mirror: $(command ls "$PROFILE/airootfs/usr/share/resi-shell/repo"/*.pkg.tar.zst | wc -l) packages, $(du -sh "$HERE/cache/offline/repo" | cut -f1)"
fi
# Salinan pacman.conf live yang bersih, untuk dikembalikan ke target setelah instalasi offline
cp "$PROFILE/pacman.conf" "$PROFILE/airootfs/usr/share/resi-shell/pacman.conf.clean"

# profiledef: nama/label ISO + hak akses skrip kita
sed -i -e "s|^iso_name=.*|iso_name=\"resi-shell\"|" \
       -e "s|^iso_label=.*|iso_label=\"RESI_$(date +%Y%m)\"|" \
       -e "s|^iso_publisher=.*|iso_publisher=\"resi-shell <https://github.com/suryakencana007/dotconfigfiles>\"|" \
       -e "s|^iso_application=.*|iso_application=\"resi-shell installer\"|" \
       -e "s|^iso_version=.*|iso_version=\"$stamp\"|" "$PROFILE/profiledef.sh"
# file_permissions: tambahkan skrip kita (array bash di profiledef.sh)
sed -i "s|^file_permissions=(|file_permissions=(\n  [\"/usr/local/bin/resi-iso-install\"]=\"0:0:755\"\n  [\"/usr/local/bin/resi-iso-postinstall\"]=\"0:0:755\"\n  [\"/root/.zlogin\"]=\"0:0:644\"|" "$PROFILE/profiledef.sh"

# Branding menu boot ISO: "Resi Arch installer" (systemd-boot UEFI, GRUB, syslinux BIOS) + splash syslinux dari resi/boot
sed -i 's/Arch Linux install medium/Resi Arch installer/g' "$PROFILE"/efiboot/loader/entries/*.conf "$PROFILE"/grub/*.cfg "$PROFILE"/syslinux/*.cfg
sed -i 's/^MENU TITLE Arch Linux/MENU TITLE Resi Arch/' "$PROFILE/syslinux/archiso_head.cfg"
[[ -f $REPO/resi/boot/iso-splash.png ]] && cp "$REPO/resi/boot/iso-splash.png" "$PROFILE/syslinux/splash.png"

echo "==> mkarchiso (this takes a while and downloads the live packages)"
rm -rf "$WORK/tmp"; mkdir -p "$WORK/tmp"
rm -f "$OUT"/resi-shell-*.iso          # hanya ISO terbaru yang disimpan (glob out/resi-shell-*.iso di test-vm.sh jadi tidak ambigu)
mkarchiso -v -w "$WORK/tmp" -o "$OUT" "$PROFILE"
( cd "$OUT" && sha256sum -- *.iso >SHA256SUMS )
[[ -n ${SUDO_USER:-} ]] && chown -R "$SUDO_USER:" "$OUT"      # ISO dapat dipakai user tanpa sudo (test-vm.sh)
echo "==> Done: $(command ls "$OUT"/*.iso)"
echo "    Test in a VM: resi/iso/test-vm.sh $(command ls "$OUT"/*.iso | head -1)"
