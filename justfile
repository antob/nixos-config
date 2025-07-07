# List all the just commands
default:
  @just --list

# Deploy to laptob
laptob mode="switch":
  nixos-rebuild {{mode}} --flake .#laptob-fw --sudo

# Deploy to hyllan
hyllan mode="switch":
  nixos-rebuild {{mode}} --flake .#hyllan --target-host hyllan.lan --sudo

# Build install ISO
iso:
  nix build .#nixosConfigurations.install-iso.config.system.build.isoImage

# Build minimal install ISO
minimal-iso:
  nix build .#nixosConfigurations.minimal-iso.config.system.build.isoImage

# Update all the flake inputs
up:
  nix flake update

# Update specific input. Usage: `just upp nixpkgs`
upp input:
  nix flake update {{input}}

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
  nix store repair {{paths}}
