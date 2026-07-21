{
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;
{
  imports = with inputs; [
    nur.modules.nixos.default
    ./hardware.nix
    ../../modules
  ];

  antob = {
    features = {
      common = enabled;
      desktop = enabled;
    };

    desktop.gnome = enabled;

    # persistence = enabled;

    virtualisation.docker.enable = false;
  };

  environment.systemPackages = with pkgs; [
    nfs-utils # Needed for mounting NFS shares
  ];

  services.tlp.enable = false;

  system.stateVersion = "22.11";
}
