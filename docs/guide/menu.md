# The menu

<kbd>Super</kbd>+<kbd>Space</kbd> opens one menu that reaches everything. Type to filter, Enter to
choose.

- Entries that open a submenu show a chevron on the right.
- In a submenu, <kbd>Backspace</kbd> on an empty search goes back.
- Pressing <kbd>Super</kbd>+<kbd>Space</kbd> again closes it.

## Sections

| Section | What is inside |
|---|---|
| **Apps** | the app launcher |
| **Learn** | key bindings, tmux keys, Hyprland wiki, Noctalia docs |
| **Trigger** | screenshots, screen recording, color picker, clipboard history, calendar |
| **Toggle** | night light, caffeine (no idle lock), Do Not Disturb, bar, Wi-Fi, Bluetooth |
| **Style** | theme carousel, palette and dark/light mode, wallpaper, random wallpaper, Noctalia settings |
| **Setup** | audio, network, Bluetooth, display, monitors, power profile, battery limit, containers, config files |
| **Install** | a package, an AUR package, a development environment, a web app |
| **Update** | resi-shell, firmware, check for updates, restart the shell |
| **Remove** | a package, an AUR package, a development environment, a web app |
| **About** | system information |
| **System** | lock, suspend, hibernate, logout, reboot, shutdown |

Some entries only appear when they make sense: Battery limit when the battery supports it, Suspend and
Hibernate when the system can do them, Remove > Web App once a web app exists.

## Installing and removing software

**Install > Package** and **Install > AUR** open a searchable list with a preview of each package.
Mark several with <kbd>Tab</kbd>, press Enter to install.

**Remove > Package** lists what you installed yourself, shows everything that would be removed with it
(including dependencies nothing else needs) and asks Yes or No before doing anything.

**Install > Web App** turns a website into its own window with an icon in the launcher.

**Install > Development** is described on [Development tools](/guide/development).

## Updating from the menu

**Update > Resi shell** runs `resi-shell update` in a floating terminal after a Yes/No question.
**Update > Firmware** checks for firmware updates. **Update > Process > Shell** restarts the bar and
panels if they misbehave. See [Updating](/guide/updating).
