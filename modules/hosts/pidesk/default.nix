{ inputs, config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.pidesk =
    {
      lib,
      pkgs,
      config,
      ...
    }:

    with lib;
    let
      inherit (config.sops) secrets;
    in
    {
      antob.systemd-networking = {
        hostName = "pidesk";
        hostId = "b4a80555";
      };

      antob.wireguard = {
        address = "10.64.1.9/24";
        privateKeyFile = secrets.wg0_private_key.path;
      };

      imports = [
        nixos.rpi
        nixos.wireguard
        nixos.systemd-networking
        nixos.base
      ];

      environment.systemPackages = with pkgs; [
        etherwake
        (pkgs.callPackage ../../tools/scripts/_files/wake-desktob.nix { })
      ];

      # Sops secrets
      sops = {
        defaultSopsFile = ./secrets.yaml;
        secrets = {
          wg0_private_key = {
            owner = "systemd-network";
          };
        };
      };

      system.stateVersion = "21.11";
    };

  flake.nixosConfigurations.pidesk = inputs.nixos-raspberrypi.lib.nixosSystem {
    system = "aarch64-linux";
    modules = [ nixos.pidesk ];
  };
}
