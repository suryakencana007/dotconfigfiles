# Pi resources for resi-shell

This GNU Stow package installs the repository's specialized resources into
`~/.pi/agent` without replacing Pi's `settings.json`, credentials, sessions, or
other user data.

## Included resources

- Native Pi skills: `dotfiles-stow`, `hyprland-config`, `noctalia-config`, and
  `terminal-stack`.
- Specialized agents: `dotfiles-keeper`, `hyprland-tweaker`, and
  `noctalia-tweaker`.
- The Pi 1.4.0 subagent example extension, vendored as `extensions/subagent`.
  It runs each specialized agent in an isolated Pi process.

The skills are Pi-adapted copies of the Claude skills. Keep both copies aligned
when changing shared configuration knowledge. Agent tool lists use Pi's native
`read`, `bash`, `edit`, and `write` names.

## Usage

Pi discovers the skills automatically. Force one when needed with, for example:

```text
/skill:hyprland-config add a window rule for an application
```

The main agent can delegate work through the `subagent` tool. Example requests:

```text
Use the hyprland-tweaker agent to inspect the current key bindings.
Use dotfiles-keeper to audit all Stow links without committing anything.
```

After editing a resource while Pi is open, run `/reload`.
