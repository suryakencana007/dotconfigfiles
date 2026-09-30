#!/usr/bin/env bash
# Uji ISO di qemu (UEFI, 4 GB RAM, disk virtual 40 GB). Butuh: qemu-desktop (atau qemu-base) + edk2-ovmf.
#   resi/iso/test-vm.sh resi/iso/out/resi-shell-*.iso      boot dari ISO (instalasi)
#   resi/iso/test-vm.sh                                     boot dari disk virtual hasil instalasi
#   RESI_VM_DISK=/path/x.qcow2                              disk lain (default ~/.local/state/resi/vm/resi-test.qcow2)
#   rm ~/.local/state/resi/vm/resi-test.qcow2               mulai dari disk kosong lagi
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Disk VM milik user (bukan di resi/iso/work: itu dibuat root oleh mkarchiso)
DISK="${RESI_VM_DISK:-${XDG_STATE_HOME:-$HOME/.local/state}/resi/vm/resi-test.qcow2}"
OVMF=/usr/share/edk2/x64/OVMF_CODE.4m.fd; [[ -f $OVMF ]] || OVMF=/usr/share/edk2/x64/OVMF_CODE.fd
command -v qemu-system-x86_64 >/dev/null || { echo "install qemu-desktop and edk2-ovmf" >&2; exit 1; }
[[ -f $OVMF ]] || { echo "OVMF firmware not found (pacman -S edk2-ovmf)" >&2; exit 1; }
mkdir -p "$(dirname "$DISK")"; [[ -f $DISK ]] || qemu-img create -f qcow2 "$DISK" 40G >/dev/null
args=( -enable-kvm -cpu host -smp 4 -m 4G -machine q35 -drive "if=pflash,format=raw,readonly=on,file=$OVMF"
       -drive "file=$DISK,if=virtio,format=qcow2" -device virtio-vga-gl -display gtk,gl=on
       -nic user,model=virtio-net-pci -audiodev pipewire,id=snd0 -device intel-hda -device hda-output,audiodev=snd0 )
if [[ -n ${1:-} ]]; then args+=( -cdrom "$1" -boot d ); fi
exec qemu-system-x86_64 "${args[@]}"
