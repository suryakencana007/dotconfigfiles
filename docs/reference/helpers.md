# Helper scripts

Small programs in `~/.local/bin` that the menu, the key bindings and the bar call. You can run them
from a terminal too.

## Menu and launcher

| Script | Purpose |
|---|---|
| `hypr-menu` | the menu on <kbd>Super</kbd>+<kbd>Space</kbd> |
| `rofi-toggle` | opens the launcher, or closes it when it is open |
| `hypr-keybindings` | searchable list of key bindings (<kbd>Super</kbd>+<kbd>K</kbd>) |
| `hypr-tui` | runs a command in a floating terminal and waits for a key; also provides the Yes/No prompts |

## Theme

| Script | Purpose |
|---|---|
| `hypr-theme` | palettes, dark or light mode, gallery |
| `hypr-theme-carousel` | sliding wallpaper carousel; the centered card is the selection |
| `hypr-folder-color` | makes folder icons follow the theme (`apply`, `set`, `pick`, `list`, `status`) |

## Software

| Script | Purpose |
|---|---|
| `hypr-pkg-install` | package picker for install and removal, official repos and AUR |
| `hypr-dev-env` | development environments (`install`, `remove`, `installed`, `list`) |
| `hypr-docker-db` | development databases in Podman (`install`, `remove`, `list`) |
| `hypr-containers` | podman-tui, installed on first use |
| `hypr-webapp` | web apps as launcher entries (`install`, `remove`, `launch`, `list`) |

## Power and hardware

| Script | Purpose |
|---|---|
| `hypr-power` | battery mode, power profile and battery limit (`status`, `apply`, `watch`, `profile`, `charge-limit`) |
| `hypr-monitors` | opens the monitor layout tool with paths that keep the repo untouched |
| `hypr-clamshell`, `hypr-lid-close` | lid handling with and without an external monitor |

## Updates

| Script | Purpose |
|---|---|
| `hypr-updates` | the update indicator (`check`, `list`, `watch`, `clear`) |
| `hypr-update-firmware` | firmware updates through fwupd |
| `hypr-restart-shell` | restarts Noctalia safely (refused while the session is locked) |

## Capture

| Script | Purpose |
|---|---|
| `hypr-record` | starts or stops a screen recording |
| `hypr-clipboard-toast` | the "Copied" note for terminal selections |
| `hypr-demo` | records an automatic tour of the features to `~/Videos/resi-shell-demo.mp4` (`--no-record` for a dry run, `--shots DIR` for screenshots per scene) |

## Maintenance

| Script | Purpose |
|---|---|
| `noctalia-drift` | lists Noctalia GUI settings that override the repo; `--fix` restores the repo's values after a backup |
| `resi-shell` | see [The resi-shell command](/reference/resi-shell) |
