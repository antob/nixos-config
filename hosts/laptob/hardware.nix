{
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:

{
  imports = with inputs.nixos-hardware.nixosModules; [
    (modulesPath + "/installer/scan/not-detected.nix")
    framework-intel-core-ultra-series3
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
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  powerManagement = {
    cpuFreqGovernor = lib.mkDefault "powersave";
    powertop.enable = true;
  };

  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  # Enable DHCP on the wireless link
  networking.useDHCP = lib.mkDefault true;
}
