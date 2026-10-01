# Several machines

The same repo runs on every machine. Most differences are handled by themselves:

- graphics drivers are detected at install time,
- monitors are covered by a wildcard rule,
- the lock-screen layout is generated for the screen it finds.

## Per-machine overlays

Real one-machine exceptions go into `hosts/<hostname>/`. The installer applies that folder only when
its name equals the machine's hostname, and ignores it everywhere else. A machine without an overlay
simply runs the generic setup.

Two machines are in the repo as examples, `legionarch` and `dynarch`.

## Add your machine

```sh
cd ~/dotconfigfiles
cp -r hosts/legionarch "hosts/$(cat /etc/hostname)"
# edit hosts/<hostname>/.config/hypr/local.lua for monitors or rules of this machine
resi-shell install
git add hosts && git commit -m "Add host overlay for $(cat /etc/hostname)" && git push
```

`local.lua` is loaded last by Hyprland, so anything in it wins over the shared config: a second
monitor, a scale factor, a rule for one device.

## Keeping machines in sync

Commit and push from `~/dotconfigfiles` on the machine where you made a change, then run
`resi-shell update` on the others.

Settings changed in Noctalia's Settings window are stored outside the repo and win over the files in
it, so two machines can drift apart without the repo changing. `noctalia-drift` lists such settings and
`noctalia-drift --fix` puts the repo back in charge.

## Installing an existing machine from the ISO

Type the hostname of its overlay in the installer's hostname question and the overlay is applied
during installation.
