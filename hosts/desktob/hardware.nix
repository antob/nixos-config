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
    framework-desktop-amd-ai-max-300-series
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
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usbhid"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
    };

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    kernelParams = [
      "nohibernate"
      # Increasing the VRAM allocation on AMD AI APUs
      # Calculation: `([size in GB] * 1024 * 1024 * 1024) / 4.096`
      "ttm.pages_limit=27648000" # 108 GB
      "ttm.page_pool_size=27648000" # 108 GB
      "amd_iommu=off" # Disables IOMMU for lower latency
      "btusb.enable_autosuspend=0" # Prevent BT mouse sleep
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = true;

  hardware.graphics.enable = true;
}
