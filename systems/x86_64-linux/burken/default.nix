{ pkgs, config, lib, channel, inputs, ... }:

with lib;
with lib.antob;
{
  imports = [ ./hardware.nix ];

  antob = {
    features = {
      common = enabled;
      desktop = enabled;
    };

    hardware.bluetooth = enabled;
    hardware.zsa-voyager = enabled;
    desktop.xfce-xmonad.mainDisplay = "DP-4";
  };

  services = {
    fstrim.enable = lib.mkDefault true;
    xserver.videoDrivers = lib.mkDefault [ "nvidia" ];
  };

  system.stateVersion = "22.11";
}
