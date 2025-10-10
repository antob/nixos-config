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
          "size=16G"
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
              size = "100%";
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

            encryptedSwap = {
              size = "130G";
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
