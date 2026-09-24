#!/usr/bin/env bash
# resi-shell installer: pasang dan setel seluruh desktop dari repo dotfiles ini (Arch Linux).
# Idempotent: aman dijalankan berulang. Butuh: Arch dasar terpasang, user dengan sudo, koneksi internet.
#
#   ./install.sh [install] [--dry-run|-n]   semua tahap
#   ./install.sh update [-y]                git pull + paket + stow + plugin (-y: tanpa konfirmasi)
#   ./install.sh doctor                     cek kondisi tanpa mengubah apa pun
#   ./install.sh packages                   daftar paket
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CMD="install"; DRY=0; YES=0
for a in "$@"; do case "$a" in install|update|doctor|packages) CMD="$a" ;; --dry-run|-n) DRY=1 ;; -y|--yes) YES=1 ;; -h|--help) sed -n '2,9p' "$0"; exit 0 ;; *) echo "unknown argument: $a" >&2; exit 2 ;; esac; done

PKGS_FOLD=(zsh git alacritty tmux nvim rofi mpv)            # stow biasa (folder boleh dilipat)
PKGS_NOFOLD=(hypr noctalia claude bin gtk)                 # --no-folding: folder tetap nyata (overlay host & file render bisa masuk)
HOST="$(cat /etc/hostname 2>/dev/null || hostname)"

c_step=$'\e[1;34m'; c_ok=$'\e[1;32m'; c_warn=$'\e[1;33m'; c_btn=$'\e[1;7m'; c_off=$'\e[0m'
step() { printf '\n%s==> %s%s\n' "$c_step" "$*" "$c_off"; }
ok()   { printf '%s  ✓ %s%s\n' "$c_ok" "$*" "$c_off"; }
warn() { printf '%s  ! %s%s\n' "$c_warn" "$*" "$c_off"; }
run()  { if (( DRY )); then printf '  [dry] %s\n' "$*"; else "$@"; fi; }
have() { command -v "$1" >/dev/null 2>&1; }
pkglist() { grep -vE '^\s*#|^\s*$' "$1"; }
in_repo() { case "$(realpath -m "$1" 2>/dev/null)" in "$REPO"/*) return 0 ;; *) return 1 ;; esac; }   # path (setelah symlink) ada di dalam repo?

# Kotak pesan + pertanyaan Yes/No (ala gum di Omarchy, tapi memakai fzf yang sudah ada; fallback y/N).
box() { local w=0 l; for l in "$@"; do (( ${#l} > w )) && w=${#l}; done
  local bar; bar="$(printf '─%.0s' $(seq 1 $((w + 4))))"
  printf '┌%s┐\n' "$bar"; for l in "$@"; do printf '│  %s%*s  │\n' "$l" $((w - ${#l})) ''; done; printf '└%s┘\n' "$bar"; }   # padding per karakter, bukan byte
confirm() { # $1 pertanyaan; tombol horizontal [ Yes ] [ No ] ala gum confirm. Sukses bila Yes.
  [[ -t 0 ]] || { local a; read -rp "$1 [y/N] " a; [[ $a =~ ^[Yy] ]]; return; }
  local sel=0 key
  printf '\033[?25l'
  while true; do
    printf '\r\033[K  %s   ' "$1"
    if (( sel == 0 )); then printf '%s  Yes  %s    No   ' "$c_btn" "$c_off"; else printf '   Yes    %s  No   %s' "$c_btn" "$c_off"; fi
    IFS= read -rsn1 key </dev/tty || { sel=1; break; }
    case "$key" in
      $'\e') if read -rsn2 -t 0.05 key </dev/tty; then [[ $key == '[C' || $key == '[D' || $key == '[Z' ]] && sel=$((1 - sel))
              else sel=1; break; fi ;;                      # Esc sendiri = No
      $'\t'|h|l|j|k|' ') sel=$((1 - sel)) ;;
      y|Y) sel=0; break ;;
      n|N|q) sel=1; break ;;
      '') break ;;                                          # Enter
    esac
  done
  printf '\033[?25h\n'
  (( sel == 0 ))
}

require_arch() { have pacman || { echo "Not Arch Linux (pacman not found)."; exit 1; }; }

sudo_keepalive() {
  (( DRY )) && return 0
  sudo -v || { echo "sudo is required."; exit 1; }
  ( while true; do sudo -n true; sleep 50; kill -0 "$$" 2>/dev/null || exit; done ) 2>/dev/null &
}

# ---------- tahap ----------
pacman_packages() {
  step "Official repo packages ($(pkglist "$REPO/resi/packages.pacman" | wc -l))"
  run sudo pacman -Syu --needed --noconfirm $(pkglist "$REPO/resi/packages.pacman")
  ok "pacman done"
}

aur_helper() {
  step "AUR helper (yay)"
  if have yay; then ok "yay already installed"; return; fi
  local tmp; tmp="$(mktemp -d)"
  run git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
  (( DRY )) || (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
  ok "yay installed"
}

aur_packages() {
  step "AUR packages ($(pkglist "$REPO/resi/packages.aur" | wc -l))"
  run yay -S --needed --noconfirm $(pkglist "$REPO/resi/packages.aur")
  ok "AUR done"
}

gpu_drivers() {
  step "GPU drivers (auto-detected)"
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
  ok "shell ready"
}

stow_all() {
  step "Stow configs into \$HOME"
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
    (cd "$REPO/hosts" && run stow --restow --no-folding -t "$HOME" "$HOST"); ok "host overlay: $HOST"
  else
    warn "no overlay for host '$HOST' (optional: create hosts/$HOST/)"
  fi
  ok "stow done"
}

tmux_plugins() {
  step "tmux: TPM + plugins"
  local tpm="$HOME/.config/tmux/plugins/tpm"
  [ -d "$tpm" ] || run git clone --depth=1 https://github.com/tmux-plugins/tpm "$tpm"
  (( DRY )) || "$tpm/bin/install_plugins" >/dev/null 2>&1 || true
  ok "tmux ready"
}

nvim_plugins() {
  step "neovim: plugins (lazy.nvim headless)"
  (( DRY )) || GIT_TERMINAL_PROMPT=0 timeout 300 nvim --headless "+Lazy! install" +qa >/dev/null 2>&1 || warn "lazy install failed/timed out; open nvim and run :Lazy sync"
  ok "nvim ready"
}

dirs_and_git() {
  step "Folders & git identity"
  run mkdir -p "$HOME/Pictures/Screenshots" "$HOME/Pictures/Wallpapers"
  if [ -z "$(git config --global user.name 2>/dev/null)" ] && [ -z "$(git -C "$REPO" config user.name 2>/dev/null)" ]; then
    if (( DRY )); then echo "  [dry] would ask for git name & email"; else
      read -rp "  git user.name : " gname; read -rp "  git user.email: " gmail
      git -C "$REPO" config user.name "$gname"; git -C "$REPO" config user.email "$gmail"
    fi
  fi
  ok "folders ready"
}

services() {
  step "System services"
  for s in NetworkManager bluetooth power-profiles-daemon greetd; do run sudo systemctl enable "$s" >/dev/null 2>&1 || warn "failed to enable $s"; done
  run sudo install -Dm644 "$REPO/resi/greetd-config.toml" /etc/greetd/config.toml
  ok "greetd + services enabled"
}

gtk_theme() {
  step "GTK theme (adw-gtk3 + Papirus, dark mode)"
  # Warna GTK dirender template builtin Noctalia gtk3/gtk4 (aktifkan di Settings > Templates; tersimpan di state).
  # Hook Noctalia yang menyetel gtk-theme adw-gtk3-dark saat tema berganti; ikon dan mode gelap diset di sini.
  have gsettings || { warn "gsettings not found"; return; }
  run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
  [ -d /usr/share/themes/adw-gtk3-dark ] && run gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
  [ -d /usr/share/icons/Papirus-Dark ] && run gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
  ok "GTK dark + Papirus"
  if have mpv; then
    for m in video/mp4 video/x-matroska video/webm video/quicktime video/x-msvideo audio/mpeg audio/flac audio/ogg audio/x-wav audio/mp4; do run xdg-mime default mpv.desktop "$m"; done
    ok "mpv set as default video/audio player"
  fi
}

greeter() {
  step "Noctalia Greeter"
  if ! have noctalia-greeter; then warn "noctalia-greeter not installed (AUR)"; return; fi
  local tmp; tmp="$(mktemp)"; sed "s/__USER__/$USER/" "$REPO/resi/greeter.toml" >"$tmp"
  run sudo install -o greeter -g greeter -m 644 "$tmp" /var/lib/noctalia-greeter/greeter.toml; rm -f "$tmp"
  run sudo noctalia-greeter passwordless-sync enable "$USER" || warn "passwordless-sync failed (greeter < 1.5?)"
  ok "greeter.toml + passwordless sync"
  # Auto-sync dinyalakan oleh noctalia/greeter.toml; sync pertama harus dipicu sekali kalau shell sedang jalan
  # (tanpa ini greeter tampil bawaan sampai tema berubah, karena /var/lib/noctalia-greeter/sync.toml belum ada).
  if have noctalia && noctalia msg status >/dev/null 2>&1; then
    if (( DRY )); then run noctalia msg greeter-sync; else noctalia msg greeter-sync >/dev/null 2>&1 && ok "greeter synced with the current theme"; fi || warn "greeter-sync failed; run: noctalia msg greeter-sync"
  else
    echo "  (Noctalia is not running: the first sync happens automatically when a wallpaper/theme is picked, or run: noctalia msg greeter-sync)"
  fi
}

finish() {
  step "Done"
  cat <<MSG
  Manual steps that cannot be automated:
   - Reboot (GPU drivers, greetd, login shell).
   - First login: Noctalia setup wizard (wallpapers in ~/Pictures/Wallpapers, theme). Greeter auto-sync is enabled
     by noctalia/greeter.toml; if the login screen still looks default: noctalia msg greeter-sync. Color templates
     (hyprland, alacritty, gtk3, gtk4, btop) are enabled by noctalia/templates.toml; if the wizard wrote its own list,
     check Settings > Templates so Hyprland, Alacritty, GTK 3, GTK 4 are on (otherwise borders & apps won't follow the theme).
   - GitHub SSH key (ssh-keygen + add it on GitHub) so git push works.
   - Log in to Brave / Spotify. BIOS: hybrid GPU mode if the laptop has an iGPU.
   - New machine: create hosts/$HOST/ for machine-specific bits (lock screen layout, monitors, etc.).
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
    if out=$(cd "$REPO/hosts" && stow -n -v --no-folding -t "$HOME" "$HOST" 2>&1 | grep -vE 'WARNING|simulation'); [ -z "$out" ]; then ok "stow host overlay $HOST"; else warn "host overlay $HOST: $out"; bad=1; fi
  fi
  local broken; broken=$(find "$HOME" -maxdepth 6 -xtype l -lname '*dotconfigfiles*' 2>/dev/null); [ -z "$broken" ] && ok "no broken symlinks" || { warn "broken symlinks: $broken"; bad=1; }
  # file kunci harus ada DAN berasal dari repo (stow -n diam saja kalau file sumbernya hilang dari repo)
  for f in .zshrc .p10k.zsh .gitconfig .config/alacritty/alacritty.toml .config/tmux/tmux.conf .config/hypr/hyprland.lua \
           .config/hypr/monitors.lua .config/noctalia/shell.toml .config/nvim/init.lua .config/rofi/config.rasi .config/mpv/mpv.conf \
           .local/bin/resi-shell .local/bin/hypr-menu .local/bin/hypr-tui .local/share/applications/nwg-displays.desktop; do
    if [ ! -e "$HOME/$f" ]; then warn "missing: ~/$f"; bad=1
    elif ! in_repo "$HOME/$f"; then warn "not from the repo (plain file replaced the symlink): ~/$f"; bad=1; fi
  done
  ok "key files present and pointing into the repo"
  grep -qF 'require("noctalia")' "$HOME/.config/hypr/hyprland.lua" 2>/dev/null && ok "hyprland.lua loads the Noctalia theme" || { warn "hyprland.lua has no require(\"noctalia\"): borders won't follow the theme"; bad=1; }
  for f in tmux/.config/tmux/tmux.conf alacritty/.config/alacritty/alacritty.toml; do
    [ -e "$REPO/$f.pre-resi" ] && { warn "leftover $f.pre-resi in the repo (old installer bug; compare, then delete)"; bad=1; }
  done
  have hyprctl && { e=$(hyprctl configerrors 2>/dev/null); [ -z "$e" ] && ok "hyprland configerrors empty" || { warn "hyprland: $e"; bad=1; }; }
  have noctalia && { noctalia config validate >/dev/null 2>&1 && ok "noctalia config valid" || { warn "noctalia config invalid"; bad=1; }; }
  have rofi && { rofi -dump-theme >/dev/null 2>&1 && ok "rofi theme valid" || { warn "rofi theme broken"; bad=1; }; }
  [ -x "$HOME/.local/bin/hypr-menu" ] && { HYPR_MENU_CHECK=1 "$HOME/.local/bin/hypr-menu" >/dev/null 2>&1 && ok "hypr-menu: all submenu targets resolve" || { warn "hypr-menu: a submenu points to a missing function (HYPR_MENU_CHECK=1 hypr-menu)"; bad=1; }; }
  have zsh && { zsh -ic 'exit' >/dev/null 2>&1 && ok "zsh loads its config" || { warn "zsh error"; bad=1; }; }
  have tmux && { [ -f "$HOME/.config/tmux/tmux.conf" ] && tmux -L residoc -f "$HOME/.config/tmux/tmux.conf" new -d -s x 2>/dev/null && tmux -L residoc kill-server && ok "tmux config OK" || { warn "tmux config error/missing"; bad=1; }; }
  [ "$(getent passwd "$USER" | cut -d: -f7)" = "/usr/bin/zsh" ] && ok "login shell is zsh" || warn "login shell is not zsh"
  if have noctalia-greeter; then
    # /var/lib/noctalia-greeter root-only dan staging /run hilang tiap boot; log Noctalia permanen, pakai itu.
    last=$(grep 'synced shell appearance to greeter' "$HOME/.cache/noctalia/noctalia.log" 2>/dev/null | tail -1 | cut -c1-19)
    if [ -n "$last" ]; then ok "greeter last synced $last"
    else warn "greeter never synced (login screen still default): noctalia msg greeter-sync"; fi
  fi
  (cd "$REPO" && git status --short | grep -q . && warn "repo has uncommitted changes" || ok "repo clean")
  (( bad )) && { echo; echo "Problems found. Run: resi-shell install"; return 1; } || echo "All healthy."
}

update_confirm() {
  (( YES )) && return 0
  box "Ready to update?" "" \
      "• git pull dotfiles, upgrade repo + AUR packages, restow, tmux/nvim plugins" \
      "• You cannot stop the update once you start!" \
      "• Make sure you're connected to power or have a full battery" "" \
      "Log: ~/.cache/resi-shell-update.log"
  echo
  confirm "Continue with update?" || { echo "Update cancelled."; exit 1; }
}

# Ala omarchy-update-orphan-pkgs + omarchy-update-pkg-prune: paket yatim ditawarkan untuk dihapus (default No,
# dilewati saat -y: hanya dilaporkan), cache paket dipangkas ke 2 versi terakhir (paccache dari pacman-contrib).
update_cleanup() {
  step "Clean up"
  local -a orphans; mapfile -t orphans < <(pacman -Qtdq 2>/dev/null || true)
  if (( ${#orphans[@]} )); then
    printf '  orphaned: %s\n' "${orphans[@]}"
    if (( YES )); then warn "${#orphans[@]} orphaned package(s) left in place (unattended run)"
    elif confirm "Remove ${#orphans[@]} orphaned package(s)?"; then run sudo pacman -Rns --noconfirm "${orphans[@]}" && ok "orphans removed"
    else echo "  keeping orphaned packages"; fi
  else ok "no orphaned packages"; fi
  if have paccache; then run sudo paccache -rk2 >/dev/null && ok "package cache pruned (2 versions kept)" || warn "paccache failed"
  else warn "paccache not found (pacman-contrib); package cache not pruned"; fi
}

# Ala omarchy-update-restart: tawarkan reboot bila kernel yang berjalan sudah tidak terpasang
# atau binary Hyprland yang berjalan sudah diganti.
update_restart() {
  (( DRY )) && return 0
  local need="" running; running="$(uname -r)"
  [[ -d /usr/lib/modules/$running ]] || need="Linux kernel has been updated (running: $running)."
  local exe; exe="$(readlink /proc/"$(pgrep -x Hyprland | head -1)"/exe 2>/dev/null || true)"
  [[ $exe == *"(deleted)"* ]] && need="${need:-Hyprland has been updated.}"
  [[ -z $need ]] && return 0
  echo; warn "$need"
  if confirm "Reboot now?"; then systemctl reboot; fi
}

# git pull yang ramah: perubahan lokal yang belum di-commit disimpan (stash) lalu dikembalikan,
# cabang yang menyimpang atau konflik saat mengembalikan dihentikan dengan petunjuk, bukan pesan git mentah.
git_sync() {
  step "Dotfiles: git pull"
  cd "$REPO"
  run git fetch -q origin || { warn "git fetch failed (offline?). Continuing with the local copy."; cd - >/dev/null; return 0; }
  local branch; branch="$(git rev-parse --abbrev-ref HEAD)"
  local dirty; dirty="$(git status --porcelain --untracked-files=no)"
  local behind ahead; behind="$(git rev-list --count HEAD..origin/"$branch" 2>/dev/null || echo 0)"; ahead="$(git rev-list --count origin/"$branch"..HEAD 2>/dev/null || echo 0)"
  if (( ahead > 0 )); then
    warn "Your local branch has $ahead commit(s) that are not on origin/$branch."
    echo "  Run in $REPO:  git pull --rebase && git push   then run: resi-shell update"; exit 1
  fi
  if (( behind == 0 )); then ok "dotfiles already up to date"; cd - >/dev/null; return 0; fi
  local stashed=0
  if [[ -n $dirty ]]; then
    local -a files; mapfile -t files < <(printf '%s\n' "$dirty" | sed 's/^ *\([A-Z?]*\) */\1  /')
    echo; box "Uncommitted changes in $REPO" "" "${files[@]}" "" \
        "origin/$branch has $behind new commit(s). They can be pulled with your changes" \
        "stashed first and re-applied afterwards (git stash / git pull / git stash pop)."
    echo
    if (( YES )) || confirm "Stash local changes, pull, and re-apply them?"; then
      run git stash push -q -m "resi-shell update $(date +%F_%T)" && stashed=1
    else
      echo "Update cancelled. Commit or stash your changes first:  cd $REPO && git status"; exit 1
    fi
  fi
  run git pull -q --ff-only || { warn "git pull failed. Fix it in $REPO (git status), then run: resi-shell update"; exit 1; }
  ok "pulled $behind commit(s) from origin/$branch"
  if (( stashed )); then
    if run git stash pop -q; then ok "local changes re-applied"
    else
      warn "Conflicts while re-applying your local changes:"
      git diff --name-only --diff-filter=U | sed 's/^/    /'
      echo "  Resolve them in $REPO (git status; your changes are also kept in: git stash list), then run: resi-shell update"; exit 1
    fi
  fi
  cd - >/dev/null
}

update() {
  update_confirm; sudo_keepalive
  git_sync
  step "Update"
  pacman_packages; aur_packages
  step "Upgrade AUR packages"; if run yay -Sua --noconfirm; then ok "AUR up to date"; else warn "AUR upgrade failed; continuing with the rest of the update"; fi
  update_cleanup
  if have mise; then step "Update mise tools"; if MISE_MINIMUM_RELEASE_AGE=0 run mise up; then ok "mise tools up to date"; else warn "mise up failed; continuing"; fi; fi
  stow_all; tmux_plugins; nvim_plugins
  have hyprctl && run hyprctl reload >/dev/null; have noctalia && run noctalia msg config-reload >/dev/null 2>&1 || true
  # autostart.lua only runs at Hyprland start: (re)launch the battery watcher now. hypr-power is single-instance
  # (flock), so this is a no-op when it is already running. Spawned through Hyprland like autostart does.
  if have hyprctl && hyprctl version >/dev/null 2>&1 && [ -x "$HOME/.local/bin/hypr-power" ]; then
    run hyprctl dispatch "hl.dsp.exec_cmd(\"$HOME/.local/bin/hypr-power watch\")" >/dev/null 2>&1 && ok "battery watcher (hypr-power) running" || warn "could not start hypr-power watch"
    [ -x "$HOME/.local/bin/hypr-updates" ] && run hyprctl dispatch "hl.dsp.exec_cmd(\"$HOME/.local/bin/hypr-updates watch\")" >/dev/null 2>&1 && ok "update checker (hypr-updates) running"
  fi
  [ -x "$HOME/.local/bin/hypr-updates" ] && "$HOME/.local/bin/hypr-updates" check >/dev/null 2>&1 || true   # bersihkan indikator bar
  ok "update done"
  update_restart
}

install_all() {
  require_arch; sudo_keepalive
  pacman_packages; aur_helper; aur_packages; gpu_drivers
  shell_setup; stow_all; tmux_plugins; nvim_plugins; dirs_and_git; services; gtk_theme; greeter; finish
}

case "$CMD" in
  install)  install_all ;;
  update)   require_arch
            if [[ -z ${RESI_UPDATE_LOGGED:-} && -t 1 ]] && have script; then   # simpan log seperti omarchy-update
              exec env RESI_UPDATE_LOGGED=1 script -qefc "$(printf '%q ' "$0" "$@")" "$HOME/.cache/resi-shell-update.log"
            fi
            update ;;
  doctor)   doctor ;;
  packages) echo "# pacman"; pkglist "$REPO/resi/packages.pacman"; echo "# aur"; pkglist "$REPO/resi/packages.aur" ;;
esac
