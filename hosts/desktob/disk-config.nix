{ lib, config, ... }:
with lib;
let
  impermanence = config.antob.persistence.enable;
  phase1Systemd = config.boot.initrd.systemd.enable;
  wipeScript = ''
    mkdir /tmp -p
    MNTPOINT=$(mktemp -d)
    (
      mount -t btrfs -o subvol=/ /dev/mapper/system "$MNTPOINT"
      trap 'umount "$MNTPOINT"' EXIT

      echo "Cleaning root subvolume"
      btrfs subvolume list -o "$MNTPOINT/@root" | cut -f9 -d ' ' | while read -r subvolume; do
        echo "Deleting $subvolume subvolume..."
        btrfs subvolume delete "$MNTPOINT/$subvolume"
      done && btrfs subvolume delete "$MNTPOINT/@root"

      echo "Restoring blank subvolume"
      btrfs subvolume snapshot "$MNTPOINT/@root-blank" "$MNTPOINT/@root"
    )
  '';
in
{
  disko.devices = {
    disk = {
      main = {
        device = mkDefault "/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b4d281d97";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              size = "1G";
              type = "EF00";
              label = "EFI";
              content = {
                type = "filesystem";
                format = "vfat";
                mountOptions = [
                  "defaults"
                  "umask=0077"
                ];
                mountpoint = "/efi";
              };
            };

            cryptsystem = {
              size = "100%";
              content = {
                type = "luks";
                name = "system";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "btrfs";
                  extraArgs = [
                    "-f" # Override existing partition
                    "-L system"
                  ];
                  # Snapshot of empty root. Used for impemnanence rollback on boot.
                  postCreateHook = mkIf impermanence ''
                    MNTPOINT=$(mktemp -d)
                    mount "/dev/mapper/system" "$MNTPOINT" -o subvol=/
                    trap 'umount $MNTPOINT; rm -rf $MNTPOINT' EXIT
                    btrfs subvolume snapshot -r $MNTPOINT/@root $MNTPOINT/@root-blank
                  '';
                  # Subvolumes must set a mountpoint in order to be mounted,
                  # unless their parent is mounted
                  subvolumes = {
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@persist" = mkIf impermanence {
                      mountpoint = "/persist";
                      mountOptions = [
                        "compress=zstd"
                        "noatime"
                      ];
                    };
                    "@swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "12G";
                      mountOptions = [ "noatime" ];
                    };
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  fileSystems = mkIf impermanence {
    "/nix".neededForBoot = true;
    "/persist".neededForBoot = true;
  };

  boot.initrd = mkIf impermanence {
    supportedFilesystems = [ "btrfs" ];
    postDeviceCommands = mkIf (!phase1Systemd) (mkBefore wipeScript);
    systemd.services.restore-root = mkIf phase1Systemd {
      description = "Rollback btrfs rootfs";
      wantedBy = [ "initrd.target" ];
      requires = [
        "dev-disk-by\\x2dlabel-system.device"
      ];
      after = [
        "dev-disk-by\\x2dlabel-system.device"
        "systemd-cryptsetup@system.service"
      ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = wipeScript;
    };
  };
}
