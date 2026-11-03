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

    # Base S3 repository for the hyllan offsite restic backups
    hyllanBackupsBaseRepo = "s3:hel1.your-objectstorage.com/antob-hyllan-backups";
  };
}
