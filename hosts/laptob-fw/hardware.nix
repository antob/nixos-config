{
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:

let
  inherit (inputs) nixos-hardware;
in
{
  imports = with nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    framework-13-7040-amd
    ./disk-config.nix
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    supportedFilesystems = [
      "nfs"
      "nfs4"
    ];

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  powerManagement = {
    cpuFreqGovernor = lib.mkDefault "powersave";
    powertop.enable = true;
  };

  hardware.enableRedistributableFirmware = true;

  # As of firmware v03.03, a bug in the EC causes the system to wake if AC is connected despite the lid being closed.
  # The following works around this, with the trade-off that keyboard presses also no longer wake the system.
  # See https://community.frame.work/t/tracking-framework-amd-ryzen-7040-series-lid-wakeup-behavior-feedback/39128/54
  hardware.framework.amd-7040.preventWakeOnAC = true;

  # high-resolution display
  #hardware.video.hidpi.enable = true;

  hardware.graphics.enable = true;

  # Enable DHCP on the wireless link
  networking = {
    useDHCP = lib.mkDefault true;
    # networking.interfaces.enp193s0f3u1c2.useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;
  };
}
