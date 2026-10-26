# Island

A dynamic island for Noctalia. When the track, the volume, the microphone or the screen brightness
changes, a capsule appears just below the bar, expands with an overshoot, holds for a moment, then
collapses and removes itself.

Rest the pointer on it and it opens into a media card: album art, title and artist, elapsed and
remaining time around a draggable seek bar, and working previous / play-pause / next buttons. Move
away and it collapses again. Clicking the bar widget opens the same card without waiting for an
event.

## The card

A layer surface takes full pointer and keyboard input, the same dispatcher a panel uses, so the
controls are real controls rather than a picture of them.

Three things make it behave:

- **Hover is counted, not flagged.** Only the innermost hovered element reports, so moving the
  pointer onto a transport button makes the card itself report *leave*. Every interactive node
  therefore carries the same `onHover` handler with its own `key`, and the island is "hovered" while
  that set is non-empty. The seek slider is the exception — see below.
- **A grace period of 280 ms.** The panel grows and shrinks under the pointer, so without the delay
  a pointer resting near its edge toggles enter/leave and the island blinks. The same delay covers
  the one frame where the capsule node is replaced by the card node.
- **The content is derived from the animating size.** Every child reads the width and height the
  tracks are currently at, so the album art shrinks, the clocks drop out below 240 px and whole rows
  are released from the bottom as the height runs out. There is no clip prop in `ui.*`, so a child
  that keeps a fixed size inside a parent that is still moving simply overflows it. The bar capsule
  always worked this way; the card did not, and that was visible as a faded copy of it hanging at
  the old size while the panel had already shrunk.

Opened by click or IPC instead of hover, the card gets the same hold timeout a toast does - nothing
will ever report a pointer leaving it otherwise.

Once every track has finished, `setNeedsFrameTick` is turned **off** and `update()` at 100 ms takes
over — it drives the hover deadline, the position poll and a 10 Hz redraw for the progress bar.
Skipping the render alone is not enough: while the frame tick is on, the layer asks for a frame 60
times a second and its surface is recomposited that often whether anything changed or not. An open
card costs ~17.5 % of a core with the tick left on and ~4.3 % with it off, against ~1 % idle.

Every function that starts an animation turns the tick back on itself. Waiting for the next
`update()` to notice would run the first 100 ms of the motion at 10 fps, which is visible as a stall
exactly where the eye is looking.

## The seek slider steals hover, and cannot give it back

`ui.slider` has no `onHover` prop — the host rejects unknown props loudly — but it does carry its
own `InputArea`, and exactly one input area is hovered at a time. So the moment the pointer touches
the handle, the card reports *leave* and nothing reports *enter*: hovering the slider looks exactly
like having walked away, and the card would collapse under the pointer that came to drag it.

There is no pointer-position API for a layer, so the position is inferred from the geometry instead.
The slider is the **only** region of the card that does not report hover, and the row that holds it
is padded on all four sides (`CARD_SEEK_PAD`, plus the two clock labels, which are not input areas
and therefore report to their row). That makes the row a fence: a pointer can only reach the handle
through it. So a hover that is lost *immediately after the seek row* means the pointer probably
moved onto the slider, and that case gets 2.5 s instead of the usual 280 ms grace.

Measured, by entering the surface at a point rather than moving across it — a cursor warp inside one
surface produces no motion events at all, so nothing in here can be tested by warping around inside
the card:

| Pointer enters the card on… | reports |
|---|---|
| album art or title | `true` key `island-card` |
| a transport button | `true` key `playpause` |
| the seek handle | **nothing at all** |
| a clock label, or the band above or below the handle | `true` key `seek` |

The fence cannot tell "moved onto the handle" from "flicked out of the card sideways through the
seek row". The second ought to cross the card's own 16 px padding and report *enter* again, but a
fast enough flick can outrun the sampling, and then the card hangs around for the full 2.5 s. That
is the cost of the deadline, and why it is 2.5 s rather than longer: it only has to cover arriving
at the handle and pressing it, because pressing fires `onChange`, and every step of a drag pushes
the deadline out again — which is what keeps the card alive while the pointer is dragged outside it.

Only the final value is sent: `onChange` fires per pixel and merely updates the displayed value,
`onDragEnd` runs `playerctl position <seconds>`. The value is pushed on every render, and the host
refuses to apply it while the handle is held, so the 1 Hz poll cannot snatch the handle away
mid-drag. Nothing reports `CanSeek` through `playerctl --follow`, so a player that cannot seek
simply ignores the command and the next poll puts the handle back.

## The surface never animates — the panel inside it does

This is the part that is easy to get wrong, and it looks like a compositor bug when you do.

A layer anchored to `top` alone is centred by the compositor, which means its **width determines its
x**. Animating that width every frame makes x trail its own size by a frame, and the strip the
surface vacated is not repainted: a stale rectangle clings to the right-hand side of the panel for
the whole collapse. It reads exactly like a shadow lagging behind, and no amount of blur, layer-rule
or animation tweaking in Hyprland touches it — it is not Hyprland's doing.

So the surface is **pinned** and the panel is animated inside it, centred by `Render.floatStage`.
The surface size changes only when the mode changes, and only ever **upward**: `[[layer]]` declares
the toast size and `noctalia.layer.configure` grows it to the card size when the card opens.
Growing vacates nothing, so it leaves nothing stale behind, and the surface is never shrunk while it
is on screen — `hide()` destroys it instead.

The cost is that the surface keeps its full rectangle as an input region even where it is
transparent. That is why the manifest declares the *toast* size, the common case: a card-sized
surface only exists while the card is actually open.

## Opening it on demand

```sh
noctalia msg plugin resi/island:island focused open
```

Bind that to a key, or click the bar widget. The capsule and the card share one surface, so this
reuses whatever is already on screen instead of stacking a second one.

## Two surfaces, one engine

The island exists twice, and both halves share `render.luau` and `anim.luau`:

- `[[layer]] float` — the floating capsule, a layer-shell surface the plugin owns. This is the real
  island and it is on by default.
- `[[widget]] island` — a capsule inside the bar. While the floating island is on, this one stays
  collapsed as a single icon that recolours with the event and carries the tooltip; turn
  **Floating island** off and it takes over the expanding instead.

A layer is lazy: nothing exists until `watch.luau` calls `noctalia.layer.show("float")`, and the
layer script hides itself once the collapse finishes, so no surface lingers between events.

The floating version is anchored to `top` only, which centres it horizontally — that is what makes
its own width decide its x, and why the surface is pinned instead. `margins.top = 10`
is measured from the usable area, with the bar's exclusive zone already subtracted, so it lands in
exactly the spot the built-in OSD used.

## Why the animation is hand-rolled

`ui.*` has no transition, easing or spring props (upstream
[#3507](https://github.com/noctalia-dev/noctalia/issues/3507),
[#4221](https://github.com/noctalia-dev/noctalia/issues/4221) are both open), so every frame is
computed here. `anim.luau` keeps one `Track` per animated property and reads the wall clock with
`noctalia.nowMs()` rather than integrating frame deltas. That is deliberate: the layer gets
`onFrameTick`, but **bar widgets never do** — `island.luau` has to drive itself with
`noctalia.setUpdateInterval` (16 ms while moving, 1000 ms at rest). Reading the clock makes the same
module correct under both.

Cost on this machine: ~1 % of one core at rest, ~14 % while a capsule is actually animating.

## Event sources

Noctalia 5 has no host API for any of these, so each one is an outside process that `watch.luau`
turns into a single stream of events on the shared state key `island.event`:

| Event | Source | Notes |
|---|---|---|
| Media | `playerctl --follow` | Attaches to players that appear *after* it starts, so login order does not matter. `file://` art is used in place; `https://` art (Spotify) is downloaded into the plugin data directory and cached by a hash of its URL, so it shows up too. |
| Volume | `pactl subscribe` → `wpctl get-volume @DEFAULT_AUDIO_SINK@` | `on sink #` only; `sink-input` is per-app volume. |
| Microphone | same `pactl subscribe` → `@DEFAULT_AUDIO_SOURCE@` | `on source #` only, not `source-output`. |
| Brightness | `udevadm monitor --subsystem-match=backlight` → `/sys/class/backlight/…` | The hardware keys call `noctalia msg brightness-*`, so nothing on the key side can be watched; the kernel uevent fires whoever writes the value. The device name is taken from the uevent, not hardcoded — this machine has both `amdgpu_bl2` and `nvidia_0`. |

`pactl subscribe` reports only *that* something changed, never the value, which is why each audio
event is followed by a `wpctl` read. All four sources debounce, because holding a key repeats.

Every stream is started with `exec` in front of it. `runStream` runs its command through `/bin/sh`
and kills the process it spawned; without `exec` that process is the shell, and `playerctl` survives
as an orphan on PID 1 after each reload.

That covers the plugin's own lifecycle — disabling the plugin, or disable/enable to restart the
service, does reap all three. It does **not** cover the shell dying. Measured on v5.4.0: a plain
`SIGTERM` to Noctalia (what `hypr-restart-shell` sends; it never had to escalate) left all three
watchers reparented to PID 1 and still running, and a second restart left three more. Nothing in the
plugin can prevent that: the teardown that would kill them belongs to the process that is being
killed. So after every shell restart:

```sh
ps -eo pid,ppid,cmd | awk '$2==1 && /playerctl --follow|pactl subscribe|udevadm monitor/'
```

and kill what it lists. They are idle — `playerctl --follow` only wakes on a D-Bus signal — so the
cost is three process table entries per restart, not CPU.

The media event carries the player's own name, and every transport command passes it with `-p`.
`playerctl` without `-p` acts on the first player on the bus, while `--follow` reports the *active*
one - on a machine with both a browser and Spotify open those are not the same player, and the card
would otherwise pause something the user cannot see.

There is no position stream, so the card polls `playerctl position` once a second while it is open
and advances the value from the wall clock between polls. Nothing is polled while it is closed.

## It replaces the built-in OSD for the kinds it covers

`notifications.toml` turns off `[osd.kinds]` `volume`, `volume_output`, `volume_input`, `media` and
`brightness`. Without that, Noctalia's own OSD draws in the same place and you get two stacked
capsules.

The remaining kinds — bluetooth, caffeine, dnd, nightlight, power_profile, keyboard_layout,
keyboard_backlight, lock_keys, privacy, wifi — **stay on the built-in OSD**, because a plugin has no
way to observe them: `noctalia msg status` exposes only `barVisible`, `panelOpen`, `activePanelId`
and `locked`. Covering them would mean polling, which is not worth a 1 Hz loop.

## Entries

- `[[layer]] float` — the floating island (`float.luau`).
- `[[widget]] island` — the bar capsule (`island.luau`).
- `[[service]] watch` — headless; owns the three watcher processes and publishes two state keys:
  `island.event` (a JSON string with an incrementing `seq`, so two identical events in a row still
  register) and `island.media`, the last known track. They are separate because the card must be
  openable long after the track changed, while the trigger is single-use.

`watch.luau` writes the state key *before* calling `show`, because a freshly created layer script
reads that key on startup to find the event that triggered it. If the layer is already up, its
`state.watch` handles the new event instead and `show` is a no-op.

## Requirements

`playerctl` for media, `pactl` + `wpctl` for volume and microphone, `udevadm` (systemd, always
present) for brightness. Each source degrades on its own: a missing tool only disables that one
source and logs a line.

Needs **plugin API 36** for the `[[layer]]` entry, which means Noctalia built from `main`
(`noctalia-git`) — the 5.3.0 release only supports up to API 34.

## Hyprland

Plugin surfaces use their own namespace, `noctalia-plugin:<author>/<plugin>:<entry>` — here
`noctalia-plugin:resi/island:float`. It is not matched by the `^noctalia-(bar-.+|…)$` rule, so
`looknfeel.lua` carries a separate `hl.layer_rule` for blur, with the same `no_anim = true`: the
panel inside the surface animates every frame, and Hyprland's own layer fade only smears it.

While the screen is locked the island still animates behind the lock screen, but it cannot be seen —
a session-lock surface sits above every layer-shell layer, overlay included.
