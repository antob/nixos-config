{ config, ... }:
{
  flake.modules.nixos.desktob = {
    imports = [ config.aspects.nixos.btrfs-luks-disk ];

    antob.btrfs-luks-disk = {
      device = "/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b4d281d97";
      swapSize = "12G";
    };
  };
}
