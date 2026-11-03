{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.tools.rescue;
  cp = pkgs.callPackage;
in
{
  options.antob.tools.rescue = with types; {
    enable = mkEnableOption "Whether or not to install backup rescue tools.";
    resticEnvFile =
      mkOpt (nullOr path) null
        "Path to the SOPS-decrypted restic credentials file (password plus S3 keys).";
  };

  config = mkMerge [
    (mkIf cfg.enable {
      environment.systemPackages = [
        (cp ./vaultwarden-local.nix { })
      ];
    })
    (mkIf (cfg.enable && cfg.resticEnvFile != null) {
      environment.systemPackages = [
        (cp ./restic-vaultwarden.nix {
          inherit lib;
          envFile = cfg.resticEnvFile;
        })
      ];
    })
  ];
}
