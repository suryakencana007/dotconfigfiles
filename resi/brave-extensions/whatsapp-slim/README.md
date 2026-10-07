# WhatsApp Slim (Brave extension)

Makes WhatsApp Web (`https://web.whatsapp.com/`) behave in a tiled window:

- below 1100 px of width the chat list collapses to an avatar rail (Signal style), so the conversation
  keeps its space;
- WhatsApp's "system theme" mode is switched on, so it follows the desktop's dark/light setting.

Taken from [Omarchy](https://github.com/omacom/omarchy) (`default/chromium/extensions/whatsapp-slim`,
MIT License, Copyright (c) David Heinemeier Hansson). `manifest.json` keeps Omarchy's pinned `key`, so
the extension id is the same stable id as in Omarchy.

`resi-shell install` (and `update`) copies this folder to `/usr/local/share/resi-shell/brave-extensions/`
and `brave/.config/brave-flags.conf` loads it with `--load-extension`. It only touches `web.whatsapp.com`.
