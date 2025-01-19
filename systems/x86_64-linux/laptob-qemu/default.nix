{
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;
with lib.antob;
{
  imports = with inputs; [
    disko.nixosModules.disko
    ./hardware.nix
  ];

  antob = {
    features = {
      common = enabled;
      desktop = enabled;
    };

    desktop.gnome = enabled;

    virtualisation.virt-manager.enable = false;
    virtualisation.docker.enable = false;

    system.console.setFont = mkForce false;
  };

  environment.systemPackages = with pkgs; [
    nfs-utils # Needed for mounting NFS shares
  ];

  services = {
    fwupd.enable = true;
    chrony.enable = true;
  };

  services.tlp.enable = false;

  system.stateVersion = "22.11";
}
