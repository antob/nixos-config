{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
with lib;
let
  cfg = config.antob.cli-apps.lumen;
  system = pkgs.stdenv.hostPlatform.system;
in
{
  options.antob.cli-apps.lumen = {
    enable = mkEnableOption "Whether or not to enable Lumen.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      inputs.lumen.packages.${system}.lumen
      mdcat
    ];

    antob.home.extraOptions = {
      xdg.configFile."lumen/lumen.config.json".text = /* json */ ''
        {
          "theme": "one-dark",
          "provider": "openrouter"
        }
      '';
    };
  };
}
