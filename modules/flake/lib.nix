{ lib, ... }:
{
  flake.lib = rec {
    mkOpt =
      type: default: description:
      lib.mkOption { inherit type default description; };

    mkOpt' = type: default: mkOpt type default null;

    mkBoolOpt = mkOpt lib.types.bool;

    mkBoolOpt' = mkOpt' lib.types.bool;

    enabled = {
      enable = true;
    };

    disabled = {
      enable = false;
    };

    # Stylix colour halfway between two base16 slots, e.g. `mixColors colors "base04" "base05"`.
    mixColors =
      colors: a: b:
      let
        channel =
          ch:
          let
            avg = (lib.toInt colors."${a}-rgb-${ch}" + lib.toInt colors."${b}-rgb-${ch}") / 2;
          in
          lib.fixedWidthString 2 "0" (lib.toHexString avg);
      in
      "#"
      + lib.concatMapStrings channel [
        "r"
        "g"
        "b"
      ];

    # Base S3 repository for the hyllan offsite restic backups
    hyllanBackupsBaseRepo = "s3:hel1.your-objectstorage.com/antob-hyllan-backups";
  };
}
