{ pkgs, config, lib, channel, inputs, ... }:

with lib;
with lib.antob;
{
  imports = [ ./hardware.nix ];

  # Temp fix for:
  # https://github.com/gytis-ivaskevicius/flake-utils-plus/issues/145
  nix.package = pkgs.nixVersions.latest;

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
    xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
  };

  system.stateVersion = "22.11";
}
