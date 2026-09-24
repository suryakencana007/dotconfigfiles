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

- **Install menu is a straight port of Omarchy's `omarchy-pkg-install` / `omarchy-pkg-aur-install`**
  (`bin/hypr-pkg-install repo|aur`): `pacman -Slq` or `yay -Slqa` piped into fzf with the same
  preview bindings, then `pacman -S --noconfirm` / `yay -S --noconfirm aur/...`. Omarchy's
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
- **Backspace in `hypr-menu` submenus** means Back when the filter is empty. rofi cannot tell that
  apart from deleting a character, so in submenus Backspace is bound to `kb-custom-1` (exit 10) and
  the script decides: empty filter = back, otherwise it reopens rofi with the filter shortened by one
  character (Shift+Backspace / Ctrl+H still delete directly).

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
