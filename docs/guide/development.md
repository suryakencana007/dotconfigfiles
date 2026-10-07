# Development tools

Menu > Install > Development sets up a language or tool with one click. Installed ones show a ✓, and
Menu > Remove > Development lists only what is installed.

## Languages

Most languages are installed through [mise](https://mise.jdx.dev), which is set up the first time you
need it.

| Through | Environments |
|---|---|
| mise | Ruby on Rails, Node.js, Bun, Deno, Go, PHP, Laravel, Symfony, Python (with uv), Elixir, Phoenix, Java, Zig, .NET, Clojure, Scala |
| rustup | Rust |
| opam | OCaml |

`resi-shell update` also updates the tools mise manages.

## Databases in containers

**Docker DB** starts a development database as a container: MySQL, PostgreSQL, Redis, MongoDB, MariaDB
or MSSQL. Each one listens only on this machine (`127.0.0.1`) and uses development passwords.

The containers run on **rootless Podman**, which is offered for installation the first time. The
`docker` and `docker compose` commands keep working through Podman's compatibility layer. If Docker is
already installed, it is used instead.

## Containers

<kbd>Super</kbd>+<kbd>Shift</kbd>+<kbd>D</kbd> (or Menu > Setup > Containers) opens podman-tui to look
at containers, images and logs.

## Web apps

Menu > Install > Web App turns a website into an app: its own window, its own icon in the launcher.
Remove it again under Menu > Remove > Web App.

**WhatsApp** is preinstalled this way: a launcher entry that opens `web.whatsapp.com` in its own Brave
window. A small bundled Brave extension ("WhatsApp Slim") collapses the chat
list to an avatar rail when the window is narrower than 1100 px, so WhatsApp stays usable in a tiled
layout, and switches WhatsApp Web to follow the desktop's dark/light theme. Removing WhatsApp under
Menu > Remove > Web App is permanent; the installer does not bring it back.
