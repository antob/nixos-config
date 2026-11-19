# Agent reference

Longer reference material moved out of `AGENTS.md` to keep the always-loaded context
small. Read the relevant section when the task needs it.

## Reading nixpkgs source and option definitions

To understand what an upstream option does or where a package is defined, do NOT
grep/find across `/nix/store` or the whole filesystem. Those trees are huge and
slow. The pinned nixpkgs source already exists in the store; resolve it to a
concrete path first, then search only inside that path.

```bash
NIXPKGS=$(just nixpkgs-src)   # e.g. /nix/store/<hash>-source (eval only, no build)
```

Then grep/read against `$NIXPKGS` directly, never against `/nix/store` itself:

```bash
rg -l "options\\.programs\\.vscode" "$NIXPKGS/nixos/modules/programs"
less "$NIXPKGS/nixos/modules/programs/vscode.nix"
```

Useful directories inside the source:

| Path                              | Contents                                         |
| --------------------------------- | ------------------------------------------------ |
| `nixos/modules/`                  | NixOS module/option definitions                  |
| `nixos/modules/services/`         | Service options (`systemd`, `web`, …)             |
| `nixos/modules/programs/`         | Program options (`vscode.nix`, `firefox.nix`, …) |
| `pkgs/top-level/all-packages.nix` | Central package attribute map                    |
| `pkgs/by-name/`                   | Package definitions keyed by name                |
| `lib/`                            | nixpkgs `lib` helpers (`mkOption`, `mkIf`, …)    |
| `nixos/modules/misc/`             | Core system options (`system.nixos`, …)          |

To inspect what an option resolves to (not just its default), evaluate the
configuration read-only instead of building:

```bash
nix eval --json .#nixosConfigurations.desktob.config.services.openssh.enable
```

Prints `true`/`false` (use `--json` for non-string option values; `--raw` only
prints strings). This runs a full evaluation (~10s the first time, cached
afterwards) but writes nothing to the store. Prefer `nix eval` over
`nixos-rebuild build` when answering "what value does option X have on host
Y?".

The alternate channels (`nixpkgs-stable`, `nixpkgs-next`, `nixpkgs-prev`) are
separate flake inputs and have their own store paths. When a question targets
those specifically, look in `modules/flake/overlays.nix` to see how they are wired
to `pkgs.stable.*` / `pkgs.next.*` / `pkgs.prev.*`, then resolve the
evaluated package set the same way (e.g. `nix eval --raw
.#nixosConfigurations.desktob.pkgs.stable.path`).

To check which version of a package a host actually gets (e.g. after the user
updated inputs), evaluate it instead of guessing from the lock:

```bash
nix eval --raw .#nixosConfigurations.desktob.pkgs.hyprland.version
nix eval --raw .#nixosConfigurations.desktob.config.boot.kernelPackages.kernel.drvPath
```

To read the source of one package as a host sees it (overlays and channels applied),
use `just pkg-src <attr> [host]` and search inside the printed path. It fetches the
source into the store if missing and builds nothing.

## Raspberry Pi hosts (pihole, pikvm, pidesk)

These are built with `inputs.nixos-raspberrypi.lib.nixosSystem` and evaluate
against nixos-raspberrypi's own (older, stable) nixpkgs. They import the `rpi`
profile (`modules/profiles/rpi.nix`), which is `shell` plus the RPi bits.

- Options that only exist in newer nixpkgs (or in flake inputs these hosts do not
  import) break RPi evaluation, even when unused. Keep that in mind when editing
  aspects that `rpi` imports, directly or as a dependency.
- Kernels come from `nixos-raspberrypi.cachix.org`. If a build starts compiling
  `linux-config-*` / the kernel, the derivation drifted from upstream's cached
  one; check `nixos-raspberrypi`'s transitive `nixpkgs` node in `flake.lock`.
