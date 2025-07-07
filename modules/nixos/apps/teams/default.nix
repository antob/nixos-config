{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.apps.teams;
in
{
  options.antob.apps.teams = with types; {
    enable = mkEnableOption "Enable Teams";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ teams ];
    antob.persistence.home.directories = [
      ".config/Microsoft/Microsoft Teams"
      ".config/Microsoft Teams - Preview"
    ];
  };
}
