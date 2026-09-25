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
  DOCKER_HOST bridge and sees pods too. Window class `TUI.large` (1100x760) is a generic rule for
  big terminal UIs. `resi-shell doctor` now checks that the hypr-power and hypr-updates watchers
  are alive when run inside a Hyprland session.
- **Backspace in `hypr-menu` submenus** means Back when the filter is empty. rofi cannot tell that
  apart from deleting a character, so in submenus Backspace is bound to `kb-custom-1` (exit 10) and
  the script decides: empty filter = back, otherwise it reopens rofi with the filter shortened by one
  character (Shift+Backspace / Ctrl+H still delete directly). rofi runs without `-no-custom` on
  purpose: with it, a custom key is ignored whenever the filter matches nothing, which made
  Backspace dead after a typo. Free-text Enter is rejected by the script instead (it reopens the
  same level with the filter kept). Verified with `wtype` key injection on 2026-09-24.

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
