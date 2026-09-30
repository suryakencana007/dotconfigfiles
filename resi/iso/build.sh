#!/usr/bin/env bash
# Bangun ISO installer resi-shell di atas profil "releng" archiso (ISO resmi Arch) + overlay kita.
# Butuh: paket archiso, root (mkarchiso), ~10 GB ruang kerja, internet (mkarchiso mengunduh paket live).
#   sudo resi/iso/build.sh              -> resi/iso/out/resi-shell-<tanggal>-x86_64.iso (+ SHA256SUMS)
#   RESI_ISO_WORK=/path  RESI_ISO_OUT=/path   ubah lokasi kerja/keluaran
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

# Repo dotfiles dibakar ke ISO (commit HEAD; perubahan belum di-commit tidak ikut)
mkdir -p "$PROFILE/airootfs/usr/share/resi-shell"
git -C "$REPO" archive --format=tar --prefix=dotconfigfiles/ HEAD >"$PROFILE/airootfs/usr/share/resi-shell/dotconfigfiles.tar"
cp "$REPO/resi/packages.pacman" "$PROFILE/airootfs/usr/share/resi-shell/dotconfigfiles.packages"
printf 'version=%s\nbuilt=%s\ncommit=%s\n' "$version" "$(date -Is)" "$(git -C "$REPO" rev-parse HEAD 2>/dev/null || echo unknown)" \
  >"$PROFILE/airootfs/usr/share/resi-shell/version"

# profiledef: nama/label ISO + hak akses skrip kita
sed -i -e "s|^iso_name=.*|iso_name=\"resi-shell\"|" \
       -e "s|^iso_label=.*|iso_label=\"RESI_$(date +%Y%m)\"|" \
       -e "s|^iso_publisher=.*|iso_publisher=\"resi-shell <https://github.com/suryakencana007/dotconfigfiles>\"|" \
       -e "s|^iso_application=.*|iso_application=\"resi-shell installer\"|" \
       -e "s|^iso_version=.*|iso_version=\"$stamp\"|" "$PROFILE/profiledef.sh"
# file_permissions: tambahkan skrip kita (array bash di profiledef.sh)
sed -i "s|^file_permissions=(|file_permissions=(\n  [\"/usr/local/bin/resi-iso-install\"]=\"0:0:755\"\n  [\"/usr/local/bin/resi-iso-postinstall\"]=\"0:0:755\"\n  [\"/root/.zlogin\"]=\"0:0:644\"|" "$PROFILE/profiledef.sh"

echo "==> mkarchiso (this takes a while and downloads the live packages)"
rm -rf "$WORK/tmp"; mkdir -p "$WORK/tmp"
mkarchiso -v -w "$WORK/tmp" -o "$OUT" "$PROFILE"
( cd "$OUT" && sha256sum -- *.iso >SHA256SUMS )
[[ -n ${SUDO_USER:-} ]] && chown -R "$SUDO_USER:" "$OUT"      # ISO dapat dipakai user tanpa sudo (test-vm.sh)
echo "==> Done: $(command ls "$OUT"/*.iso)"
echo "    Test in a VM: resi/iso/test-vm.sh $(command ls "$OUT"/*.iso | head -1)"
