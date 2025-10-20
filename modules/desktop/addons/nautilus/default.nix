{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.nautilus;
in
{
  options.antob.desktop.addons.nautilus = with types; {
    enable = mkEnableOption "Whether to enable Nautilus.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.nautilus
    ];

    antob.persistence.home.directories = [
      ".config/nautilus"
      ".local/state/nautilus"
    ];
  };
}
