{ pkgs, config, lib, channel, inputs, ... }:

with lib;
with lib.antob;
{
  imports = with inputs; [
    ./hardware.nix
    auto-cpufreq.nixosModules.default
  ];

  antob = {
    features = {
      common = enabled;
      desktop = enabled;
    };

    desktop.hyprland = enabled;

    virtualisation.virt-manager = enabled;

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
    amdgpu_top
    radeontop
    glxinfo
    deploy-rs
    sops
  ];

  services = {
    fwupd.enable = true;

    logind = {
      lidSwitch = "suspend-then-hibernate";
      lidSwitchExternalPower = "suspend";
    };

    chrony.enable = true;
  };

  # Power optimizer daemons. Choose one.
  programs.auto-cpufreq.enable = false;
  services.power-profiles-daemon.enable = true;
  services.tlp.enable = false;

  system.stateVersion = "22.11";
}
