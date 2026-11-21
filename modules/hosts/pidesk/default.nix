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

      imports = with nixos; [
        rpi
        wireguard
        systemd-networking
      ];

      environment.systemPackages = with pkgs; [
        etherwake
        (pkgs.callPackage ../../shell/scripts/_files/wake-desktob.nix {
          keyFile = secrets.desktob_wake_key.path;
        })
      ];

      # Sops secrets
      sops = {
        defaultSopsFile = ./secrets.yaml;
        secrets = {
          wg0_private_key = {
            owner = "systemd-network";
          };
          # Login key for desktob, authorised there only for wake-desktob-guard
          desktob_wake_key = {
            owner = config.antob.user.name;
            mode = "0400";
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
