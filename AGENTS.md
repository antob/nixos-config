# Agent Guidelines for nixos-config

A multi-host, flake-based NixOS configuration with Home Manager integration.
All custom options live under the `antob.*` namespace.

---

## Build / Lint / Format Commands

The primary task runner is `just` (see `justfile`).

| Command | Description |
|---|---|
| `just build [host]` | Build current or named host config (`nixos-rebuild build`) |
| `just switch [host]` | Apply config to running system (`nixos-rebuild switch`) |
| `just test [host]` | Apply without creating boot entry (`nixos-rebuild test`) |
| `just boot [host]` | Apply on next boot (`nixos-rebuild boot`) |
| `just deploy <host> <target> [mode]` | Remote deploy via SSH |
| `just fmt` | Format all `.nix` files (`nix fmt`, uses `nixfmt-tree`) |
| `just iso [type]` | Build install or minimal ISO |

There is **no test suite** and **no CI**. Correctness is validated by `nixos-rebuild build` (dry run) or `nixos-rebuild test` on the target machine.

To validate a specific host config without switching:

```bash
just build <hostname>          # e.g. just build laptob-fw
```

To check formatting:

```bash
nix fmt                        # formats all .nix files via nixfmt-tree
```

---

## Repository Structure

```text
flake.nix          # Flake entry: all inputs and outputs
justfile           # Task runner
hosts/             # Per-machine NixOS configs (desktob, laptob-fw, hyllan, wiggum, …)
  common/          # Shared secrets (sops-encrypted secrets.yaml)
modules/           # All custom NixOS/HM modules under antob.*
  apps/            # GUI applications
  cli-apps/        # CLI tools
  desktop/         # Window managers (hyprland, niri, gnome, cosmic…)
    addons/        # Shared WM addons (waybar, mako, rofi, gtk…)
  features/        # High-level feature flags (common, desktop)
  hardware/        # Hardware modules (audio, bluetooth, networking…)
  home/            # Home Manager integration wrapper
  services/        # Services (openssh, tailscale, ollama, syncthing…)
  system/          # System-level (fonts, locale, time, zfs…)
  tools/           # User tools (zsh, git, starship, helix, neovim…)
overlays/          # nixpkgs overlays (stable, next, prev, additions, modifications)
pkgs/              # Custom packages
lib/               # Custom library functions extending nixpkgs lib
```

---

## Code Style

### Formatting

- **2 spaces** for indentation throughout — no tabs.
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
requires placing a file in the correct directory — no import list to update.

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
pkgs.nixpkgs-next.<pkg>  # from nixpkgs-next (newer unstable)
pkgs.nixpkgs-prev.<pkg>  # from nixpkgs-prev (pinned previous)
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

| Thing | Convention | Example |
|---|---|---|
| File names | `kebab-case` | `open-webui.nix` |
| Directory names | `kebab-case` | `cli-apps/` |
| Local Nix bindings | `camelCase` | `cfg`, `gtkCfg` |
| NixOS options | `camelCase` | `hostName`, `storageDriver` |
| Custom option namespace | `antob.*` | `antob.tools.git.enable` |
| Host names | `kebab-case` | `laptob-fw`, `desktob` |

---

## Key Architectural Decisions

- **`antob.*` namespace** — all custom options are under `antob` to prevent conflicts with upstream NixOS options.
- **Feature flags** — `antob.features.common` and `antob.features.desktop` act as presets enabling many sub-modules at once. Hosts opt into presets.
- **Impermanence** — root filesystem is ephemeral. Persistent data lives in `/persist` (system) and `/persist/safe` (user, backed up).
- **No CI** — validate with `just build <host>` locally; no automated test pipeline exists.
