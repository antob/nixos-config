{
  lib,
  ...
}:

with lib;
with lib.antob;
{
  imports = [ ./hardware.nix ];

  antob = {
    features = {
      common = enabled;
      desktop = enabled;
    };

    desktop.xfce-xmonad.enable = true;

    apps = {
      flameshot = enabled;
    };

    hardware = {
      bluetooth = enabled;
      zsa-voyager = enabled;
      yubikey = enabled;
    };

    desktop.xfce-xmonad.mainDisplay = "DP-4";
  };

  services = {
    fstrim.enable = lib.mkDefault true;
  };

  system.stateVersion = "22.11";
}
