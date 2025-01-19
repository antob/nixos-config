{
  pkgs,
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
      fingerprint = enabled;
      bluetooth = enabled;
    };
  };

  environment.systemPackages = with pkgs; [
    powertop
  ];

  services = {
    fwupd.enable = true;
    logind = {
      lidSwitch = "suspend-then-hibernate";
      lidSwitchExternalPower = "suspend";
    };
  };

  system.stateVersion = "22.11";
}
