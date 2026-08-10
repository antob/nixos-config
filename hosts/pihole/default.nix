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
        hostName = "pihole";
        # Derived from `head -c 8 /etc/machine-id`
        hostId = "11111111";
        enableVpn = false;
      };
    };
  };

  system.stateVersion = "21.11";
}
