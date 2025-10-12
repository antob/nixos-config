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

  # Bootloader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      consoleMode = "max";
      configurationLimit = 5;
      editor = false;
    };

    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
  };

  system.stateVersion = "22.11";
}
