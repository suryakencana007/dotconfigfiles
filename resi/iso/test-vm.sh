#!/usr/bin/env bash
# Uji ISO di qemu (UEFI, 4 GB RAM, disk virtual 40 GB). Butuh: qemu-desktop (atau qemu-base) + edk2-ovmf.
#   resi/iso/test-vm.sh resi/iso/out/resi-shell-*.iso      boot dari ISO (instalasi)
#   resi/iso/test-vm.sh                                     boot dari disk virtual hasil instalasi
#   RESI_VM_DISK=/path/x.qcow2                              disk lain (default ~/.local/state/resi/vm/resi-test.qcow2)
#   rm ~/.local/state/resi/vm/resi-test.qcow2               mulai dari disk kosong lagi
# Monitor QEMU: ~/.local/state/resi/vm/monitor.sock (contoh: printf "sendkey ctrl-alt-f2\n" | nc -U -q1 <sock>).
# SSH ke VM: port host 2222 -> 22 di VM. Di VM: sudo systemctl enable --now sshd; lalu dari host:
#   ssh -p 2222 <user>@127.0.0.1   (kunci: ~/.local/state/resi/vm/id_vm, lihat resi/iso/README.md)
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Disk VM milik user (bukan di resi/iso/work: itu dibuat root oleh mkarchiso)
DISK="${RESI_VM_DISK:-${XDG_STATE_HOME:-$HOME/.local/state}/resi/vm/resi-test.qcow2}"
OVMF=/usr/share/edk2/x64/OVMF_CODE.4m.fd; [[ -f $OVMF ]] || OVMF=/usr/share/edk2/x64/OVMF_CODE.fd
command -v qemu-system-x86_64 >/dev/null || { echo "install qemu-desktop and edk2-ovmf" >&2; exit 1; }
[[ -f $OVMF ]] || { echo "OVMF firmware not found (pacman -S edk2-ovmf)" >&2; exit 1; }
mkdir -p "$(dirname "$DISK")"; [[ -f $DISK ]] || qemu-img create -f qcow2 "$DISK" 40G >/dev/null
# Monitor QEMU di socket (kirim tombol dari host: echo "sendkey ctrl-alt-f2" | socat - UNIX-CONNECT:$MON, atau nc -U)
MON="${RESI_VM_MONITOR:-$(dirname "$DISK")/monitor.sock}"
args=( -enable-kvm -cpu host -smp 4 -m 4G -machine q35 -drive "if=pflash,format=raw,readonly=on,file=$OVMF" -monitor "unix:$MON,server,nowait"
       -drive "file=$DISK,if=virtio,format=qcow2" -device virtio-vga-gl -display gtk,gl=on
       -nic user,model=virtio-net-pci,hostfwd=tcp:127.0.0.1:2222-:22 -audiodev pipewire,id=snd0 -device intel-hda -device hda-output,audiodev=snd0 )
# Beberapa ISO (glob out/resi-shell-*.iso cocok dengan build lama juga): boot yang TERBARU, bukan argumen pertama
iso=""; if (( $# > 1 )); then iso=$(ls -t -- "$@" | head -1); echo "several ISOs given, booting the newest: $iso"; elif (( $# == 1 )); then iso=$1; fi
if [[ -n $iso ]]; then args+=( -cdrom "$iso" -boot d ); fi
exec qemu-system-x86_64 "${args[@]}"
