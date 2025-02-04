{
  config,
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
    lenovo-thinkpad-x1-9th-gen
  ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    initrd = {
      availableKernelModules = [
        "xhci_pci"
        "thunderbolt"
        "nvme"
        "usb_storage"
        "sd_mod"
      ];
      kernelModules = [ ];
      luks.devices."system".device = "/dev/disk/by-partlabel/cryptsystem";
    };

    kernelModules = [ "kvm-intel" ];
    extraModulePackages = [ ];
    kernelParams = [
      "mem_sleep_default=deep"
      "resume_offset=533760" # Value from `btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile`
    ];
    resumeDevice = "/dev/mapper/system";
  };

  fileSystems = lib.mkMerge [
    {
      "/" = lib.mkDefault {
        device = "/dev/mapper/system";
        fsType = "btrfs";
        options = [
          "subvol=@root"
          "compress=zstd"
        ];
      };

      "/home" = lib.mkIf (!config.antob.persistence.enable) {
        device = "/dev/mapper/system";
        fsType = "btrfs";
        options = [
          "subvol=@home"
          "compress=zstd"
        ];
      };

      "/nix" = {
        device = "/dev/mapper/system";
        fsType = "btrfs";
        options = [
          "subvol=@nix"
          "compress=zstd"
          "noatime"
        ];
      };

      "/persist" = lib.mkIf config.antob.persistence.enable {
        device = "/dev/mapper/system";
        fsType = "btrfs";
        options = [
          "subvol=@persist"
          "compress=zstd"
        ];
        neededForBoot = true;
      };

      "/swap" = {
        device = "/dev/mapper/system";
        fsType = "btrfs";
        options = [
          "subvol=@swap"
          "compress=none"
          "noatime"
        ];
      };

      "/efi" = {
        device = "/dev/disk/by-partlabel/EFI";
        fsType = "vfat";
        options = [
          "dmask=0077"
          "fmask=0077"
        ];
        neededForBoot = true;
      };
    }
    (lib.mkIf (config.antob.persistence.enable) {
      "/" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=2G"
          "mode=755"
        ];
      };

      "/home/${config.antob.user.name}" = {
        device = "none";
        fsType = "tmpfs";
        options = [
          "defaults"
          "size=1G"
          "mode=777"
        ];
      };
    })
  ];

  swapDevices = [ { device = "/swap/swapfile"; } ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  hardware.enableRedistributableFirmware = true;
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  # high-resolution display
  #hardware.video.hidpi.enable = true;

  hardware.graphics.enable = true;

  # Enable DHCP on the wireless link
  networking = {
    # Derived from `head -c 8 /etc/machine-id`
    hostId = "67fedb6a";

    useDHCP = lib.mkDefault true;
    # networking.interfaces.enp82s0u2u4.useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp0s20f3.useDHCP = lib.mkDefault true;
  };
}
