# Features

## Look and theme

- Colors come from the wallpaper. Noctalia builds a palette and renders it into alacritty, rofi, Neovim,
  GTK apps, the Hyprland borders, the prompt and the login screen.
- Bar, panels, notifications and the launcher share one style: frosted glass, square corners and the
  same 10 px spacing as the windows.
- Folder icons follow the theme too (`hypr-folder-color` picks the closest Papirus color).
- Thunar and other GTK apps use adw-gtk3 with Papirus icons in dark mode.
- WhatsApp is there from the start as a web app in its own window (see
  [Development tools](/guide/development#web-apps)).
- One font everywhere: JetBrains Mono Nerd Font.

Switch the look from the menu under **Style**, or with the [theme keys](/guide/keys#panels).

## Bar and panels

- A floating bar: launcher and workspaces on the left, date and time in the middle, and on the right
  the tray, network, Bluetooth, volume, brightness and battery. The playing track shows up only while
  something plays.
- Bar buttons: notifications, clipboard, caffeine (keeps the screen awake), night light, dark/light
  switch, control center and session menu.
- A red **REC** button appears while recording; click it to stop.
- An update button with a count appears when updates exist. Left click updates, right click lists them.
- The control center shows weather and a calendar.
- The screen locks after 10 minutes without input and switches off after 11.

## Lock screen

<kbd>Super</kbd>+<kbd>Ctrl</kbd>+<kbd>L</kbd>, the session menu, the idle timer, closing the lid and
suspending all lead to the same lock screen (hyprlock): the blurred desktop, the password box and the
widgets you choose, in the colors of the current wallpaper.

**Menu > Setup > Lock screen > Widgets** turns widgets on and off (Enter toggles, Esc finishes; the
change shows at the next lock). Available: 24-hour or 12-hour clock, date, user name, avatar
(`~/.face`), a "type your password" hint, machine name, battery, keyboard layout, now playing, and the
weather from Noctalia's own location setting. The choice is per machine and kept in
`~/.config/hypr/hyprlock-widgets.conf`; each widget is a small file in `~/.config/hypr/hyprlock.d/`,
so a new one is a copy of an existing file with another position or command. Colors are rendered by
Noctalia into `hyprlock-colors.conf` whenever the theme changes, so every widget follows the wallpaper.

## Screenshots and recording

- A screenshot freezes the screen, lets you select an area and annotate it, then goes to the clipboard
  and to `~/Pictures/Screenshots`.
- Recording uses gpu-screen-recorder: 60 fps with desktop audio, encoded on the graphics card. One key
  starts it, the same key stops it.

## Terminal

- alacritty with zsh, oh-my-zsh and a one-line Powerlevel10k prompt.
- Tools: fzf, zoxide, eza, bat, fd, ripgrep, delta, dust, duf, btop, tldr, lazygit.
- Selecting text with the mouse copies it, also inside tmux, and shows a small "Copied" note.
- tmux with `Ctrl+Space` as the prefix; sessions survive a reboot.
- Neovim with LazyVim; its colors change live with the theme.

## Login, passwords and SSH

- The login screen (greetd with noctalia-greeter) wears the same wallpaper and colors as the desktop.
- Your login password also unlocks the keyring, so Brave can store passwords and your SSH keys stay
  unlocked for the session.

## Media

mpv with yt-dlp is the default video and audio player, with hardware decoding.

## More

- [Laptops](/guide/laptops): battery mode, power profiles, battery limit, lid, night light.
- [Development tools](/guide/development): languages, databases, containers, web apps.
- [Boot splash](/guide/boot-splash): the Resi Arch boot screen.
