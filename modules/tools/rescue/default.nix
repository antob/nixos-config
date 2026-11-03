{ config, ... }:
let
  inherit (config.flake.lib) mkOpt hyllanBackupsBaseRepo;
in
{
  flake.modules.nixos.rescue =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    let
      cfg = config.antob.rescue;
      cp = pkgs.callPackage;
    in
    {
      options.antob.rescue = with types; {
        resticEnvFile =
          mkOpt (nullOr path) null
            "Path to the SOPS-decrypted restic credentials file (password plus S3 keys).";
      };

      config = mkMerge [
        ({
          environment.systemPackages = [
            (cp ./_files/vaultwarden-local.nix { })
          ];
        })
        (mkIf (cfg.resticEnvFile != null) {
          environment.systemPackages = [
            (cp ./_files/restic-vaultwarden.nix {
              baseRepo = hyllanBackupsBaseRepo;
              envFile = cfg.resticEnvFile;
            })
          ];
        })
      ];
    };

}
