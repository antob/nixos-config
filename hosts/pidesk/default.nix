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
  imports = [
    ./hardware.nix
  ];

  antob = {
    features.rpi = enabled;
    hardware.systemd-networking = {
      enable = true;
      hostName = "pidesk";
      enableVpn = false;
      hostId = "c99ced58";
    };
    services.wireguard = {
      enable = true;
      address = "10.64.1.9/24";
      privateKeyFile = secrets.wg0_private_key.path;
    };
  };

  environment.systemPackages = with pkgs; [
    etherwake
    (pkgs.callPackage ../../modules/tools/scripts/wake-desktob.nix { })
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
}
