# Notes

This file is the "why" behind this repo: decisions, gotchas, and things that were tried and
rejected. `README.md` documents *what* is installed and *how* to install it; this file exists so
that whoever (or whatever — an AI model, a future you) touches this repo next doesn't have to
rediscover the same facts by trial and error. Written in English to match `README.md` and stay
readable by any tool or model, regardless of what assisted a given change.

## Origin

The desktop started as a port of [Omarchy](https://omarchy.org)'s Hyprland Lua config (bindings,
window rules, tmux config, keybindings menu) onto a plain Arch install, with
[Noctalia](https://noctalia.dev) v5 standing in for Omarchy's own shell (bar, launcher panels,
notifications, lock screen, idle, wallpaper, greeter). Every color follows the wallpaper: Noctalia
generates a Material 3 palette and templates render it into alacritty, rofi, Neovim, GTK apps,
Hyprland's window borders, and the login screen.

## Key decisions and why

- **`hypr` and `noctalia` are stowed `--no-folding`** (real directories with per-file symlinks),
  not folded into a single symlinked directory. This lets per-host overlays
  (`hosts/<hostname>/.config/hypr/local.lua`, etc.) add files into the same directory without
  touching the repo, and keeps Noctalia's rendered files (`~/.config/hypr/noctalia.lua`, GTK
  `gtk.css`/`noctalia.css`) sitting next to the real config without being *inside* the repo.
- **Noctalia's color templates are enabled from a config file** (`noctalia/templates.toml`,
  `builtin_ids = ["hyprland", "alacritty", "gtk3", "gtk4", "btop"]`), not left to the setup
  wizard. The wizard writes its own list to `~/.local/state/noctalia/settings.toml`, and on a
  machine where the wizard skipped one of these, the corresponding app kept static colors after a
  wallpaper change (this actually happened on the `dynarch` host — Hyprland's window borders
  stayed static because the `hyprland` template id was never enabled there). If colors still don't
  follow the wallpaper after pulling this repo, check **Settings → Templates** in Noctalia; a value
  already set in `settings.toml` wins over the file here (state always wins over config for a given
  key — see "Noctalia's two config layers" below).
- **`nvim/.config/nvim/lazy-lock.json` is gitignored, not tracked.** lazy.nvim rewrites it on every
  `:Lazy sync`, and two machines syncing independently just fight over one file in git with no real
  benefit (plugin versions don't need to be pinned identically across personal machines). Each
  machine keeps its own lockfile.
- **`gpu-screen-recorder` over `wf-recorder`/`wl-screenrec` for screen recording**, matching what
  Omarchy itself moved to: KMS capture + GPU encoding is measurably lighter than the
  screencopy-protocol recorders, and it has a replay-buffer mode the others don't. It's AUR-only,
  which is the one tradeoff.
- **rofi over walker for the launcher/menu**, evaluated 2026-09-24. Measured on the `legionarch`
  machine: rofi runs at ~32MB RSS per invocation with zero background process when idle (native
  Wayland layer-shell, confirmed via `hyprctl layers`). walker (Rust + GTK4) requires a persistent
  Go daemon ("elephant") to function at all, and its own docs recommend running walker itself as a
  resident service too — because GTK4 toolkit init alone measured ~363MB RSS on this machine for a
  *bare* window with no content. walker's "lightweight" reputation rests on staying resident to
  hide that cold-start cost; rofi has no such cost to hide. Given the launcher here is already
  built entirely on `rofi -dmenu` (`hypr-menu`, `hypr-theme`), switching offered no clear win.
  Don't re-litigate this without new information about walker's architecture changing.
- **GPU handling is written to be hardware-agnostic**: `hypr/.config/hypr/envs.lua` only sets the NVIDIA
  environment when NVIDIA is the *sole* GPU (no `amdgpu`/`i915`/`xe` present); in hybrid mode it
  sets `LIBVA_DRIVER_NAME`/`__GLX_VENDOR_LIBRARY_NAME` explicitly for the iGPU. This was a real bug
  on `legionarch` (a hybrid NVIDIA+AMD laptop): mpv and VA-API decode silently ran on the wrong GPU
  until this was made explicit — see "Hyprland's `hl.env` never unsets" below for why "just don't
  set it" wasn't enough.
- **Per-machine differences live in `hosts/<hostname>/`** (a Stow overlay applied only when the
  folder name matches `/etc/hostname`), not in machine-specific branches or conditionals inside the
  shared config. See `README.md`'s "Several machines" section for the mechanics; this file just
  notes that the pattern exists so a second host (`dynarch`) could be added later without anyone
  needing to explain the convention from scratch.

- **Install and Remove menus are a straight port of Omarchy's `omarchy-pkg-install` /
  `omarchy-pkg-aur-install` / `omarchy-pkg-remove`** (`bin/hypr-pkg-install repo|aur|remove`):
  `pacman -Slq`, `yay -Slqa` or `pacman -Qqe` piped into fzf with the same preview bindings, then
  `pacman -S --noconfirm` / `yay -S --noconfirm aur/...` / `pacman -Rns --noconfirm` (red markers
  for removal). Removal first prints the full list from `pacman -Rs -p` (`-Rns -p` is rejected by
  pacman) in a box and asks Yes/No via `hypr-tui --confirm`; the box/confirm code is duplicated in
  `install.sh` on purpose, because the installer must work before `bin` is stowed. Omarchy's other Remove entries (AI, gaming, dev envs, web apps) are Omarchy-specific
  and were not ported. Omarchy's
  `omarchy-sudo-keepalive` is inlined; the floating terminal and the "Done! Press any key" prompt
  (`omarchy-launch-floating-terminal-with-presentation` + `omarchy-show-done`) are `bin/hypr-tui`,
  which any menu entry can use. The picker runs in its own alacritty class (`hypr-pkg-install`,
  floating 1000x800) because the 65% preview pane needs more height than the generic `TUI.float`
  rule gives. Nothing new to install: fzf, pacman and yay are already in the package lists.
- **Update menu = `resi-shell update` (menu > Update > Resi shell)**, mirroring `omarchy-update`:
  a boxed "Ready to update?" notice and a Yes/No confirmation before anything runs (`-y` skips it),
  the whole run captured with `script` to `~/.cache/resi-shell-update.log`, and a reboot offer at
  the end when the running kernel is no longer installed or the Hyprland binary was replaced
  (`omarchy-update-restart`). The `git pull` step (`git_sync`) never shows raw git errors: with
  uncommitted changes it lists them and offers stash / pull / stash pop (automatic with `-y`), a
  branch that is ahead of origin stops with "git pull --rebase && git push", and a conflict on
  stash pop stops with the conflicting files listed (the stash is kept). Omarchy draws these with gum; ours are plain bash (a box-drawing
  notice and horizontal `[ Yes ] [ No ]` buttons driven by arrow keys/Tab/y/n/Esc), so gum is not a
  dependency. Confirmation comes before the sudo prompt on purpose.
- **Everything shown to the user is English** (installer output, doctor checks, TUI prompts, menu
  labels, README). Code comments in the scripts and the Claude skills stay Indonesian; that is the
  owner's working language. Keep new user-facing strings English.
- **Update > Firmware** (`bin/hypr-update-firmware`) mirrors `omarchy-update-firmware`: fwupd is not
  in the package list, the script offers to install it on first use, then `fwupdmgr refresh --force`
  and `sudo fwupdmgr update` (exit 2 = nothing to update, reported as such). A refresh error
  "metadata checksum expected X and got Y" is cdn.fwupd.org serving a newer `firmware.xml.zst`
  with a stale cached `.jcat` signature (seen 2026-09-24: metadata 06:42 UTC, jcat 02:41 UTC);
  nothing local is wrong, retry later. The script says so and continues with old metadata if any. Omarchy also copies
  `fwupdx64.efi` into `/boot/EFI/arch`; we skip that because fwupd's uefi-capsule plugin places it on
  the ESP itself when a UEFI update is staged, and our ESP layout is not Omarchy's.
- **Update > Process > Shell** (`bin/hypr-restart-shell`) is the Noctalia version of
  `omarchy-restart-shell`: refuse while `noctalia msg status` reports `locked` (killing the lock
  client strands the session in Hyprland's failsafe), kill the daemon, relaunch it through
  `hyprctl dispatch 'hl.dsp.exec_cmd("noctalia")'` so it inherits the session environment rather
  than the terminal's, then poll `noctalia msg status` until it answers. Omarchy's other Process
  entry (Hyprsunset) has no equivalent here: night light is built into Noctalia.
- **Setup > Monitors = nwg-displays with redirected output** (`bin/hypr-monitors`). nwg-displays 0.4.4
  writes both `monitors.conf` and, for Hyprland 0.55+, `monitors.lua` containing `hl.monitor({...})`
  blocks, then runs `hyprctl reload`. Its default path is `~/.config/hypr/monitors.lua`, which here
  is a per-file stow symlink into the repo, so a plain `nwg-displays` would overwrite our
  `monitors.lua`. The wrapper passes `-m ~/.config/hypr/nwg-monitors.conf -w
  ~/.config/hypr/nwg-workspaces.conf`; the generated `nwg-monitors.lua` / `nwg-workspaces.lua` live
  in `~/.config/hypr` outside the repo (hypr is `--no-folding`) and `monitors.lua` loads them with
  `dofile` when present, after the generic catch-all rule. Omarchy's Setup > Monitors just opens
  `monitors.lua` in an editor; the user asked for the graphical tool instead. nwg-displays is not in
  the package list; the wrapper offers to install it on first use. The package's own launcher entry
  (`Exec=nwg-displays`) is shadowed by `bin/.local/share/applications/nwg-displays.desktop`
  (same desktop-file id, `Exec=hypr-monitors`) so the app launcher is safe too. nwg-displays also
  creates empty `~/.config/hypr/monitors.conf` and `workspaces.conf` on every start regardless of
  `-m/-w`; they are placeholders for hyprlang `source=` users and harmless here.
- **Processes spawned by Hyprland inherit stdin = `/dev/tty1`** (greetd runs Hyprland on that
  console), so `[[ -t 0 ]]` is true for anything launched from a keybind or the menu, and a prompt
  printed there lands on the invisible console. `hypr-monitors` learned this the hard way: its
  "not installed" prompt went to tty1 and the menu entry looked dead. Scripts must not use
  `-t 0` alone to decide whether to open a floating terminal; check `HYPR_TUI_INNER=1` (set by
  `hypr-tui` inside the terminal it opened) and treat `/dev/ttyN` as non-interactive.
- **System > Hibernate is conditional**, like Omarchy's `when: omarchy-hibernation-available`:
  `hypr-menu` asks logind (`busctl … CanHibernate` / `CanSuspend`) and only lists what answers
  "yes". On legionarch hibernate is "na": the only swap is zram (RAM-backed, cannot hold a
  hibernation image), there is no `resume` initramfs hook and no `resume=` kernel parameter.
  Enabling it would take a real swap file at least `/sys/power/image_size` (~12 GiB here, Omarchy
  uses the full RAM size, 30 GiB) on the 46 GB ext4 root, `HOOKS+=(resume)` in
  `/etc/mkinitcpio.conf.d/`, `resume=<root PARTUUID> resume_offset=<filefrag offset>` in
  `/etc/kernel/cmdline`, and an initramfs/UKI rebuild for Limine. Omarchy's
  `omarchy-hibernation-setup` is Btrfs + limine-entry-tool specific, so it was not ported as is.
- **Lid close and clamshell mode.** Suspend on lid close needs nothing from us: logind's default
  `HandleLidSwitch=suspend` is active, the kernel uses `deep` (S3) sleep, and Noctalia holds a
  "Lock before sleep" delay inhibitor (`lock_before_suspend = true`). With an external monitor
  logind ignores the lid (`HandleLidSwitchDocked=ignore`), so `bin/hypr-clamshell` (a simplified
  `omarchy-hyprland-monitor-clamshell`) switches the internal panel off: it writes
  `hl.monitor({ output = "eDP-2", disabled = true })` to `~/.local/state/resi/hypr/clamshell.lua`,
  which `monitors.lua` loads last, then reloads Hyprland; lid open or unplugging the external
  monitor removes the file, reloads and forces DPMS on. The flag-file approach (instead of a live
  `hyprctl` keyword) means other reloads, e.g. Noctalia theme changes, do not silently re-enable
  the panel. Triggers: Hyprland `switch:on/off:Lid Switch` binds and `monitor.added/removed`
  events registered in `monitors.lua` (Omarchy uses a socket-watching daemon for the latter).
  `hypr-lid-close` additionally locks right away when no external monitor is connected, so the
  lock is already up before logind suspends. Not ported: Omarchy's manual internal-display
  toggle/mirror binds and its scale bookkeeping.
- **Font: JetBrains Mono Nerd Font everywhere (2026-09-28)**, replacing MesloLGS. Chosen for code
  legibility (tall x-height, clearly different `0O`, `1lI`, `rn`/`m`), a repo package
  (`ttf-jetbrains-mono-nerd`, extra) instead of AUR, and full Nerd Font v3 icons for Powerlevel10k, eza,
  rofi menus and mpv. It is also Omarchy's default font. Variants: `JetBrainsMono Nerd Font Mono` in
  alacritty (icons one cell wide, the prompt stays aligned), `JetBrainsMono Nerd Font` for UI text
  (Noctalia `shell.toml`, rofi, mpv OSD/subtitles, Hyprland groupbar, which used the fontconfig
  `monospace` alias before). The greeter follows the shell font through auto-sync.
- **Notifications and OSD (2026-09-27)** (`noctalia/notifications.toml`). Toasts and the OSD were 97% opaque and
  sat 8 px below the bar with the toast edge about 12 px inside the islands' edge. They now use
  `background_opacity = 0.78` (blurred by the existing `noctalia-notification`/`noctalia-osd` layer rule, same
  as the bar capsules) and `offset_x = offset_y = 10` for the window grid; Noctalia measures offsets from the
  screen edge but still starts toasts below the bar's reserved area. `max_visible = 3` (0 filled half the screen
  with four toasts); when a fourth arrives the oldest leaves the screen and stays in history. A
  `[notification.filter.spotify]` hides Spotify's track-change toasts and keeps them out of history, since the
  track is already in the bar's media widget and the control center.
- **Panels float (2026-09-27): glass + attached = see-through.** After `transparency_mode = "glass"` went in
  for the launcher, the attached panels (control center `Super+S`, session `Super+Esc`, wallpaper) turned
  see-through without blur: terminal text behind them was sharp and readable, over the wallpaper file names
  too. Floating panels in the same mode are blurred by Hyprland's layer rule and stay legible, so those three
  now float (`noctalia/control-center.toml`): control center and session top right under the status/power
  islands, wallpaper top center, `floating_offset = 10` for the bar's 10 px grid. With an island bar whose
  background is transparent there is no bar surface to attach to anyway. Lowering Hyprland's `ignore_alpha`
  to 0.05 was tested as an alternative and was not needed. Same pass: control center `width = 760` (700
  truncated the shortcut labels), `date_format = "%A, %d %B %Y"` instead of the en_US `%x`, weather location
  `[location] address = "Jakarta"` (was empty: "No location set"; `auto_locate` stays off to avoid an IP
  lookup), and the calendar events card hidden because calendar integration is off.
- **Launcher look (2026-09-27).** The Noctalia launcher (bar icon only; Super+Space and Super+Alt+Space
  stay rofi) had a filled block behind every row, an unlabeled icon-only category row, no favourites on
  top, and junk entries (three Avahi browsers, lstopo, two Qt V4L2 tools, About Xfce, Rofi, Rofi Theme
  Selector). Now: `list_item_background = false`, `categories = false`, `pinned` favourites, and
  `transparency_mode = "glass"` to match the bar (subtle over dark windows: measured `#2d2227` to
  `#362b32`; it applies to every floating panel). `pinned` takes desktop IDs without `.desktop`; with the
  suffix nothing is pinned and nothing is logged. The junk entries are hidden with `NoDisplay=true`
  overrides in `bin/.local/share/applications/` (same desktop ID as the system file, like Omarchy does),
  which hides them in rofi drun too and travels to every machine. Noctalia's app index missed one of the
  newly created overrides until the shell was restarted (`hypr-restart-shell`).
- **Noctalia 5.2 event sounds need `sound-theme-freedesktop`** (2026-09-28). 5.2 turned on `enable_sounds` with
  `sound_theme = "freedesktop"`; without the theme package it logged "sound theme 'freedesktop' is missing
  sound" for message-new-instant, audio-volume-change, power-plug, power-unplug and screen-capture, and
  played nothing. The package is now in `resi/packages.pacman`. Noctalia resolves the theme once at startup,
  so after installing it the shell must be restarted (Update > Process > Shell, or `hypr-restart-shell`);
  verified afterwards by a `noctalia-sound` output stream appearing in PipeWire when a notification fires.
- **Battery charge limit goes through UPower, not sysfs** (2026-09-28). The first version wrote
  `charge_control_end_threshold` directly (with a udev rule giving wheel write access). UPower 1.91 owns that file:
  with its own limit disabled it rewrote 100 within seconds. `hypr-power charge-limit on|off` now calls
  `EnableChargeThreshold` on the UPower battery over D-Bus (polkit `allow_active=yes`, no password); UPower
  persists it in `/var/lib/upower/charging-threshold-status` and applies its thresholds (end 80, start 75). The
  udev rule was removed. **dynarch's firmware ignores it**: with the charger connected, UPower's limit on, and
  even `echo 80 > charge_control_end_threshold` as root (rc 0), the Dynabook G83/HS reads back 100 at once and
  stays there, although `toshiba_acpi` advertises battery-charge-mode. The limit is left off there; menu and
  `hypr-power charge-limit on` now warn when the firmware value does not follow. Use the BIOS or Dynabook's
  Windows utility if the 80% mode is wanted on this laptop.
- **Keyring** (2026-09-28): gnome-keyring + `resi/setup-keyring-pam.sh` (auth/session lines in
  /etc/pam.d/greetd, session after pam_systemd because auto_start needs XDG_RUNTIME_DIR; password line in
  /etc/pam.d/passwd so a password change re-encrypts the keyring). Brave on Hyprland defaulted to the "basic"
  store (static key), hence `brave-flags.conf`; Chromium still decrypts old v10 cookies. SSH agent from gcr-4
  (`gcr-ssh-agent.socket`) with `SSH_AUTH_SOCK` from envs.lua.
  First login after installing it is special: the socket-activated daemon starts a few ms before PAM creates
  `login.keyring`, so the `login` collection never registers on D-Bus (only `session`), every store asks to
  create a keyring, and the gcr prompt window may not appear. From the next login on the file exists and PAM
  just unlocks it (seen 2026-09-28: "gkr-pam: unlocked login keyring"; restarting the daemon showed the
  collection). The greeter screen also goes through `/etc/pam.d/greetd` as user `greeter` (home `/`), which
  started a useless keyring daemon; `pam_succeed_if ... user = greeter` now skips the keyring lines for it.
- **Folder colors** (2026-09-28): papirus-folders is AUR-only and needs root on every change, so
  `hypr-folder-color` builds a user icon theme instead (symlinks to the chosen Papirus variant, inherits
  Papirus-Dark; 567 links, ~2 MB). Plain Lab distance picked white/brown for Material 3 pastels, so the
  score is hue difference first (+0.5 chroma, +0.3 lightness), neutrals only when the primary is nearly grey.
- **Doctor lints scripts** (2026-09-28): `bash -n` and `shellcheck -S error` on bin/, install.sh and resi/*.sh,
  plus Python parse and `luac -p`. Warnings are not failures: the remaining ones are deliberate (tilde in
  menu actions run by sh later, word-split package lists, trap capturing `$!`).
- **Caffeine in the bar (2026-09-28).** Noctalia's built-in `caffeine` widget (no options; outline cup when
  off, filled cup in the primary color when on) sits in the info island after clipboard. It takes a Wayland
  idle inhibitor plus a logind idle inhibit (`[logind] logind idle inhibit acquired` in the log). Verified that
  it really stops our idle behaviors: a temporary 8-second `action = "command"` behavior did not fire in
  16 s with caffeine on and fired after 8 s with it off, so the 10 min lock and 11 min screen-off in
  `idle.toml` are held off while it is on. Same toggle: menu Toggle > Caffeine, control-center shortcut,
  `noctalia msg caffeine-toggle`.
- **Bar look (2026-09-27): square frosted islands on the window grid.** The capsules were fully opaque, so
  the Hyprland layer blur on `noctalia-bar-*` (`ignore_alpha = 0.5`) never showed; they are now 0.78 opaque
  with an `outline` border. They were rounded pills over square windows (Hyprland `rounding = 0`, Noctalia
  `corner_radius_scale = 0`); radius 4 makes the bar one shape language with the rest. Geometry follows
  Hyprland's `gaps_out = 10`: bar 30 px, capsules fill it, 10 px from the top edge, first/last capsule edge
  at 10 px like the window borders, 10 px down to the windows (before: 26 px inset, 4 px above, 14 px below).
  Capsule groups do not inherit `capsule_*` from `[bar.default]`, so each group repeats opacity, border,
  padding and radius. Wallpaper and Wallhaven icons left the bar; both panels still open from their
  shortcuts and the Style menu (plugin panels do not need their bar widget). A rounded-pill variant was
  previewed and rejected for the shape mismatch; it is the same config without the radius keys.
- **Battery mode** (`bin/hypr-power`, started by `autostart.lua` as `hypr-power watch`). Findings on
  legionarch (2026-09-24): ~18 W idle on battery with panel at 100% / 144 Hz, profile `balanced`,
  and the GTX 1660 Ti held in D0 by Hyprland because the HDMI/DP ports are wired to it (Hyprland
  renders on amdgpu, NVIDIA is opened only for its connectors; RTD3 would need
  `AQ_DRM_DEVICES` restricted to the AMD card and would lose those ports, so it was not done).
  BIOS has no CPPC, so it is acpi-cpufreq/schedutil, not amd-pstate. The watcher needs no root:
  power-profiles-daemon is driven over D-Bus, brightness via brightnessctl (first non-`nvidia_*`
  backlight; `nvidia_0` is a bogus device on hybrid laptops), refresh via a flag file loaded by
  `monitors.lua`. It is idempotent (last applied source in `~/.local/state/resi/power/applied`),
  single-instance (flock), and re-applies on every `upower --monitor` event. Panel eDP-2 on
  legionarch only offers 144 Hz, so the refresh step is a no-op there. `hypr-power profile <p>`
  (menu Setup > Power profile) follows omarchy-powerprofiles-set: the choice is stored per power
  source (`profile-ac` / `profile-battery` in the state dir) and `apply` uses it, so a manual
  override is not clobbered by the next plug/unplug; defaults are balanced / power-saver.
- **Install > Development = Omarchy's dev-env installer on mise** (`bin/hypr-dev-env`, ported from
  `omarchy-install-dev-env` / `omarchy-remove-dev-env`). Same tool choices: mise for everything it
  can version (`mise use --global <tool>@latest`, PHP via the `static-php-builds` alias, uv after
  Python), rustup for Rust, opam for OCaml. Differences: mise is not in the base package list (Omarchy
  ships `mise-bin`); `hypr-dev-env` offers to install it on first use, and `.zshrc` activates it only
  when present (plus shims on PATH, like Omarchy's env-bootstrap). `omarchy-pkg-add` became
  `pacman -S --needed` / `yay` (symfony-cli is AUR). The menu marks installed environments with ✓
  (Omarchy greys them out) using the same detection paths (`~/.local/share/mise/installs/<tool>`,
  `~/.rustup`, `~/.opam`, `~/.mix/archives/phx_new*`), and Remove > Development, like Omarchy, lists only installed ones (groups appear only when a member is installed; a "Nothing installed yet" placeholder goes back). Remove > AUR filters with `pacman -Qqm`.
  Rust: rustup lives in `~/.cargo/bin`, which is NOT on the Hyprland session PATH, so the
  first removal silently did nothing (`rustup ... 2>/dev/null || true`); `hypr-dev-env remove
  rust` now calls `~/.cargo/bin/rustup` explicitly and falls back to deleting `~/.rustup` and
  `~/.cargo`. Install runs rustup with `--no-modify-path` (it otherwise appends to ~/.zshenv,
  ~/.profile, ~/.bashrc, ~/.bash_profile); `.zshrc` adds `~/.cargo/bin` to PATH when present.
  Docker DB (`bin/hypr-docker-db`) ports omarchy-install-docker-dbs with the same `run` lines
  (ports on 127.0.0.1, dev credentials, `--restart unless-stopped`), plus list/remove and
  "already exists -> start it". Engine choice (2026-09-25, user's request): **rootless Podman**
  instead of Docker. It needs no root daemon and no sudo, which dissolves Omarchy's "docker group
  = passwordless root" trade-off; `podman-docker` provides a `docker` CLI, `podman-compose` and
  `DOCKER_HOST` (set in `.zshrc`) keep docker-compose/lazydocker working; `podman.socket` and
  `podman-restart.service` (user units) give the API socket and honour restart policies at login.
  Image names are fully qualified (`docker.io/library/...`) so they resolve under both engines.
  subuid/subgid for the user already existed on legionarch. If Docker is already installed the
  script still uses it (through sudo, no docker group) and writes a minimal log-rotation
  `/etc/docker/daemon.json`.
- **`hypr-menu` self-check.** Commit b8b94b6 accidentally deleted `update_items`, `process_items`,
  `remove_items` and `can_power` while a block of functions was replaced by text offsets, so Update
  and Remove opened as empty menus (only "Back") and System lost Suspend. `HYPR_MENU_CHECK=1
  hypr-menu` now verifies that every `menu:X` target and every `run_menu` items function is
  defined; `resi-shell doctor` runs it. Run it after editing the menu.
- **Update indicator and cleanup** (2026-09-25). `bin/hypr-updates` is our version of Omarchy's
  SystemUpdate bar widget: `checkupdates` (pacman-contrib, refreshes a temporary db without root;
  falls back to `pacman -Qu` when missing) plus `yay -Qua`, every 6 hours from a watcher started by
  `autostart.lua`. It reuses the REC-indicator trick (a generated Noctalia TOML adding a
  `custom_button` to the bar's `end` lane, then `noctalia msg config-reload`). `resi-shell update`
  runs `hypr-updates check` at the end so the button disappears, and now also offers to remove
  orphans (`pacman -Qtdq`, default No, only reported with `-y`) and prunes the cache with
  `paccache -rk2`, mirroring omarchy-update-orphan-pkgs / omarchy-update-pkg-prune.
- **Web apps** (`bin/hypr-webapp`) port omarchy-webapp-install / omarchy-launch-webapp /
  omarchy-webapp-remove: a `.desktop` in `~/.local/share/applications` whose Exec is
  `hypr-webapp launch "URL"`, which resolves the default browser's Exec from its desktop file and
  runs it with `--app=URL` (Chromium family only; falls back to Brave). Icons come from the site's
  apple-touch-icon, then `/apple-touch-icon.png`, then Google's favicon service, saved as 256px PNG
  under hicolor. gum prompts became plain `read` inside hypr-tui; the picker for removal is fzf.
  Launchers are recognised by that Exec marker, which is also how Remove > Web App decides to show.
- **Containers TUI** = `podman-tui` (AUR) via `bin/hypr-containers`, Super+Shift+D and Setup >
  Containers, in place of Omarchy's lazydocker: we run rootless Podman, so the native TUI needs no
  DOCKER_HOST bridge and sees pods too. podman-tui talks to `podman system connection` entries, and
  a rootless install has none, so it showed DISCONNECTED until `hypr-containers` / `hypr-docker-db`
  register `local` -> `unix://$XDG_RUNTIME_DIR/podman/podman.sock` as the default connection.
  It also lagged: the stock user `podman.service` runs `podman system service` with the default
  5-second idle timeout and info-level request logging, so a client polling every second kept
  reactivating it (journal showed "Received shutdown" every few seconds). `podman_api_setup`
  (in hypr-docker-db, called by hypr-containers) writes a user drop-in with `--time=0` and
  `--log-level=warning`, enables podman.service persistently, and restarts it. Enabling it at login raced with
  `podman-restart.service`: both are the first podman run after boot, and when they collide on setting up the
  rootless user namespace podman.service exits 125 with "unexpected fd received from systemd: cannot listen on
  it" and stays failed until a client hits the socket (seen on dynarch 2026-09-28; reproduced with isolated
  test units, 1 failure in 6 races). The drop-in now adds `Restart=on-failure`, `RestartSec=2` and a start
  limit of 5 per 2 minutes (0 of 10 races left it failed), and is rewritten when its content differs so
  existing machines pick it up; `resi-shell update` runs `hypr-docker-db api-setup` when Podman is installed,
  and `resi-shell doctor` warns when podman.service is failed. Window class `TUI.large` (1100x760) is a generic rule for
  big terminal UIs. `resi-shell doctor` now checks that the hypr-power and hypr-updates watchers
  are alive when run inside a Hyprland session.
- **Noctalia drift** (2026-09-30). Settings changed in Noctalia's GUI land in
  `~/.local/state/noctalia/settings.toml`, which always wins over the repo TOML and is not synced,
  so the two laptops drifted three times (clock capsule, control-center position, bar shape).
  `bin/noctalia-drift` compares state against `~/.config/noctalia/*.toml` and reports keys present
  in both with different values (numbers compared with 1e-4 tolerance, since the GUI stores
  0.99999998 for 1.0); `--fix` removes them from state with a timestamped backup and reloads.
  `resi-shell doctor` warns on drift. On legionarch the fix dropped four bar keys (thickness 27,
  margin_edge 8, padding 8, capsule_opacity 0.81) in favour of the repo's dynarch-made values, plus
  capsule_padding/radius which the repo leaves at defaults, and a lock-screen widget order that still
  listed the temporary `resi-test` headless output from the clamshell test.
- **Installer ISO** (`resi/iso/`, 2026-09-30, user asked for it "like Ryoku/Omarchy"). Studied both:
  Ryoku = mkarchiso + its own Go TUI + signed `[ryoku]` repo + full offline closure (too much to
  maintain for one person); Omarchy = archiso + archinstall + a configurator that emits archinstall
  JSON, then its installer runs in the chroot. We follow Omarchy: the JSON template (GPT, EFI 1 GiB,
  Btrfs `@ @home @log @pkg` with compress=zstd, Limine, optional LUKS, zram) is copied from their
  configurator; the wizard is bash + fzf; the repo's committed HEAD is baked into the ISO and
  `resi-shell install --chroot` runs as the user with a temporary NOPASSWD sudoers drop-in.
  `install.sh` grew `--chroot` (implies -y; chsh via sudo; git identity from RESI_GIT_NAME/EMAIL or
  skipped; gtk_theme deferred) and `first-login` (autostart.lua runs it every start, no-op without
  the marker `~/.local/state/resi/first-login-pending`). Online only for now; an offline mirror
  (AUR built at build time, vendored oh-my-zsh/p10k/TPM) is the next step if the ISO is shared.
  **Offline mirror** (2026-09-30, "a few minutes like Omarchy"): `resi/iso/offline-repo.sh` resolves the
  full closure with `pacman -Sp --dbpath <empty local db + copied sync dbs>` (699 packages, 1.6 GB;
  NVIDIA adds 0.5 GB), downloads packages + `.sig`, builds `yay-bin` + `resi/packages.aur` with
  makepkg (must run as a user), `repo-add`s them into `resi-offline`, and tars the git clones. The
  live installer prepends `[resi-offline]` (file://) to pacman.conf so pacstrap reads from the ISO;
  with no network it also drops core/extra so nothing is attempted online. In the chroot the
  target's pacman.conf is temporarily ONLY the local repo (the target has no core/extra sync dbs
  offline), `install.sh --offline` uses `pacman -S` without -y for pacman and AUR packages and the
  vendor tarballs for oh-my-zsh/p10k/fzf-tab/TPM; afterwards the clean releng pacman.conf is restored
  and the resi-offline sync db removed. nvim/tmux plugins and the Wallhaven plugin still need GitHub:
  an `offline-install-pending` marker makes the first `resi-shell update` say so and fetch them.
  First offline ISO build failed in the VM for a dumb reason: build.sh baked `git archive HEAD` while
  the installer scripts came from the working tree, so the ISO had the new `resi-iso-postinstall`
  but an `install.sh` without `--offline` ("unknown argument" -> nothing installed). build.sh now
  tars the tracked files from the working tree (version marked -dirty) and warns about untracked
  files; postinstall copies `/root/resi-install.log` into the target at `/var/log/resi-install.log`;
  the hostname prompt is validated (a stray Delete key had produced the hostname `[3~`).
  First VM install (2026-09-30) worked end to end except the greeter kept its default look: `first-login`
  called `greeter()`, whose first lines are `sudo install`/`sudo noctalia-greeter ...`; with no terminal
  sudo cannot prompt, `set -e` killed the script before `noctalia msg greeter-sync`. The sync is now
  its own sudo-free `greeter_sync()`. Anything run from autostart must not touch sudo.
  Two more from the same VM: (1) `~/dotconfigfiles` was not a git repo because `git init` ran before
  `chown` (tar extracted as root) - order swapped; (2) the lock screen used Noctalia's default login
  box because the compact centered layout only existed in `hosts/<host>/lockscreen-widgets.toml`,
  keyed by output name (eDP-2). `install.sh lockscreen_layout` now generates that file per machine
  from `hyprctl monitors` (first-login / install / `resi-shell lockscreen-layout --force`) unless a
  host overlay already provides it, then runs `noctalia-drift --fix` so GUI state cannot override it.
  `noctalia-drift` itself had two parser bugs found here: Noctalia indents nested table headers
  (`    [lockscreen_widgets.widget."..."]`), which the old `/^\[/` match skipped, and quoted values
  with a trailing comment were compared with the comment included. Fixed; on legionarch the fix then
  surfaced a real drift (`theme.templates.builtin_ids` had 10 templates enabled via the GUI vs 5 in
  the repo) which was reset to the repo's list. `resi-shell doctor` no longer stops on the first
  failing check (`set +e` inside doctor); before, it silently ended after the hyprctl check when run
  outside a Hyprland session (ssh).
  Third VM finding: the bar islands and control center were Noctalia's default blue. `[theme]`
  (source = wallpaper, dark, m3-tonal-spot) had only ever been set through the first-run wizard, so it
  lived in each machine's GUI state and never reached the repo. It is now `noctalia/theme.toml`;
  applying it in the VM immediately recolored everything from the wallpaper and re-rendered the
  templates (hypr/noctalia.lua, alacritty theme). Rule of thumb from these three: anything picked in
  Noctalia's GUI that should look the same on every machine must be copied into a repo TOML, and
  `noctalia-drift` is the check that it stayed there. Same treatment for the Wallhaven plugin:
  `noctalia/plugins.toml` declares it and `noctalia_plugins()` (first-login / install) runs
  `noctalia msg plugins enable noctalia/wallhaven`, which downloads it from the official source.
  And the wallpaper directory (`noctalia/wallpaper.toml`, `~/Pictures/Wallpapers`): the Wallhaven
  plugin saves into Noctalia's `wallpaper.directory` when its own `download_dir` is empty, and on a
  fresh machine that setting was Noctalia's default, so downloads landed elsewhere.
- **Mouse selection copies to the clipboard** (2026-09-30), like the Claude Code terminal: alacritty
  `selection.save_to_clipboard = true`, and because tmux owns the mouse, tmux.conf pipes selections
  to `wl-copy` on drag end / double-click (word) / triple-click (line) with `copy-pipe-no-clear` so
  the selection stays visible; `y` uses `copy-pipe-and-cancel wl-copy`. OSC 52 (`set-clipboard on`)
  stays as the fallback path. Inside nvim the mouse belongs to nvim (Shift+drag for the terminal).
  Alacritty gives no feedback that a selection was copied, so `bin/hypr-clipboard-toast watch`
  (autostart, single instance, kept as a bash parent so doctor can see it) runs `wl-paste --watch`
  and shows a Noctalia notification "Copied" with a one-line snippet, but only when the focused
  window's class is a terminal (Alacritty, TUI.*, hypr-*), so copies from browsers stay silent.
- **Backspace in `hypr-menu` submenus** means Back when the filter is empty. rofi cannot tell that
  apart from deleting a character, so in submenus Backspace is bound to `kb-custom-1` (exit 10) and
  the script decides: empty filter = back, otherwise it reopens rofi with the filter shortened by one
  character (Shift+Backspace / Ctrl+H still delete directly). rofi runs without `-no-custom` on
  purpose: with it, a custom key is ignored whenever the filter matches nothing, which made
  Backspace dead after a typo. Free-text Enter is rejected by the script instead (it reopens the
  same level with the filter kept). Verified with `wtype` key injection on 2026-09-24.

- **Demo video** (`bin/hypr-demo`, 2026-09-28). Records a ~3 minute tour with gpu-screen-recorder on the
  focused monitor while it drives every feature through IPC only (`noctalia msg`, `hyprctl dispatch`, the
  bin scripts): there is no key injection on these machines (no wtype/ydotool), so anything that needs a
  keypress is not in the tour. Captions are Noctalia toasts, cleared before each panel so they never cover it.
  It runs on empty workspaces 6/7 so the user's windows stay out of the video, and restores wallpaper, light/
  dark mode, volume, brightness, bar, scratchpad and workspace on exit (also on Ctrl+C or SIGTERM, tested). Left out on purpose
  because demo videos get shared: clipboard history, the Network tab and btop's net box (local IP),
  fastfetch's host module (laptop product code), and the lock screen (would stop the tour at the password).
  tmux runs on its own socket with the user's config minus the resurrect/continuum plugins, so no saved
  private session is restored into the video; btop gets a temporary config and a smaller font (it needs
  80x24 and a quarter screen is 22 rows). It refuses to start when the notification history is not empty,
  because it clears the history at the end. Scenes whose tool is missing (podman-tui, carousel, updates)
  are skipped instead of prompting.

- **Lock screen is hyprlock, not Noctalia's (2026-10-08).** Noctalia's lock screen only offers a login box and
  a clock widget; the user wanted a clock, date, battery and more, so `hypr-lock` → hyprlock replaced it. To keep
  exactly one locker, `[lockscreen] enabled = false` (lockscreen.toml) turns Noctalia's off, which also disables
  its lock-before-suspend monitor ("logind session lock monitor disabled" in its log). The pieces that replace it:
  idle.toml `action = "command"` → `hypr-lock`; session.toml `[[shell.session.actions]]` with `command` for Lock
  and Suspend (the panel runs them with `/bin/sh -c`); `hypridle.conf` with only `lock_cmd`/`before_sleep_cmd`
  (no listeners, Noctalia keeps the idle timers) so `loginctl lock-session` and PrepareForSleep still lock;
  `hypr-lid-close` and the menu call `hypr-lock`. Colors come from a user template rendered to
  `~/.config/hypr/hyprlock-colors.conf` (`rgba(r, g, b, a)` decimal form, which hyprlang accepts; `.hex` would
  need the `#` stripped); `hyprlock.conf` sources `hyprlock-colors.default.conf` first so it loads before the
  first render. `lockscreen-layout` and the host `lockscreen-widgets.toml` are kept for a quick way back.
  Widgets are one file each in `hypr/.config/hypr/hyprlock.d/` and the per-machine selection is a list of
  `source =` lines in `~/.config/hypr/hyprlock-widgets.conf` (written by `hypr-lock widgets`, outside the repo),
  so the repo config stays generic and the user never edits hyprlock syntax to turn a widget on. The weather
  widget reads Noctalia's own cache (`~/.cache/noctalia/weather.json`, WMO code → Nerd Font icon), so it follows
  the location set in Noctalia without a second weather setup.

- **WhatsApp as a built-in web app + the "WhatsApp Slim" Brave extension (`resi/brave-extensions/`).**
  Omarchy ships WhatsApp not as an app but as `WhatsApp.desktop` → `omarchy-launch-webapp
  https://web.whatsapp.com/` plus a Chromium extension loaded with `--load-extension` from
  `/usr/share/omarchy/...` (chat list collapses to an avatar rail under 1100 px, system theme forced on).
  Ported 2026-10-07: `webapps_default()` creates the launcher once with `hypr-webapp install WhatsApp
  https://web.whatsapp.com/ whatsapp` (Papirus icon name, so it works offline in the ISO chroot) and
  leaves a marker in `~/.local/state/resi/webapps-default-done`, so a user who removes WhatsApp does not
  get it back on the next run. The extension is vendored unchanged (MIT, Omarchy's pinned `key` kept so
  the id is stable), copied by `brave_extensions()` to `/usr/local/share/resi-shell/brave-extensions/`
  because `brave-flags.conf` cannot expand `~`. Brave 1.96 still honours `--load-extension` (verified
  with a probe content script in headless mode); Google Chrome dropped it, so this only works with
  Brave/Chromium-family browsers that keep the flag. If the flag is in place but the files are not
  copied yet (fresh stow before `install`/`update`), Brave shows a "Failed to load extension" dialog at
  start; `doctor` warns about exactly that.

- **Boot splash "Resi Arch" (`resi/boot/`)**, modelled on Omarchy's Plymouth theme. One root script,
  `resi/boot/setup-boot-splash.sh`, does everything and is idempotent: installs the Plymouth `script` theme from
  `resi/boot/plymouth/resi/`, inserts the `plymouth` hook right after `systemd`/`udev` in `HOOKS` (so it is before
  `encrypt`/`sd-encrypt` and the LUKS prompt is drawn by the theme), appends `quiet splash` to every `cmdline:` in
  `limine.conf` and to `/etc/kernel/cmdline` (UKI machines need both: systemd-stub prefers the command line Limine
  passes), writes a marked branding block at the top of `limine.conf` and renames `/Arch Linux` entries to
  `/Resi Arch`, points a UKI preset's `--splash` at our `splash.bmp`, then runs `mkinitcpio -P`. Edited files get a
  one-time `<file>.resi-bak`. It runs in `resi-shell install` only, never in `update`, because it touches the
  initramfs and the bootloader config. Everything is black (`000000`) with an off-white wordmark so firmware →
  Limine → UKI splash → Plymouth do not flash between colours. `/etc/os-release` is left alone: pacman, yay and
  other tools key on it, and Omarchy keeps it too. The logo has one source, the ASCII art in
  `resi/boot/logo.txt` (figlet "doom"): `make-assets.sh` renders it with JetBrains Mono into the Plymouth, UKI and
  ISO-menu images (one `<text>` per character on a 0.6 em grid, because librsvg collapses runs of spaces and ignores
  per-glyph `x` lists), and the ISO prints the same file on the installer screens and in the live motd. The assets
  are pre-rendered and committed (`resi/boot/make-assets.sh` regenerates them with rsvg-convert + ffmpeg), so installing needs no image tools and
  the theme does not depend on Plymouth's label plugin or a font in the initramfs (the passphrase prompt is a PNG).
  `RESI_BOOT_ROOT=/some/dir` runs the script against a fake root without root, plymouth or mkinitcpio, which is how
  the config rewriting is tested.

## Noctalia's two config layers (read this before debugging "my change didn't work")

Noctalia merges two layers, and the second always wins for any key it defines:

1. Files under `~/.config/noctalia/*.toml` — what's tracked in this repo (`noctalia/` package).
2. `~/.local/state/noctalia/settings.toml` — written by the Settings GUI and the first-run wizard.
   **Not tracked** (it's runtime state, differs per machine, and can contain UI-only session bits).

If editing a `.toml` file in this repo seems to have no effect, the same key is almost certainly
already set in `settings.toml` on that machine (usually from the wizard) and needs to be changed
through the GUI instead, or removed from `settings.toml` by hand. `resi-shell doctor` and
`noctalia config export` (merged view) are the fastest ways to check which layer actually won.

## Gotchas for anyone editing this repo (human or AI)

- **`sed -i` on a per-file stow symlink replaces the symlink with a regular file.** Packages stowed
  `--no-folding` (`hypr`, `noctalia`, `gtk`, `claude`, `bin`) expose every file in them as a
  standalone symlink in `$HOME`. `sed -i` writes a temp file and renames it over the target, which
  silently drops the symlink — the edit then lives only in `$HOME`, never reaches the repo, and
  `git status` shows nothing changed. This happened once (`hypr/bindings/noctalia.lua`, 2026-09-23)
  and cost two keybindings that only worked locally until caught. Edit through the repo path
  (`~/dotconfigfiles/...`) directly, or use `sed -i --follow-symlinks`. `resi-shell doctor` will
  flag it afterward as a stow conflict ("cannot stow ... over existing target").
- **Hyprland's `hl.env` never unsets a variable once set, only on a full Hyprland restart** (not on
  `hyprctl reload`). A conditional `hl.env(...)` that stops being called on a later reload leaves
  the *old* value in place for every new process, which is exactly how the GPU env bug above went
  unnoticed for a while. Any conditional environment variable needs an explicit "else" branch that
  sets the *other* value, not just an omission.
- **`pkill -f <pattern>`, run through this session's Bash tool, can match its own wrapper shell.**
  The tool runs every command inside a `zsh -c '<the whole command as text>'` invocation, so a
  pattern that matches part of the command text also matches that live wrapper process's cmdline —
  `pkill -f "alacritty --class hypr-keybindings"` and `pkill -f 'python3 .*carousel'` both killed
  the session's own shell this way. Prefer `pkill -x <exact-name>`, a PID from `hyprctl clients
  -j`, or a pattern anchored to the real binary path (`pkill -f '^python3 /home/.../script'`).
- **Process names longer than 15 characters break plain `pgrep -x`/`pkill -x`** (`comm` is
  truncated at 15 chars in `/proc`). `gpu-screen-recorder` (19 chars) is the concrete case in
  `bin/hypr-record`: its PID is captured via `$!` right after backgrounding it, not via
  `pgrep -x gpu-screen-recorder`, which would silently match nothing.
- **`install.sh` runs with `set -euo pipefail`, so `x=$(grep ... | ...)` aborts the whole script when grep
  finds nothing** (outside an `if` condition). `resi-shell doctor` stopped silently after "login shell is zsh"
  with exit 1 on 2026-09-28 because Noctalia had rotated its log (`noctalia.log` -> `noctalia.log.1` at 1 MB)
  and the greeter-sync line was only in the old file. Append `|| true` to such substitutions, and read both
  Noctalia log files when looking for past events.
- **Package lists: comments used to be allowed only on their own line.** A trailing comment
  (`ttf-jetbrains-mono-nerd   # font utama: ...`, added 2026-09-28) was passed to pacman word by word
  ("target not found: #, font, utama:..."); pacman aborted the whole transaction, so the system upgrade did
  not happen and `set -e` stopped `resi-shell update` before AUR, restow and reloads. `pkglist` now strips
  anything after `#` and surrounding whitespace, so both comment styles are safe in `resi/packages.*`.
- **A machine without `linux-headers` installed *before* `nvidia-open-dkms`** will have DKMS fail
  to build the kernel module, and the system silently falls back to `simpledrm`/software rendering
  — Hyprland still starts, just fully unaccelerated, with no error dialog pointing at the cause.
  `install.sh` installs `linux-headers` before the NVIDIA packages specifically to avoid this; if a
  machine still ends up on `simpledrm`, check `lsmod | grep -E 'nvidia|amdgpu'` and
  `journalctl -k -b | grep -i nvidia` before assuming it's a driver bug.

- **`dynarch` (Dynabook G83/HS, BIOS 8.90) needs `acpi_mask_gpe=0x6F` on the kernel command line.**
  Its firmware raises ACPI GPE `6F` about 290 times a second from boot (`/proc/interrupts` IRQ 9, `sci`
  and `gpe6F` in `/sys/firmware/acpi/interrupts/`). Every event runs a BIOS method, so `kacpid` +
  `kworker` ate one full core (25% "sys" CPU with the desktop idle) and the laptop drew 11 W at 45%
  brightness instead of ~5.5 W. `6F` is not the EC's GPE (that is `6E`, which is fine), so the kernel's
  EC storm detection never kicked in. Diagnosed 2026-09-24. Test without rebooting:
  `echo disable | sudo tee /sys/firmware/acpi/interrupts/gpe6F`, then watch `upower -i ... | grep
  energy-rate`. Permanent: the parameter is in `/boot/EFI/BOOT/limine.conf` (`cmdline:` line; the
  limine pacman hook only copies EFI binaries and never rewrites that file). Result: 5.4 W, ~10 h,
  charger detection, brightness keys and USB-C still work. Bootloader config is outside this repo,
  so a reinstall must re-add it by hand; check Dynabook for a BIOS newer than 8.90 first.
  **After installing from the resi ISO** the file is `/boot/EFI/arch-limine/limine.conf` (archinstall's
  location): append ` acpi_mask_gpe=0x6F` to the `cmdline:` line, after `quiet splash`, and reboot. Nothing in
  `install.sh` or `resi/boot/setup-boot-splash.sh` adds it; a DMI-matched quirk list was considered on
  2026-10-01 and left out on purpose, this note is the record.

## Evaluated and rejected

- **walker** as a launcher — see "rofi over walker" above.
- **wl-screenrec** for recording — AUR-only like `gpu-screen-recorder` but without its replay
  buffer or KMS-capture efficiency; kept as a fallback in `hypr-record`'s backend chain, not
  primary.
- **Tracking `lazy-lock.json`** — see "Key decisions" above.

## Open items / known limits

- Noctalia's launcher has no window-capture screenshot mode of its own; `hyprshot` is still used
  for `Shift+Print` (window screenshots) specifically.
- The GTK folder-icon color (Papirus) doesn't follow the wallpaper palette; only the app chrome
  does. `papirus-folders` (AUR) could recolor it but hasn't been added.
