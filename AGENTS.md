# Agent Guidelines for nixos-config

A multi-host, flake-based NixOS configuration with Home Manager integration.
All custom options live under the `antob.*` namespace.

---

## Where to Look (read this before scanning)

- This repo is the source of truth for all config. Never run `find`, `ls -R`, or
  `grep -r` across `/nix/store`, `/`, or the whole filesystem. Those trees are huge
  and slow.
- Do not build to resolve questions. `just build / switch / test / boot / deploy`
  and `nixos-rebuild ...` write to the store and change running system state. Only
  run them when the user explicitly asks you to. Never run them to inspect current
  configuration.
- `result` is an ignored symlink at the repo root pointing to the most recent local
  build. The path encodes the host: `/nix/store/<hash>-nixos-system-<host>-...`.
  Resolve it with `realpath result` or `just store-result`, and trust it only if it
  names the host you are working on (it may point to another host built previously).
  If it is missing or names a different host, do not rebuild. Ask the user to build
  the host you need.
- `flake.nix` declares the inputs/channels and which host subsystems they use.
- `flake.lock` pins every input to a committed revision. For a one-off lookup use
  `just store-rev <input>` (e.g. `nixpkgs`, `nixpkgs-stable`), or read it directly:
  ```bash
  jq -r '.nodes.<name>.locked.rev' flake.lock
  ```
  `just bump-prev` re-pins `nixpkgs-prev` to the locked rev of the current system.
- `modules/`, `hosts/`, `pkgs/`, `overlays/`, and `lib/` hold the actual config.
  Start there, never in the store. If you must touch `/nix/store`, start from the
  `result` symlink or a concretely named store path, never from the `/nix/store`
  root. The `store-*` steps are the only allowed store-adjacent lookups; the
  `build/switch/test/boot/deploy` steps are state-changing and off-limits for
  info-gathering.

---

## Build / Lint / Format Commands

The primary task runner is `just` (see `justfile`).

| Command                            | Description                                                |
| ---------------------------------- | ---------------------------------------------------------- |
| `just build [host]`                | Build current or named host config (`nixos-rebuild build`) |
| `just switch [host]`               | Apply config to running system (`nixos-rebuild switch`)      |
| `just test [host]`                 | Apply without creating boot entry (`nixos-rebuild test`)     |
| `just boot [host]`                 | Apply on next boot (`nixos-rebuild boot`)                    |
| `just deploy <host> <target> [mode]` | Remote deploy via SSH                                      |
| `just fmt`                         | Format all `.nix` files (`nix fmt`, uses `nixfmt-tree`)        |
| `just iso [type]`                  | Build install or minimal ISO                               |

Read-only store lookups (safe to run):

| Command                | Description                                                |
| ---------------------- | ---------------------------------------------------------- |
| `just store-result`    | Resolve `result` symlink to the most recent local build      |
| `just store-rev <input>` | Print the pinned revision of a flake input from `flake.lock` |

These `store-*` commands only read state and change nothing. The `build / switch /
test / boot / deploy / iso` commands write to the store and change system state; do
not run them to gather information. Ask the user when you need a host built or
switched.

There is **no test suite** and **no CI**. Correctness is validated by
`nixos-rebuild build` (dry run) or `nixos-rebuild test` on the target machine.

---

## Repository Structure

```text
flake.nix       # Flake entry: all inputs and outputs
flake.lock      # Pins every input to a locked revision
justfile        # Task runner
docs/           # Documentation (empty at present)
result          # Ignored symlink to the most recent local build in /nix/store

hosts/                     # Per-machine NixOS configs
  common/                  # Shared secrets (sops-encrypted secrets.yaml)
  <host>/                  # e.g. desktob, laptob, laptob-fw, hyllan, wiggum, pihole, pikvm
    default.nix            # Host options entry point
    hardware.nix           # Machine hardware config
    disk-config.nix        # Partition layout (desktop/laptop family)
    secrets.yaml           # Host sops secrets
    public_key.asc         # SSH/age public key

modules/                   # All custom NixOS/HM modules under antob.*
  apps/                    # GUI applications (firefox, vscode, thunderbird, …)
  cli-apps/                # CLI tools (neovim, helix, tmux, yazi, llm-agents, …)
  color-scheme/            # Color schemes (catppuccin, gruvbox, tokyonight, …)
  debug/                   # Debug helpers (track-changes)
  desktop/                 # Window managers (hyprland, niri, cosmic, gnome, plasma, mango, …)
    addons/                #   Shared WM addons (waybar, mako, rofi, gtk), keyring, …)
    scripts/               #   Shared WM scripts
  features/                # High-level presets (common, common-minimal, desktop, gaming, laptop, rpi)
  hardware/                # audio, bluetooth, fingerprint, ledger, networking, ddcutil, yubikey, …
  home/                    # Home Manager integration wrapper
  monitoring/              # Monitoring email defaults
  nix/                     # nixpkgs settings, overlay wiring, nix access tokens
  persistence/             # Persistent storage (preservation module)
  security/                # Hardening (gpg)
  services/                # avahi, openssh, tailscale, ollama, syncthing, restic-backup, …
  system/                  # console, env, fonts, info, locale, time, zfs
  tools/                   # CLI/user tools (zsh, git, starship, alacritty, fzf, …)
  user/                    # Default user account, default icon
  virtualisation/          # docker, podman, virt-manager

overlays/                  # nixpkgs overlays (stable, pkgs-next, pkgs-prev, additions, modifications, flake-inputs)
pkgs/                      # Custom packages
lib/                       # Custom library functions extending nixpkgs lib
```

---

## Code Style

### Formatting

- **2 spaces** for indentation throughout, no tabs.
- Formatter: `nixfmt-tree` (wrapper around `nixfmt`). Run `just fmt` before committing.
- File names: `kebab-case` (e.g. `open-webui.nix`, `color-scheme/`).
- Variable names: `camelCase` for local bindings (`cfg`, `gtkCfg`, `emailFrom`).
- NixOS option names: `camelCase` as per upstream convention.

### Module Signature

Every module uses the standard NixOS module function signature with arguments on separate lines:

```nix
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.antob.<category>.<module>;
in
{
  options.antob.<category>.<module> = { ... };
  config = mkIf cfg.enable { ... };
}
```

Only add `inputs` or `outputs` to the argument set when actually needed.

### `with lib;`

Always open with `with lib;` at the top of any file using lib functions. This brings
`mkIf`, `mkOption`, `mkEnableOption`, `mkMerge`, `types`, `enabled`, `disabled`, etc.
into scope without qualification.

### `let...in` Blocks

Use a `let` block to bind `cfg = config.antob.<module>;` as the first line of every
module. Derive other computed values there (e.g. package selections, path strings).

### Options Definition

```nix
options.antob.tools.git = with types; {
  enable    = mkEnableOption "Whether or not to install and configure git.";
  userName  = mkOpt str user.fullName "The name to configure git with.";
  userEmail = mkOpt str user.email   "The email to configure git with.";
};
```

- Use `mkEnableOption` for boolean on/off flags.
- Use the custom helpers from `lib/`: `mkOpt type default description`, `mkBoolOpt default description`, `mkOpt'`/`mkBoolOpt'` when a description is not needed.
- Always supply a description string as the third argument to `mkOpt`.
- Use `with types;` inside option blocks to avoid repeating `types.`.

### Custom Lib Helpers

Defined in `lib/default.nix` and available wherever `lib` is in scope:

```nix
lib.mkOpt        # mkOption shorthand: type → default → description → option
lib.mkBoolOpt    # mkOpt types.bool shorthand
lib.enabled      # { enable = true; }
lib.disabled     # { enable = false; }
lib.relativeToRoot  # lib.path.append from repo root
lib.scanPaths    # auto-discover .nix files in a directory (exclude default.nix)
lib.getFiles     # list plain files under a path
lib.mkSslProxy   # Caddy vhost builder with Let's Encrypt DNS challenge
lib.mkProxy      # Caddy vhost builder with internal TLS
```

### Config Guards

Every module must guard its `config` block with `mkIf cfg.enable`:

```nix
config = mkIf cfg.enable {
  # …
};
```

For modules with multiple independent flags, use `mkMerge`:

```nix
config = mkMerge [
  (mkIf cfg.enable       { … })
  (mkIf cfg.enableCache  { nix.settings = { … }; })
];
```

### `enabled` / `disabled` Shorthand

Use the `enabled` / `disabled` helpers in host configs instead of `{ enable = true; }`:

```nix
antob = {
  features.common     = enabled;
  hardware.bluetooth  = enabled;
  tools.git           = enabled;
  services.openssh    = disabled;
};
```

### Auto-Discovery (`scanPaths`)

Every category directory (e.g. `modules/tools/default.nix`) should import child
modules via `lib.scanPaths`:

```nix
{ lib, ... }: { imports = lib.scanPaths ./.; }
```

This auto-discovers all `.nix` files except `default.nix`. Adding a new module only
requires placing a file in the correct directory, with no import list to update.

### Home Manager Integration

Home Manager runs as a NixOS module, not a standalone flake output. Modules add
home-manager config through the unified `antob.home` API:

```nix
config = mkIf cfg.enable {
  antob.home.extraOptions = {
    programs.git.enable = true;
  };
  # or for file management:
  antob.home.configFile."some/path".source = ./file;
};
```

Never access `home-manager.users.<name>` directly from within a module; always go
through `antob.home.*`.

### Overlays and Multiple nixpkgs Channels

Custom packages and patched packages live in `overlays/`. The overlays expose
alternate channels as top-level attrs on `pkgs`:

```nix
pkgs.stable.<pkg>        # from nixpkgs-stable
pkgs.pkgs-next.<pkg>     # from nixpkgs-next (newer unstable)
pkgs.pkgs-prev.<pkg>     # from nixpkgs-prev (pinned previous)
```

Use these when a specific package version is needed from a different channel.

### Custom Packages

Packages in `pkgs/` use `pkgs.callPackage` or `pkgs.writeShellScriptBin`. They are
exposed via the `additions` overlay. Use `pkgs.<name>` to reference them from modules.

### Secrets (SOPS)

- Secrets are encrypted YAML files under `hosts/<name>/secrets.yaml` and `hosts/common/secrets.yaml`.
- Each host declares `sops.defaultSopsFile` and individual `sops.secrets.<key>` options.
- Access a secret at runtime with `config.sops.secrets.<key>.path`.
- Never hardcode secrets or place plaintext credentials in `.nix` files.

### Error Handling

- Use `lib.mkForce` at host level to override module defaults (e.g. `mkForce false`).
- Use `lib.optionalString`, `lib.optional`, and `lib.optionals` for conditional lists/strings.
- Use NixOS `assertions` for runtime validation where correctness cannot be enforced by types.
- No explicit `throw` / `abort` unless truly unrecoverable.

---

## Naming Conventions Summary

| Thing                   | Convention | Example                 |
| ----------------------- | ---------- | ----------------------- |
| File names              | `kebab-case` | `open-webui.nix`          |
| Directory names         | `kebab-case` | `cli-apps/`               |
| Local Nix bindings      | `camelCase`  | `cfg`, `gtkCfg`             |
| NixOS options           | `camelCase`  | `hostName`, `storageDriver` |
| Custom option namespace | `antob.*`    | `antob.tools.git.enable`  |
| Host names              | `kebab-case` | `laptob-fw`, `desktob`      |

---

## Key Architectural Decisions

- **`antob.*` namespace** all custom options live under `antob`, to prevent conflicts with upstream NixOS options.
- **Feature presets** the `antob.features.*` modules act as presets. `common`, `common-minimal`, `desktop`, `gaming`, `laptop`, and `rpi` enable many sub-modules at once. Hosts opt into presets instead of enabling every module individually.
- **Impermanence.** Root filesystem is ephemeral. Persistent data lives at `antob.persistence.path` (default `/persist`), and the `.safe` subfolder is additionally backed up offsite. Some hosts override the path (e.g. `laptob-fw` uses `/nix/persist`). System and user state is preserved via the `preservation` module, not written into the ephemeral root.
- **No CI.** Validate with `just build <host>` locally; there is no automated test pipeline.