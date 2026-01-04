{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.services.syncthing;
in
{
  options.antob.services.syncthing = with types; {
    enable = mkEnableOption "Whether or not to enable Syncthing.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      services.syncthing = {
        enable = true;
        package = pkgs.syncthing;
      };
    };

    networking.firewall = {
      allowedTCPPorts = [ 22000 ];
      allowedUDPPorts = [
        21027
        22000
      ];
    };

    antob.persistence.home.directories = [
      ".config/syncthing"
      ".local/share/syncthing"
      ".local/state/syncthing"
    ];
  };
}
