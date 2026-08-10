{
  lib,
  ...
}:

with lib;
{
  imports = [
    ./hardware.nix
  ];

  antob = {
    features.rpi = enabled;
    hardware = {
      systemd-networking = {
        enable = true;
        hostName = "pikvm";
        # Derived from `head -c 8 /etc/machine-id`
        hostId = "7a5a15e8";
        enableVpn = false;
      };
    };
  };

  system.stateVersion = "21.11";
}
