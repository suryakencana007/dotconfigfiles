# Updating

One command updates everything:

```sh
resi-shell update
```

It is also in the menu under **Update > Resi shell**. It asks before it starts; add `-y` to skip the
question.

## What it does

1. Pulls the latest version of the repo.
2. Upgrades Arch and AUR packages, and installs packages that were added to the repo since last time.
3. Offers to remove packages nothing needs any more, and trims old package files.
4. Updates the development tools managed by mise.
5. Relinks the configs and updates the tmux and Neovim plugins.
6. Reloads Hyprland and Noctalia.
7. Offers a reboot if the kernel or Hyprland was replaced.

The whole output is saved in `~/.cache/resi-shell-update.log`.

## The update button in the bar

A background check runs every 6 hours. When updates exist, a button with their number appears in the
bar. Left click runs the update, right click lists what is waiting. Menu > Update > Check for updates
does the same check on demand.

## Firmware

Menu > Update > Firmware looks for firmware updates through fwupd (and offers to install fwupd the
first time).

## If you changed files in the repo

`resi-shell update` notices local changes. It shows them and offers to set them aside, pull, and put
them back (`git stash`, `git pull`, `git stash pop`).

If your branch has commits that are not on GitHub, or one of your changes conflicts with a new one, it
stops and prints the exact commands to run. Nothing is overwritten.

## After an offline install

The first `resi-shell update` with internet finishes the installation: it links the dotfiles repo to
GitHub and fetches the tmux and Neovim plugins.
