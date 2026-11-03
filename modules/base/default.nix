{ inputs, config, ... }:
{
  flake.modules.nixos.base = {
    imports = [
      inputs.sops-nix.nixosModules.sops
      inputs.disko.nixosModules.disko
      inputs.preservation.nixosModules.preservation
      config.flake.modules.nixos.overlays
    ];
  };
}
