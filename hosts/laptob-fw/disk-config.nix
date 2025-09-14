{ lib, config, ... }:
let
  impermanence = config.antob.persistence.enable;
in
{
  disko.devices = {
    nodev = lib.mkIf impermanence {
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
        device = lib.mkDefault "/dev/nvme0n1";
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

            nix = {
              priority = 2;
              size = "1000G";
              label = "nix";
              content = {
                # LUKS passphrase will be prompted interactively only
                type = "luks";
                name = "cryptnix";
                settings = {
                  allowDiscards = true;
                };
                content = {
                  type = "filesystem";
                  format = "ext4";
                  mountpoint = "/nix";
                };
              };
            };

            root = lib.mkIf (!impermanence) {
              priority = 3;
              size = "500G";
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

            encryptedSwap = {
              size = "70G";
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

  fileSystems = lib.mkIf impermanence {
    "/nix".neededForBoot = true;
  };
}
