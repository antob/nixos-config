{ config, ... }:
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
      secrets = config.sops.secrets;
    in
    {
      antob.wireguard = {
        address = "10.64.1.9/24";
        privateKeyFile = secrets.wg0_private_key.path;
      };

      imports = [
        nixos.rpi
        nixos.wireguard
      ];

      antob = {

        hardware.systemd-networking = {
          enable = true;
          hostName = "pidesk";
          enableVpn = false;
          hostId = "b4a80555";
        };
      };

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
}
