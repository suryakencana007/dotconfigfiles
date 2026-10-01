# Troubleshooting

Start here:

```sh
resi-shell doctor
```

It checks the links into the repo, the configs, the background helpers, the login screen and more, and
says what to do for each problem it finds.

## Common cases

| What you see | What to do |
|---|---|
| Colors of an app do not follow the wallpaper | `noctalia-drift` shows settings changed in Noctalia's GUI that override the repo. `noctalia-drift --fix` restores them. |
| The login screen looks default | `noctalia msg greeter-sync` |
| A change in a config file has no effect | Hyprland: `hyprctl reload && hyprctl configerrors`. Noctalia: `noctalia config validate && noctalia msg config-reload`. |
| The bar or a panel is stuck | Menu > Update > Process > Shell restarts Noctalia. |
| Plugins are missing after an offline install | Connect to the internet and run `resi-shell update`. |
| The boot splash hangs or stays black | Press <kbd>Esc</kbd> to see the text. To turn it off see [Boot splash](/guide/boot-splash#if-the-splash-gets-in-the-way). |
| The update stops because of local changes | Follow the commands it prints, then run `resi-shell update` again. See [Updating](/guide/updating#if-you-changed-files-in-the-repo). |
| A laptop drains its battery while idle | See [Laptops](/guide/laptops#battery-draining-while-idle). |

## Where things are logged

| What | Where |
|---|---|
| Last update | `~/.cache/resi-shell-update.log` |
| Installation from the ISO | `/var/log/resi-install.log` |
| Noctalia | `~/.cache/noctalia/noctalia.log` |
| Hyprland config errors | `hyprctl configerrors` |

## Why is it built this way?

The [design notes](https://github.com/suryakencana007/dotconfigfiles/blob/main/NOTES.md) explain the
reasons behind the decisions, what to know before editing, and what was tried and dropped.
