{ inputs, config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.lumen =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      inherit (pkgs.stdenv.hostPlatform) system;
    in
    {
      config = {
        home-manager.sharedModules = [ homeManager.lumen ];

        environment.systemPackages = with pkgs; [
          inputs.lumen.packages.${system}.lumen
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
