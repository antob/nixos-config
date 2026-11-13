{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.lumen =
    { pkgs, ... }:
    {
      config = {
        home-manager.sharedModules = [ homeManager.lumen ];

        environment.systemPackages = with pkgs; [
          lumen
          mdcat
        ];

      };
    };

  flake.modules.homeManager.lumen =
    { lib, ... }:
    {
      xdg.configFile."lumen/lumen.config.json".text = /* json */ ''
        {
          "theme": "one-dark",
          "provider": "openrouter"
        }
      '';
    };

}
