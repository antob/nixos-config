{ lib, config, ... }:
{
  disko.devices = {
    nodev = lib.mkIf config.antob.persistence.enable {
      "/" = {
        fsType = "tmpfs";
        mountOptions = [
          "defaults"
          "size=25%"
          "mode=755"
        ];
      };
    };
    disk = {
      main = {
        device = lib.mkDefault "/dev/vda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
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

            root = lib.mkIf (!config.antob.persistence.enable) {
              size = "100%";
              label = "root";
              content = {
                # LUKS passphrase will be prompted interactively only
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/";
                };
              };
            };

            nix = lib.mkIf config.antob.persistence.enable {
              size = "100%";
              label = "root";
              content = {
                # LUKS passphrase will be prompted interactively only
                type = "luks";
                name = "cryptroot";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/nix";
                  postMountHook = "mkdir -p /nix/persist";
                };
              };
            };

            encryptedSwap = {
              size = "2G";
              name = "cryptswap";
              content = {
                type = "swap";
                randomEncryption = true;
                priority = 100; # prefer to encrypt as long as we have space for it
              };
            };
          };
        };
      };
    };
  };

  fileSystems = lib.mkIf config.antob.persistence.enable {
    "/nix".neededForBoot = true;
  };
}
