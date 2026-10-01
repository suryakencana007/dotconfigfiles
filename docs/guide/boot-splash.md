# Boot splash

The machine boots with the Resi Arch logo and a progress bar instead of scrolling text, and the boot
menu entry is called "Resi Arch". If the disk is encrypted, the passphrase is asked on the same screen.

![The Resi Arch boot screen](/boot-splash.png)

## Setting it up

`resi-shell install` sets it up, and the installer ISO does it as its last step. `resi-shell update`
never touches it, because it changes the boot configuration.

```sh
sudo ~/dotconfigfiles/resi/boot/setup-boot-splash.sh --check     # report only, changes nothing
sudo ~/dotconfigfiles/resi/boot/setup-boot-splash.sh             # set up (again)
sudo ~/dotconfigfiles/resi/boot/setup-boot-splash.sh --remove    # back to the plain text boot
```

## What it changes

- Installs the Plymouth theme `resi` and makes it the default.
- Adds the `plymouth` hook to the initramfs.
- Adds `quiet splash` to the kernel command line.
- Renames the Limine boot entry to "Resi Arch" and sets the bootloader's title and colors.
- On machines that boot a unified kernel image, replaces the Arch logo shown before the splash.
- Rebuilds the initramfs.

Every file it edits is saved once as `<file>.resi-bak`. The system stays plain Arch Linux underneath;
`/etc/os-release` is not touched.

## If the splash gets in the way

Press <kbd>Esc</kbd> during boot to see the text behind it. To boot once without it, press
<kbd>e</kbd> on the entry in the Limine menu and delete the word `splash`. To turn it off for good, run
the script with `--remove`.

## Changing the logo

The logo has one source: the ASCII art in `resi/boot/logo.txt`. Edit it, run
`resi/boot/make-assets.sh`, then set up the splash again. The same file is printed on the installer
screens.
