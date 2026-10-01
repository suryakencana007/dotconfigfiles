# First steps

You have rebooted and logged in at the Noctalia login screen. Three things are worth doing right away.

## 1. Check that everything is in place

```sh
resi-shell doctor
```

It should end with `All healthy.` If not, each line says what is wrong and usually how to fix it.

## 2. Add wallpapers and pick one

```sh
cp /path/to/*.jpg ~/Pictures/Wallpapers/
```

Then press <kbd>Super</kbd>+<kbd>Ctrl</kbd>+<kbd>Space</kbd> for the wallpaper panel, or
<kbd>Super</kbd>+<kbd>Shift</kbd>+<kbd>Ctrl</kbd>+<kbd>Space</kbd> for the carousel. The colors of the
whole desktop follow the wallpaper you choose. <kbd>Super</kbd>+<kbd>Ctrl</kbd>+<kbd>Alt</kbd>+<kbd>Space</kbd>
opens the Wallhaven browser to download more.

## 3. Learn the keys

Press <kbd>Super</kbd>+<kbd>K</kbd> for the searchable list of every key binding, and
<kbd>Super</kbd>+<kbd>Space</kbd> for the menu. The short list is on [Everyday keys](/guide/keys).

## Also worth doing once

- Sign in to Brave and Spotify.
- On a laptop with a second graphics card, set the BIOS to hybrid graphics.
- If Noctalia opens its setup wizard, just go through it. The theme, plugins and color templates
  already come from the repo.

## If you want to push your own changes

The repo was cloned over HTTPS. To push, create an SSH key and switch the remote:

```sh
ssh-keygen -t ed25519 -C "$(cat /etc/hostname)"
cat ~/.ssh/id_ed25519.pub        # add it at https://github.com/settings/keys
cd ~/dotconfigfiles
git remote set-url origin git@github.com:suryakencana007/dotconfigfiles.git
```

If you forked the repo, use your fork's address instead.
