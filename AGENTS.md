# Agent Guidelines for nixos-config

A multi-host NixOS configuration in the dendritic pattern: every `.nix` file under
`modules/` is a flake-parts module, loaded by import-tree. Features are *aspects*
(`flake.modules.nixos.<name>` / `flake.modules.homeManager.<name>`) that hosts and
presets import. Custom settings live under the `antob.*` namespace.

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
- `modules/` (aspects, hosts, overlays, flake.lib) and `pkgs/` hold the actual config.
  Start there, never in the store. If you must touch `/nix/store`, start from the
  `result` symlink or a concretely named store path, never from the `/nix/store`
  root. The `store-*` steps are the only allowed store-adjacent lookups; the
  `build/switch/test/boot/deploy` steps are state-changing and off-limits for
  info-gathering.
- Flakes only see files tracked by git. A new file you create is invisible to
  `nix eval` / builds until it is added. Run `git add -N <file>` (intent-to-add,
  stages no content) or tell the user it must be added before they rebuild.

---

## Working With the User

- The user builds and switches hosts themselves. When a change is ready, say which
  host needs `just build` / `just switch` and stop there. Verify with `nix eval`.
- When the user pastes a build failure, find the failing derivation (the first
  `Cannot build` line; the rest are dependents). Usual fixes, in order of preference:
  use `pkgs.prev.<pkg>` or `pkgs.stable.<pkg>`, or add a scoped override in the
  `modifications` overlay (`modules/flake/overlays.nix`) such as `doCheck = false` or a
  pinned `src`. Mark temporary workarounds with a `TODO:` and the upstream issue/PR.
- "Investigate, do not fix" means read-only: no file edits, no service restarts,
  no deletions. Report findings and wait.
- Much of the work is live debugging of the running machine (network, input
  devices, printers, services), not just config edits. Usually the local host is
  `desktob`; check with `hostname`. Prefer read-only diagnostics (`journalctl`,
  `systemctl status`, `ip`, `iwctl`, `resolvectl`) and ask before changing state.
- Other hosts are reachable as `ssh <host>.lan` (e.g. `hyllan.lan`, `laptob.lan`,
  `pihole.lan`). Only SSH in when the task concerns that host.
- After the user switches, confirm the change actually landed before
  re-debugging: Home Manager files under `~/.config` are symlinks into the store,
  so `readlink -f` shows the deployed version. Many apps (tmux, workmux, waybar,
  compositors) also need a reload or restart to pick up new config.
- Remember impermanence: new state an app writes (config dirs, caches, databases)
  is lost on reboot unless persisted via the `preservation` module. Check this
  whenever adding an app or debugging "settings don't survive a reboot".

---

## Build / Lint / Format Commands

The primary task runner is `just` (see `justfile`; the user often types `j`).

| Command                              | Description                                                  |
| ------------------------------------ | ------------------------------------------------------------ |
| `just build [host]`                  | Build current or named host config (`nixos-rebuild build`)   |
| `just switch [host]`                 | Apply config to running system (`nixos-rebuild switch`)      |
| `just test [host]`                   | Apply without creating boot entry (`nixos-rebuild test`)     |
| `just boot [host]`                   | Apply on next boot (`nixos-rebuild boot`)                    |
| `just deploy <mode> <host> [target]` | Remote deploy via SSH (`target` defaults to `<host>.lan`)    |
| `just fmt`                           | Format all `.nix` files (`nix fmt`, uses `nixfmt-tree`)      |
| `just iso [type]`                    | Build install or minimal ISO                                 |
| `just build-sd-image <host>`         | Build a Raspberry Pi SD image                                |
| `just up` / `just upp <input>`       | Update all inputs / one input                                |
| `just up-cached`                     | Fetch the `flake.lock` last built by hyllan's nightly cache  |
| `just bump-prev`                     | Pin `nixpkgs-prev` to the currently locked `nixpkgs` rev     |

Typical update flow: `just bump-prev && just up-cached && just build`, then switch
and commit `flake.nix` + `flake.lock` together.

Read-only store lookups (safe to run):

| Command                | Description                                                |
| ---------------------- | ---------------------------------------------------------- |
| `just store-result`    | Resolve `result` symlink to the most recent local build      |
| `just store-rev <input>` | Print the pinned revision of a flake input from `flake.lock` |
| `just nixpkgs-src [input]` | Print the store path of the pinned nixpkgs (or another input) source from `flake.lock` |

These `store-*` / `nixpkgs-src` commands only read state and change nothing. The `build / switch /
test / boot / deploy / iso` commands write to the store and change system state; do
not run them to gather information. Ask the user when you need a host built or
switched.

There is **no test suite** and **no CI**. Correctness is validated by the user
running `just build` / `just test`. The closest thing to CI is the nightly
`nix-cache-build` job on hyllan (`modules/hosts/hyllan/nix-cache.nix`, 03:00): it clones
`main` from the remote, builds the listed hosts into a separate store, serves them
from `http://nix-cache.hyllan.lan` and publishes its `flake.lock`. Uncommitted or
unpushed local changes are not in that build.

---

## Reading nixpkgs source & option definitions (fast)

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

---

## Raspberry Pi Hosts (pihole, pikvm, pidesk)

These are built with `inputs.nixos-raspberrypi.lib.nixosSystem` and evaluate
against nixos-raspberrypi's own (older, stable) nixpkgs. They import the `rpi`
profile (`modules/profiles/rpi.nix`), which is `shell` plus the RPi bits.

- Options that only exist in newer nixpkgs (or in flake inputs these hosts do not
  import) break RPi evaluation, even when unused. Keep that in mind when editing
  aspects that `rpi` imports, directly or as a dependency.
- Kernels come from `nixos-raspberrypi.cachix.org`. If a build starts compiling
  `linux-config-*` / the kernel, the derivation drifted from upstream's cached
  one; check `nixos-raspberrypi`'s transitive `nixpkgs` node in `flake.lock`.

---

## Repository Layout

`flake.nix` only declares inputs; `outputs` is `mkFlake` over `import-tree ./modules`.
Paths containing a `_`-prefixed segment are skipped by import-tree.

```text
modules/
  flake/        flake-parts.nix (systems, config.aspects), lib.nix (flake.lib),
                overlays.nix (flake.overlays + `overlays` aspect), packages.nix
  base/         `base` aspect (sops, disko, preservation module, overlays, nix,
                Home Manager wiring, user, info, persistence options)
  profiles/     bundles of aspects; see "Profiles and Hosts"
  hosts/<host>/ every file adds to flake.modules.nixos.<host>; default.nix also
                defines flake.nixosConfigurations.<host>. hosts/common/ = shared secrets
  shell/        zsh, starship, fzf, eza, atuin, direnv, yazi, scripts, nix-search-tv
  terminals/    kitty, alacritty, ghostty, wezterm, tmux, zellij, herdr
  editors/      neovim, helix, vscode
  dev/          git, devenv, rustup, fhs, lumen, sqlit, podman, docker, virt-manager
  ai/           llm-agents, worktrunk, llama-cpp, ollama, voxtype
  network/      networking, systemd-networking, networkd-vpn, wireguard, tailscale,
                avahi, openssh, checkpoint-vpn
  desktop/      hyprland, gnome, niri, cosmic, addons/, _scripts/
  apps/         firefox, flameshot, swappy
  hardware/     audio, bluetooth, fingerprint, ledger, webcam, yubikey, …
  services/     syncthing, printing, clipperd, restic-backup, rescue
  system/       console, env, fonts, locale, time, zfs, persistence, gpg,
                secure-boot, track-changes, stylix (colour scheme, imported by base)
pkgs/           custom packages, exposed via the `additions` overlay
```

Folders only group files for humans: aspect names are flat, so moving a file
changes nothing.

---

## Code Style

### Formatting

- **2 spaces** for indentation throughout, no tabs.
- Formatter: `nixfmt-tree` (wrapper around `nixfmt`). Run `just fmt` before committing.
- File names: `kebab-case` (e.g. `open-webui.nix`, `backup-status/`).
- Variable names: `camelCase` for local bindings (`cfg`, `gtkCfg`, `emailFrom`).
- NixOS option names: `camelCase` as per upstream convention.

### Aspect Files

One file (or one folder with `default.nix`) per feature, under its category folder.
The aspect name is the feature name, flat and unique repo-wide (`git`, `hyprland`,
`desktop`); the folder is only for organisation. A feature is turned on by
**importing** its aspect, so there is no `enable` option:

```nix
{ inputs, config, ... }:          # flake-parts args: only what the file uses
let
  inherit (config.flake.lib) mkOpt;
  inherit (config.aspects) nixos homeManager;
in
{
  flake.modules.nixos.git =
    { config, lib, pkgs, ... }:   # ordinary NixOS module
    with lib;
    let
      cfg = config.antob.git;
    in
    {
      imports = [ nixos.gpg ];    # dependencies are imports too

      options.antob.git = with types; {
        userEmail = mkOpt str config.antob.user.email "The email to configure git with.";
      };

      config = {
        home-manager.sharedModules = [ homeManager.git ];
        environment.systemPackages = [ pkgs.git ];
      };
    };

  flake.modules.homeManager.git =
    { osConfig, ... }:            # ordinary Home Manager module
    {
      programs.git.settings.user.email = osConfig.antob.git.userEmail;
    };
}
```

- **Import aspects via `config.aspects.<class>.<name>`**, never `config.flake.modules`
  directly: the wrapper gives each aspect a module key, so importing it from a preset,
  a host and a dependency at once evaluates it once.
- **`inputs`, `config.flake.lib` and `config.aspects` come from the outer
  flake-parts closure.** Inner modules get no `specialArgs`; `lib` is stock nixpkgs
  `lib`.
- **Options are settings only** (`antob.<name>.<setting>`, flat, named after the
  aspect). Set them where the aspect is imported.
- **Home Manager halves** read NixOS settings through `osConfig` and are attached
  with `home-manager.sharedModules`. HM is NixOS-integrated only.
- **Multi-file features** (neovim plugins, hyprland) add to the same aspect name
  from several files. Non-module helpers (scripts, data files, callPackage'd `.nix`)
  live in `_files/` next to the aspect, keeping their basenames so store paths stay
  stable.
- **Checking another feature:** use the upstream option it sets
  (`config.programs.zsh.enable`, `osConfig.services.desktopManager.gnome.enable`).
  When there is none, check that its options exist (`config.antob ? networkd-vpn`),
  or import it as a dependency.
- **Colours** come from Stylix (`modules/system/stylix/`, `autoEnable = false`). Read
  them with `osConfig.lib.stylix.colors.base0D` (bare hex) or `.withHashtag`, and opt an
  app into its Stylix target in that app's aspect (`stylix.targets.<app>.enable = true`).
  Older nixpkgs on the RPi hosts may need Stylix modules added to `disabledModules` in
  the `rpi` profile.
- **Ordering:** module order follows import-tree's file order, not intent. When the
  order of merged list/string definitions matters (`initLua`, `initContent`, mime
  defaults), state it with `mkOrder`/`mkBefore` (neovim plugins use `mkOrder 201`..`212`).

### Profiles and Hosts

Profiles (`modules/profiles/*.nix`) are aspects that import other aspects. They
layer, each adding only its delta:

```text
shell        base + core shell aspects, base packages   ← rpi
└── server   + env, console, yazi, gpg, bootloader      ← wiggum
    └── common       + dev tools, fonts, audio, docs    ← hyllan, laptob-qemu
        └── workstation  + desktop, hyprland, VPNs, backups, persistence and
                           the settings shared by the personal machines
                                                        ← desktob, laptob
iso          what both installer ISOs share             ← install-iso, minimal-iso
desktop, laptop (imports desktop), gaming: add-ons
```

Hosts import one profile plus host-specific aspects and keep only per-machine
settings (host ids, addresses, hardware, extras). Put config shared by several
hosts in the lowest profile they all import; nothing opts out of a profile's
import. When only some hosts want a feature, those hosts import it.
Unused host-specific files are standalone aspects named `<host>-<file>`
(`hyllan-plex`, `wiggum-headscale`): import one to enable it.

### Overlays and Multiple nixpkgs Channels

`modules/flake/overlays.nix` exposes alternate channels as top-level attrs on `pkgs`:

```nix
pkgs.stable.<pkg>   # from nixpkgs-stable
pkgs.next.<pkg>     # from nixpkgs-next (newer unstable)
pkgs.prev.<pkg>     # from nixpkgs-prev (pinned previous)
```

### Custom Packages

Packages in `pkgs/` use `pkgs.callPackage` or `pkgs.writeShellScriptBin`. They are
exposed via the `additions` overlay. Use `pkgs.<name>` to reference them from modules.

### Secrets (SOPS)

- Secrets are encrypted YAML files under `modules/hosts/<name>/secrets.yaml` and
  `modules/hosts/common/secrets.yaml`.
- Each host declares `sops.defaultSopsFile` and individual `sops.secrets.<key>` options.
- Access a secret at runtime with `config.sops.secrets.<key>.path`.
- Never hardcode secrets or place plaintext credentials in `.nix` files.

### Error Handling

- Use `lib.optionalString`, `lib.optional`, and `lib.optionals` for conditional lists/strings.
- Use NixOS `assertions` for runtime validation where correctness cannot be enforced by types.
- No explicit `throw` / `abort` unless truly unrecoverable.

---

## Naming Conventions Summary

| Thing                   | Convention   | Example                     |
| ----------------------- | ------------ | --------------------------- |
| File names              | `kebab-case` | `open-webui.nix`            |
| Directory names         | `kebab-case` | `cli-apps/`                 |
| Aspect names            | `kebab-case` | `nix-search-tv`, `hyprland` |
| Local Nix bindings      | `camelCase`  | `cfg`, `gtkCfg`             |
| NixOS options           | `camelCase`  | `hostName`, `storageDriver` |
| Custom option namespace | `antob.*`    | `antob.git.userEmail`       |
| Host names              | `kebab-case` | `laptob`, `desktob`         |

---

## Key Architectural Decisions

- **`antob.*` namespace** all custom options live under `antob`, to prevent conflicts with upstream NixOS options.
- **Dendritic aspects.** Every file is a flake-parts module; features are imported, not enabled. Layered profiles bundle aspects so hosts import one profile instead of every feature.
- **Impermanence.** Root filesystem is ephemeral. Persistent data lives at `antob.persistence.path` (default `/persist`), and the `.safe` subfolder is additionally backed up offsite. Some hosts override the path. System and user state is preserved via the `preservation` module, not written into the ephemeral root.
- **No CI.** The user validates with `just build <host>` locally; hyllan's nightly cache build is the only automated build.
- **Shell scripts as commands.** User-facing scripts live in `modules/shell/scripts/_files/` as Nix-wrapped commands (one file or folder per command, e.g. `backup-status/`), not as loose files in `scripts/`.
