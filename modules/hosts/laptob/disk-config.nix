{ config, ... }:
{
  flake.modules.nixos.laptob = {
    imports = [ config.aspects.nixos.btrfs-luks-disk ];

    antob.btrfs-luks-disk = {
      device = "/dev/disk/by-id/nvme-eui.e8238fa6bf530001001b448b42f9e49e";
      # If the swapfile size changes, resume_offset in hardware.nix must be recalculated.
      swapSize = "64G";
      hibernation = true;
    };
  };
}
