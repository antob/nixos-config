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
    kernelParams = [
      "resume_offset=60630272"
      # Fixes suspend-then-hibernate.
      "rtc_cmos.use_acpi_alarm=1"
    ];

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

  # UCSI driver on this Framework holds a phantom USB-C power source after
  # unplug, fooling systemd's AC detection. Reload the driver after each
  # resume so suspend-then-hibernate actually hibernates on schedule.
  antob.hardware.ucsi-reset.enable = true;

  hardware.intelgpu = {
    vaapiDriver = "intel-media-driver";
    driver = "xe";
  };

  hardware.cpu.intel.npu.enable = true;
  hardware.enableRedistributableFirmware = true;
}
