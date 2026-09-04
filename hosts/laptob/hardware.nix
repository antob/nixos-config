{
  lib,
  pkgs,
  modulesPath,
  inputs,
  ...
}:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    inputs.nixos-hardware.nixosModules.framework-intel-core-ultra-series3
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

    kernelModules = [ "kvm-intel" ];

    # Enable emulated systems for cross-compilation
    binfmt.emulatedSystems = [ "aarch64-linux" ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  hardware.intelgpu = {
    vaapiDriver = "intel-media-driver";
    driver = "xe";
  };

  hardware.cpu.intel.npu.enable = true;
  hardware.enableRedistributableFirmware = true;
}
