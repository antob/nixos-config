{ channels, ... }:

final: prev:

{
  inherit (channels.unstable) btrfs-progs;
}
