#!/usr/bin/env bash
# resi-shell installer: pasang dan setel seluruh desktop dari repo dotfiles ini (Arch Linux).
# Idempotent: aman dijalankan berulang. Butuh: Arch dasar terpasang, user dengan sudo, koneksi internet.
#
#   ./install.sh [install] [--dry-run|-n]   semua tahap
#   ./install.sh update                     git pull + paket + stow + plugin
#   ./install.sh doctor                     cek kondisi tanpa mengubah apa pun
#   ./install.sh packages                   daftar paket
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMD="install"; DRY=0
for a in "$@"; do case "$a" in install|update|doctor|packages) CMD="$a" ;; --dry-run|-n) DRY=1 ;; -h|--help) sed -n '2,9p' "$0"; exit 0 ;; *) echo "argumen tidak dikenal: $a" >&2; exit 2 ;; esac; done

PKGS_FOLD=(zsh git alacritty tmux nvim rofi mpv)            # stow biasa (folder boleh dilipat)
PKGS_NOFOLD=(hypr noctalia claude bin gtk)                 # --no-folding: folder tetap nyata (overlay host & file render bisa masuk)
HOST="$(cat /etc/hostname 2>/dev/null || hostname)"

c_step=$'\e[1;34m'; c_ok=$'\e[1;32m'; c_warn=$'\e[1;33m'; c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_step" "$*" "$c_off"; }
ok()   { printf '%s  ✓ %s%s\n' "$c_ok" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_warn" "$*" "$c_off"; }
run()  { if (( DRY )); then printf '  [dry] %s\n' "$*"; else "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }
pkglist() { grep -vE '^\s*#|^\s*$' "$1"; }
in_repo() { case "$(realpath -m "$1" 2>/dev/null)" in "$REPO"/*) return 0 ;; *) return 1 ;; esac; }   # path (setelah symlink) ada di dalam repo?

require_arch() { have pacman || { echo "Bukan Arch Linux (pacman tidak ada)."; exit 1; }; }

sudo_keepalive() {
  (( DRY )) && return 0
  sudo -v || { echo "sudo diperlukan."; exit 1; }
  ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
}

# ---------- tahap ----------
pacman_packages() {
  step "Paket repo resmi ($(pkglist "$REPO/resi/packages.pacman" | wc -l))"
  run sudo pacman -Syu --needed --noconfirm $(pkglist "$REPO/resi/packages.pacman")
  ok "pacman selesai"
}

aur_helper() {
  step "AUR helper (yay)"
  if have yay; then ok "yay sudah ada"; return; fi
  local tmp; tmp="$(mktemp -d)"
  run git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (( DRY )) || (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  ok "yay terpasang"
}

aur_packages() {
  step "Paket AUR ($(pkglist "$REPO/resi/packages.aur" | wc -l))"
  run yay -S --needed --noconfirm $(pkglist "$REPO/resi/packages.aur")
  ok "AUR selesai"
}

gpu_drivers() {
  step "Driver GPU (deteksi otomatis)"
  local pci; pci="$(lspci -nn 2>/dev/null | grep -iE 'vga|3d controller|display' || true)"
  echo "$pci" | sed 's/^/  /'
  if grep -qi nvidia <<<"$pci"; then
    # Turing+ memakai nvidia-open; DKMS butuh headers kernel yang berjalan.
    run sudo pacman -S --needed --noconfirm linux-headers nvidia-open-dkms nvidia-utils
    if ! grep -qE '^MODULES=\(.*nvidia' /etc/mkinitcpio.conf; then
      run sudo sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
      run sudo sed -i 's/^MODULES=( /MODULES=(/' /etc/mkinitcpio.conf
      run sudo mkinitcpio -P
    fi
    ok "NVIDIA: nvidia-open-dkms + early KMS"
  fi
  if grep -qiE 'amd|ati' <<<"$pci"; then
    run sudo pacman -S --needed --noconfirm mesa vulkan-radeon libva-mesa-driver
    ok "AMD: mesa + vulkan-radeon"
  fi
  if grep -qi intel <<<"$pci"; then
    run sudo pacman -S --needed --noconfirm mesa vulkan-intel intel-media-driver
    ok "Intel: mesa + vulkan-intel"
  fi
  # CPU microcode
  if grep -qi amd /proc/cpuinfo; then run sudo pacman -S --needed --noconfirm amd-ucode; else run sudo pacman -S --needed --noconfirm intel-ucode; fi
}

shell_setup() {
  step "zsh, oh-my-zsh, powerlevel10k, fzf-tab"
  local omz="$HOME/.oh-my-zsh"
  [ -d "$omz" ] || run git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git "$omz"
  [ -d "$omz/custom/themes/powerlevel10k" ] || run git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$omz/custom/themes/powerlevel10k"
  [ -d "$omz/custom/plugins/fzf-tab" ] || run git clone --depth=1 https://github.com/Aloxaf/fzf-tab "$omz/custom/plugins/fzf-tab"
  run mkdir -p "$omz/custom/plugins"
  run ln -sfn /usr/share/zsh/plugins/zsh-autosuggestions "$omz/custom/plugins/zsh-autosuggestions"
  run ln -sfn /usr/share/zsh/plugins/zsh-syntax-highlighting "$omz/custom/plugins/zsh-syntax-highlighting"
  # .zshrc bawaan oh-my-zsh akan digantikan symlink stow; singkirkan kalau bukan symlink
  [ -f "$HOME/.zshrc" ] && [ ! -L "$HOME/.zshrc" ] && ! in_repo "$HOME/.zshrc" && run mv "$HOME/.zshrc" "$HOME/.zshrc.pre-resi"
  if [ "$(getent passwd "$USER" | cut -d: -f7)" != "/usr/bin/zsh" ]; then run chsh -s /usr/bin/zsh; fi
  ok "shell siap"
}

stow_all() {
  step "Stow config ke \$HOME"
  # file biasa yang akan bentrok dengan symlink -> disingkirkan ke *.pre-resi.
  # Lewati kalau path itu sudah berada di dalam repo (mis. ~/.config/tmux adalah symlink folder ke repo,
  # sehingga tmux.conf terlihat sebagai file biasa): memindahkannya berarti menghapus file di repo.
  for f in .zshrc .p10k.zsh .gitconfig .config/alacritty/alacritty.toml .config/tmux/tmux.conf; do
    [ -e "$HOME/$f" ] && [ ! -L "$HOME/$f" ] && ! in_repo "$HOME/$f" && run mv "$HOME/$f" "$HOME/$f.pre-resi"
  done
  # folder nyata hanya disingkirkan kalau BUKAN hasil stow (tidak berisi symlink ke repo ini)
  for d in hypr noctalia nvim rofi; do
    t="$HOME/.config/$d"
    if [ -d "$t" ] && [ ! -L "$t" ] && ! find "$t" -maxdepth 1 -type l -lname "*$(basename "$REPO")*" 2>/dev/null | grep -q .; then
      run mv "$t" "$t.pre-resi"
    fi
  done
  run mkdir -p "$HOME/.config" "$HOME/.local/bin" "$HOME/.claude"
  (cd "$REPO" && run stow --restow -t "$HOME" "${PKGS_FOLD[@]}")
  (cd "$REPO" && run stow --restow --no-folding -t "$HOME" "${PKGS_NOFOLD[@]}")
  if [ -d "$REPO/hosts/$HOST" ]; then
    (cd "$REPO/hosts" && run stow --restow --no-folding -t "$HOME" "$HOST"); ok "overlay host: $HOST"
  else
    warn "tidak ada overlay untuk host '$HOST' (opsional: buat hosts/$HOST/)"
  fi
  ok "stow selesai"
}

tmux_plugins() {
  step "tmux: TPM + plugin"
  local tpm="$HOME/.config/tmux/plugins/tpm"
  [ -d "$tpm" ] || run git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm"
  (( DRY )) || "$tpm/bin/install_plugins" >/dev/null 2>&1 || true
  ok "tmux siap"
}

nvim_plugins() {
  step "neovim: plugin (lazy.nvim headless)"
  (( DRY )) || GIT_TERMINAL_PROMPT=0 timeout 300 nvim --headless "+Lazy! install" +qa >/dev/null 2>&1 || warn "lazy install gagal/timeout; jalankan nvim lalu :Lazy sync"
  ok "nvim siap"
}

dirs_and_git() {
  step "Folder & identitas git"
  run mkdir -p "$HOME/Pictures/Screenshots" "$HOME/Pictures/Wallpapers"
  if [ -z "$(git config --global user.name 2>/dev/null)" ] && [ -z "$(git -C "$REPO" config user.name 2>/dev/null)" ]; then
    if (( DRY )); then echo "  [dry] akan bertanya nama & email git"; else
      read -rp "  git user.name : " gname; read -rp "  git user.email: " gmail
      git -C "$REPO" config user.name "$gname"; git -C "$REPO" config user.email "$gmail"
    fi
  fi
  ok "folder siap"
}

services() {
  step "Layanan sistem"
  for s in NetworkManager bluetooth power-profiles-daemon greetd; do run sudo systemctl enable "$s" >/dev/null 2>&1 || warn "gagal enable $s"; done
  run sudo install -Dm644 "$REPO/resi/greetd-config.toml" /etc/greetd/config.toml
  ok "greetd + layanan aktif"
}

gtk_theme() {
  step "Tema GTK (adw-gtk3 + Papirus, mode gelap)"
  # Warna GTK dirender template builtin Noctalia gtk3/gtk4 (aktifkan di Settings > Templates; tersimpan di state).
  # Hook Noctalia yang menyetel gtk-theme adw-gtk3-dark saat tema berganti; ikon dan mode gelap diset di sini.
  have gsettings || { warn "gsettings tidak ada"; return; }
  run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  [ -d /usr/share/themes/adw-gtk3-dark ] && run gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
  [ -d /usr/share/icons/Papirus-Dark ] && run gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
  ok "GTK gelap + Papirus"
  if have mpv; then
    for m in video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo audio/mpeg audio/flac audio/ogg audio/x-wav audio/mp4; do run xdg-mime default mpv.desktop "$m"; done
    ok "mpv jadi pemutar default video/audio"
  fi
}

greeter() {
  step "Noctalia Greeter"
  if ! have noctalia-greeter; then warn "noctalia-greeter belum terpasang (AUR)"; return; fi
  local tmp; tmp="$(mktemp)"; sed "s/__USER__/$USER/" "$REPO/resi/greeter.toml" >"$tmp"
  run sudo install -o greeter -g greeter -m 644 "$tmp" /var/lib/noctalia-greeter/greeter.toml; rm -f "$tmp"
  run sudo noctalia-greeter passwordless-sync enable "$USER" || warn "passwordless-sync gagal (greeter < 1.5?)"
  ok "greeter.toml + sync tanpa password"
  # Auto-sync dinyalakan oleh noctalia/greeter.toml; sync pertama harus dipicu sekali kalau shell sedang jalan
  # (tanpa ini greeter tampil bawaan sampai tema berubah, karena /var/lib/noctalia-greeter/sync.toml belum ada).
  if have noctalia && noctalia msg status >/dev/null 2>&1; then
    if (( DRY )); then run noctalia msg greeter-sync; else noctalia msg greeter-sync >/dev/null 2>&1 && ok "greeter di-sync dengan tema saat ini"; fi || warn "greeter-sync gagal; jalankan: noctalia msg greeter-sync"
  else
    echo "  (Noctalia belum jalan: sync pertama otomatis saat wallpaper/tema pertama dipilih, atau: noctalia msg greeter-sync)"
  fi
}

finish() {
  step "Selesai"
  cat <<MSG
  Langkah manual yang tidak bisa diotomatisasi:
   - Reboot (driver GPU, greetd, shell login).
   - Login pertama: Noctalia setup wizard (wallpaper ke ~/Pictures/Wallpapers, tema). Auto-sync greeter sudah aktif
     lewat noctalia/greeter.toml; kalau layar login masih bawaan: noctalia msg greeter-sync. Template warna (hyprland, alacritty, gtk3, gtk4, btop) diaktifkan
     noctalia/templates.toml; kalau wizard menulis daftar sendiri, cek Settings > Templates supaya Hyprland,
     Alacritty, GTK 3, GTK 4 aktif (kalau tidak, border & aplikasi tidak ikut ganti warna).
   - Kunci SSH GitHub (ssh-keygen + tambahkan di GitHub) supaya git push jalan.
   - Login Brave / Spotify. BIOS: mode GPU hybrid kalau laptop punya iGPU.
   - Mesin baru: buat hosts/$HOST/ untuk yang khas mesin ini (layout lock screen, monitor, dll).
MSG
}

doctor() {
  step "Doctor: $HOST"
  local bad=0
  for p in "${PKGS_FOLD[@]}" "${PKGS_NOFOLD[@]}"; do
    local extra=(); [[ " ${PKGS_NOFOLD[*]} " == *" $p "* ]] && extra=(--no-folding)
    if out=$(cd "$REPO" && stow -n -v "${extra[@]}" -t "$HOME" "$p" 2>&1 | grep -vE 'WARNING|simulation'); [ -z "$out" ]; then ok "stow $p"; else warn "stow $p: $out"; bad=1; fi
  done
  if [ -d "$REPO/hosts/$HOST" ]; then
    if out=$(cd "$REPO/hosts" && stow -n -v --no-folding -t "$HOME" "$HOST" 2>&1 | grep -vE 'WARNING|simulation'); [ -z "$out" ]; then ok "stow overlay host $HOST"; else warn "overlay host $HOST: $out"; bad=1; fi
  fi
  local broken; broken=$(find "$HOME" -maxdepth 6 -xtype l -lname '*dotconfigfiles*' 2>/dev/null); [ -z "$broken" ] && ok "tidak ada symlink putus" || { warn "symlink putus: $broken"; bad=1; }
  # file kunci harus ada DAN berasal dari repo (stow -n diam saja kalau file sumbernya hilang dari repo)
  for f in .zshrc .p10k.zsh .gitconfig .config/alacritty/alacritty.toml .config/tmux/tmux.conf .config/hypr/hyprland.lua \
           .config/noctalia/shell.toml .config/nvim/init.lua .config/rofi/config.rasi .config/mpv/mpv.conf .local/bin/resi-shell; do
    if [ ! -e "$HOME/$f" ]; then warn "hilang: ~/$f"; bad=1
    elif ! in_repo "$HOME/$f"; then warn "bukan dari repo (file biasa/menimpa symlink): ~/$f"; bad=1; fi
  done
  ok "file kunci ada dan mengarah ke repo"
  grep -qF 'require("noctalia")' "$HOME/.config/hypr/hyprland.lua" 2>/dev/null && ok "hyprland.lua memuat tema Noctalia" || { warn "hyprland.lua tanpa require(\"noctalia\"): border tidak ikut tema"; bad=1; }
  for f in tmux/.config/tmux/tmux.conf alacritty/.config/alacritty/alacritty.toml; do
    [ -e "$REPO/$f.pre-resi" ] && { warn "sisa $f.pre-resi di repo (bekas bug installer lama; bandingkan lalu hapus)"; bad=1; }
  done
  have hyprctl && { e=$(hyprctl configerrors 2>/dev/null); [ -z "$e" ] && ok "hyprland configerrors kosong" || { warn "hyprland: $e"; bad=1; }; }
  have noctalia && { noctalia config validate >/dev/null 2>&1 && ok "noctalia config valid" || { warn "noctalia config tidak valid"; bad=1; }; }
  have rofi && { rofi -dump-theme >/dev/null 2>&1 && ok "tema rofi valid" || { warn "tema rofi rusak"; bad=1; }; }
  have zsh && { zsh -ic 'exit' >/dev/null 2>&1 && ok "zsh memuat config" || { warn "zsh error"; bad=1; }; }
  have tmux && { [ -f "$HOME/.config/tmux/tmux.conf" ] && tmux -L residoc -f "$HOME/.config/tmux/tmux.conf" new -d -s x 2>/dev/null && tmux -L residoc kill-server && ok "tmux config OK" || { warn "tmux config error/hilang"; bad=1; }; }
  [ "$(getent passwd "$USER" | cut -d: -f7)" = "/usr/bin/zsh" ] && ok "login shell zsh" || warn "login shell bukan zsh"
  if have noctalia-greeter; then
    # /var/lib/noctalia-greeter root-only dan staging /run hilang tiap boot; log Noctalia permanen, pakai itu.
    last=$(grep 'synced shell appearance to greeter' "$HOME/.cache/noctalia/noctalia.log" 2>/dev/null | tail -1 | cut -c1-19)
    if [ -n "$last" ]; then ok "greeter terakhir di-sync $last"
    else warn "greeter belum pernah di-sync (layar login masih bawaan): noctalia msg greeter-sync"; fi
  fi
  (cd "$REPO" && git status --short | grep -q . && warn "repo punya perubahan belum di-commit" || ok "repo bersih")
  (( bad )) && { echo; echo "Ada masalah. Jalankan: resi-shell install"; return 1; } || echo "Semua sehat."
}

update() {
  step "Update"
  (cd "$REPO" && run git pull --ff-only)
  pacman_packages; aur_packages; stow_all; tmux_plugins; nvim_plugins
  have hyprctl && run hyprctl reload >/dev/null; have noctalia && run noctalia msg config-reload >/dev/null 2>&1 || true
  ok "update selesai"
}

install_all() {
  require_arch; sudo_keepalive
  pacman_packages; aur_helper; aur_packages; gpu_drivers
  shell_setup; stow_all; tmux_plugins; nvim_plugins; dirs_and_git; services; gtk_theme; greeter; finish
}

case "$CMD" in
  install)  install_all ;;
  update)   require_arch; sudo_keepalive; update ;;
  doctor)   doctor ;;
  packages) echo "# pacman"; pkglist "$REPO/resi/packages.pacman"; echo "# aur"; pkglist "$REPO/resi/packages.aur" ;;
esac
