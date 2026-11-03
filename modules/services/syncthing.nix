{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.syncthing =
    { config, lib, ... }:

    {
      config = {
        home-manager.sharedModules = [ homeManager.syncthing ];

        networking.firewall = {
          allowedTCPPorts = [ 22000 ];
          allowedUDPPorts = [
            21027
            22000
          ];
        };

        antob.persistence.safe.home.directories = [
          ".local/state/syncthing"
        ];
      };
    };

  flake.modules.homeManager.syncthing =
    { lib, pkgs, ... }:
    {
      services.syncthing = {
        enable = true;
        package = pkgs.syncthing;
      };
    };

}
