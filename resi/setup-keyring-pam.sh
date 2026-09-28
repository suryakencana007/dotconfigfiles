#!/usr/bin/env bash
# Pasang pam_gnome_keyring (dijalankan installer dengan sudo; idempotent, aman diulang):
#   /etc/pam.d/greetd : keyring "login" dibuka otomatis dengan password login di layar greeter
#                       (dibuat otomatis dengan password itu pada login pertama)
#   /etc/pam.d/passwd : password keyring ikut berganti saat `passwd`
# Cadangan sekali sebagai <file>.pre-resi. Referensi: ArchWiki GNOME/Keyring, bagian PAM.
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "run as root (sudo)" >&2; exit 1; }
[[ -f /usr/lib/security/pam_gnome_keyring.so ]] || { echo "pam_gnome_keyring.so missing (install gnome-keyring)" >&2; exit 1; }

insert_after() { # $1 file, $2 regex baris jangkar, $3 baris baru. Tanpa jangkar: ditambah di akhir.
  local f="$1" pat="$2" line="$3" tmp
  [[ -f $f ]] || return 0
  grep -qF -- "$line" "$f" && return 0
  [[ -f $f.pre-resi ]] || cp -p "$f" "$f.pre-resi"
  tmp=$(mktemp)
  awk -v pat="$pat" -v line="$line" '{ print } $0 ~ pat && !done { print line; done = 1 } END { if (!done) print line }' "$f" >"$tmp"
  cat "$tmp" >"$f"; rm -f "$tmp"          # cat, bukan mv: izin dan pemilik file tetap
  echo "  $f: + $line"
}

insert_before() { # $1 file, $2 regex baris sasaran, $3 baris baru yang harus tepat di atasnya
  local f="$1" pat="$2" line="$3" tmp
  [[ -f $f ]] || return 0
  grep -qF -- "$line" "$f" && return 0
  [[ -f $f.pre-resi ]] || cp -p "$f" "$f.pre-resi"
  tmp=$(mktemp)
  awk -v pat="$pat" -v line="$line" '$0 ~ pat && !done { print line; done = 1 } { print }' "$f" >"$tmp"
  cat "$tmp" >"$f"; rm -f "$tmp"
  echo "  $f: + $line"
}

insert_after /etc/pam.d/greetd '^auth[[:space:]]+include'    'auth       optional     pam_gnome_keyring.so'
# session setelah pam_systemd: auto_start butuh XDG_RUNTIME_DIR yang disiapkan pam_systemd
insert_after /etc/pam.d/greetd '^session[[:space:]]+required[[:space:]]+pam_systemd' 'session    optional     pam_gnome_keyring.so auto_start'
# Layar greeter juga lewat PAM greetd sebagai user "greeter" (tanpa home): tanpa ini daemon keyring ikut jalan untuknya
# dan gagal ("unable to create keyring dir: /.local/share/keyrings"). success=1 = lewati satu baris berikutnya.
insert_before /etc/pam.d/greetd 'pam_gnome_keyring[.]so$'           'auth       [success=1 default=ignore] pam_succeed_if.so quiet user = greeter'
insert_before /etc/pam.d/greetd 'pam_gnome_keyring[.]so auto_start' 'session    [success=1 default=ignore] pam_succeed_if.so quiet user = greeter'
insert_after /etc/pam.d/passwd '^password[[:space:]]+include' 'password   optional     pam_gnome_keyring.so'
