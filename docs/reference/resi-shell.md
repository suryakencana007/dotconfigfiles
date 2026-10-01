# The `resi-shell` command

After installing, the installer is available everywhere as `resi-shell`. It is the same file as
`~/dotconfigfiles/install.sh`.

## Everyday commands

| Command | What it does |
|---|---|
| `resi-shell update` | Updates everything: the repo, Arch and AUR packages, development tools, plugins; then reloads the desktop. See [Updating](/guide/updating). |
| `resi-shell doctor` | Health check. Tells you what is wrong and usually how to fix it. |
| `resi-shell install` | The full setup again. Safe to repeat. |
| `resi-shell packages` | Prints the package lists. |
| `resi-shell lockscreen-layout` | Writes a centered login box for this machine's monitor on the lock screen. Done automatically; `--force` rewrites it. |

## Options

| Option | Meaning |
|---|---|
| `--dry-run`, `-n` | show what would be done, change nothing |
| `-y`, `--yes` | do not ask for confirmation |
| `--force` | overwrite a generated file that already exists (used with `lockscreen-layout`) |
| `-h`, `--help` | short usage |

## What `doctor` checks

- every Stow package is linked, and no link is broken;
- the key files exist and point into the repo;
- the Hyprland, Noctalia, rofi, tmux and zsh configs load without errors;
- the menu has no entry that leads nowhere;
- the scripts pass a syntax check (and shellcheck, when installed);
- the keyring is unlocked at login;
- the background helpers are running: battery mode, update check, clipboard note;
- the login screen has been synced with the desktop;
- the boot splash is consistent (theme, default, initramfs hook);
- Noctalia settings changed in its GUI that now override the repo (`noctalia-drift`);
- whether the repo has uncommitted changes.

Some checks only make sense inside the desktop session. Run over SSH, `doctor` skips them and says so.

## Commands used by the installer ISO

You normally never type these.

| Command | Purpose |
|---|---|
| `resi-shell install --offline` | packages (including pre-built AUR ones) come from the mirror on the ISO; git clones and Noctalia plugins come from bundles on the ISO |
| `resi-shell install --chroot` | runs inside the freshly installed system before its first boot; steps that need a running desktop are postponed |
| `resi-shell first-login` | started by Hyprland at every start; does the postponed steps once |
| `resi-shell iso-relink` | connects a repo installed from the ISO to GitHub; also done by the first `update` |

## The boot splash script

A separate script, because it needs root and changes the boot configuration:

```sh
sudo ~/dotconfigfiles/resi/boot/setup-boot-splash.sh [--check | --remove]
```

See [Boot splash](/guide/boot-splash).
