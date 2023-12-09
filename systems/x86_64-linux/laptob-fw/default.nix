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

    desktop.hyprland = enabled;

    hardware = {
      fingerprint = enabled;
      bluetooth = enabled;
      zsa-voyager = enabled;
      yubikey = enabled;
    };
  };

  antob.system.console.setFont = mkForce false;

  environment.systemPackages = with pkgs; [
    powertop
    vulkan-tools
  ];

  services = {
    fwupd.enable = true;

    logind = {
      lidSwitch = "suspend-then-hibernate";
      lidSwitchExternalPower = "suspend";
    };

    chrony.enable = true;
  };

  system.stateVersion = "22.11";
}
