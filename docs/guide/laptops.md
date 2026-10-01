# Laptops

Everything here works without root and starts by itself with the desktop.

## Battery mode

Unplug the charger and the desktop switches to saving power:

- the power profile becomes **power-saver**,
- brightness is limited to 50% (raise it by hand if you like),
- the panel drops to its lowest refresh rate, if it has more than one.

Plug in again and the profile, brightness and refresh rate come back.

## Power profile

Menu > Setup > Power profile switches between performance, balanced and power-saver. A ✓ marks the
active one. Your choice is remembered separately for battery and for charger, so a manual pick survives
plugging and unplugging. The defaults are balanced on the charger and power-saver on battery.

## Battery limit

Menu > Setup > Battery limit stops charging at 80% and resumes at 75%. That is easier on a battery that
spends most of its life plugged in. The setting survives reboots.

The entry only appears when the battery reports that it supports a limit. Some firmware accepts the
setting and ignores it; the menu says so when that happens.

## Lid

Closing the lid locks the screen and suspends the laptop.

With an external monitor attached it does not suspend. The laptop panel switches off instead (clamshell
mode) and comes back when you open the lid or unplug the monitor.

## Night light

The screen warms up from sunset to sunrise, with a one-hour fade. On the moon button in the bar, a left
click switches it on or off and a right click forces it on; the icon shows which of the three it is.

## Monitors

Menu > Setup > Monitors opens a graphical tool to arrange screens. Its layout is saved outside the repo
and loaded automatically.

## Battery draining while idle?

A few laptops have firmware problems that keep one CPU core busy. Check the
[design notes](https://github.com/suryakencana007/dotconfigfiles/blob/main/NOTES.md) for known cases
(for example the Dynabook G83/HS) and how they were diagnosed.
