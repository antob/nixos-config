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
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      (cp ./vaultwarden-local.nix { })
    ];
  };
}
