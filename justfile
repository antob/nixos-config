# List all the just commands
default:
    @just --list

###################################
# Various `nixos-rebuild` commands
###################################

# Build flake
build flake="": (_nixos-rebuild "build" flake)

# Switch flake
switch flake="": (_nixos-rebuild "switch" flake)

# Boot flake
boot flake="": (_nixos-rebuild "boot" flake)

# Test flake
test flake="": (_nixos-rebuild "test" flake)

# Deploy flake to remote host
deploy flake host mode="switch": (_nixos-rebuild mode flake host)

###################################
# Various install commands
###################################

# Build install ISO
iso type="install":
    nix build .#nixosConfigurations.{{ type }}-iso.config.system.build.isoImage

# Install flake to remote host
install host flake *ARGS:
    nixos-anywhere --flake .#{{ flake }} {{ host }} {{ ARGS }}

###################################
# Various flake commands
###################################

# Lock nixpkgs-prev to locked rev of current system
bump-prev:
    sed -i "s/\(^[ \t]*nixpkgs-prev.url .*\/nixpkgs\/\).*\";$/\1`jq -r '.nodes.nixpkgs.locked.rev' flake.lock`\";/" flake.nix

# Update all the flake inputs
up:
    nix flake update

# Update specific input. Usage: `just upp nixpkgs`
upp input:
    nix flake update {{ input }}

# Update all Nixpkgs inputs
up-nix:
    nix flake update nixpkgs nixpkgs-stable

# Format the nix files in this repo
fmt:
    nix fmt

# List all generations of the system profile
history:
    nix profile history --profile /nix/var/nix/profiles/system

# Open a nix shell with the flake
repl:
    nix repl -f flake:nixpkgs

# Remove all generations older than 7 days
clean:
    # Wipe out NixOS's history
    sudo nix profile wipe-history --profile /nix/var/nix/profiles/system  --older-than 7d
    # Wipe out home-manager's history
    nix profile wipe-history --profile $"($env.XDG_STATE_HOME)/nix/profiles/home-manager" --older-than 7d

# Garbage collect all unused nix store entries
gc:
    # garbage collect all unused nix store entries(system-wide)
    sudo nix-collect-garbage --delete-older-than 7d
    # garbage collect all unused nix store entries(for the user - home-manager)
    # https://github.com/NixOS/nix/issues/8508
    nix-collect-garbage --delete-older-than 7d

# Show all the auto gc roots in the nix store
gcroot:
    ls -al /nix/var/nix/gcroots/auto/

# Verify all the store entries
# Nix Store can contains corrupted entries if the nix store object has been modified unexpectedly.
# This command will verify all the store entries,

# and we need to fix the corrupted entries manually via `sudo nix store delete <store-path-1> <store-path-2> ...`
verify-store:
    nix store verify --all

# Repair Nix Store Objects
repair-store *paths:
    nix store repair {{ paths }}

###################################
# Internal recipes
###################################

# generic nixos-rebuild
_nixos-rebuild mode flake="" host="":
    nixos-rebuild {{ mode }} --flake .#{{ if flake == "" { `hostname` } else { flake } }} --sudo {{ if host == "" { "" } else { "--target-host " + host } }}
