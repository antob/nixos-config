{ config, lib, pkgs, modulesPath, inputs, ... }:

let inherit (inputs) nixos-hardware;
in {
  imports = with nixos-hardware.nixosModules;
    [
      (modulesPath + "/installer/scan/not-detected.nix")
      framework-13-7040-amd
    ];

  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    initrd = {
      availableKernelModules =
        [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "sd_mod" ];
      kernelModules = [ ];
      luks.devices."system".device = "/dev/disk/by-partlabel/cryptsystem";
    };

    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
    kernelParams = [
      "resume_offset=533760" # Value from `btrfs inspect-internal map-swapfile -r /mnt/swap/swapfile`
    ];
    resumeDevice = "/dev/mapper/system";
  };

  fileSystems = lib.mkMerge [
    {
      "/" = lib.mkDefault {
        device = "/dev/mapper/system";
        fsType = "btrfs";
        options = [ "subvol=@root" "compress=zstd" ];
      };

      "/home" = lib.mkIf (!config.antob.persistence.enable) {
        device = "/dev/mapper/system";
        fsType = "btrfs";
        options = [ "subvol=@home" "compress=zstd" ];
        neededForBoot = true;
      };

      "/nix" = {
        device = "/dev/mapper/system";
        fsType = "btrfs";
        options = [ "subvol=@nix" "compress=zstd" "noatime" ];
      };

      "/persist" = lib.mkIf config.antob.persistence.enable {
        device = "/dev/mapper/system";
        fsType = "btrfs";
        options = [ "subvol=@persist" "compress=zstd" ];
        neededForBoot = true;
      };

      "/swap" = {
        device = "/dev/mapper/system";
        fsType = "btrfs";
        options = [ "subvol=@swap" "compress=none" "noatime" ];
      };

      "/efi" = {
        device = "/dev/disk/by-partlabel/EFI";
        fsType = "vfat";
        options = [ "dmask=0077" "fmask=0077" ];
        neededForBoot = true;
      };
    }
    (lib.mkIf (config.antob.persistence.enable) {
      "/" = {
        device = "none";
        fsType = "tmpfs";
        options = [ "defaults" "size=2G" "mode=755" ];
      };

      "/home/${config.antob.user.name}" = {
        device = "none";
        fsType = "tmpfs";
        options = [ "defaults" "size=1G" "mode=777" ];
      };
    })
  ];

  swapDevices = [{ device = "/swap/swapfile"; }];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";

  hardware.enableRedistributableFirmware = true;

  # As of firmware v03.03, a bug in the EC causes the system to wake if AC is connected despite the lid being closed.
  # The following works around this, with the trade-off that keyboard presses also no longer wake the system.
  # See https://community.frame.work/t/tracking-framework-amd-ryzen-7040-series-lid-wakeup-behavior-feedback/39128/54
  hardware.framework.amd-7040.preventWakeOnAC = true;

  # high-resolution display
  #hardware.video.hidpi.enable = true;

  hardware.opengl = {
    enable = true;
    driSupport = true;
  };

  # Enable DHCP on the wireless link
  networking = {
    # Derived from `head -c 8 /etc/machine-id`
    hostId = "6278643e";

    useDHCP = lib.mkDefault true;
    # networking.interfaces.enp193s0f3u1c2.useDHCP = lib.mkDefault true;
    # networking.interfaces.wlp1s0.useDHCP = lib.mkDefault true;
  };
}
