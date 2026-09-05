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

    # Hibernation: resume from the swapfile on /.swapvol
    # The offset must match the physical start of the swapfile, recalculate with:
    #   sudo btrfs inspect-internal map-swapfile -r /.swapvol/swapfile
    resumeDevice = "/dev/mapper/system";
    kernelParams = [ "resume_offset=60630272" ];

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
