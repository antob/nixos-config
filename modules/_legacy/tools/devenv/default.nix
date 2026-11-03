{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.tools.devenv;
in
{
  options.antob.tools.devenv = with types; {
    enable = mkBoolOpt false "Whether or not to enable devenv.";
  };

  config = mkIf cfg.enable {
    nix.settings = {
      keep-outputs = true;
      keep-derivations = true;
    };

    antob = {
      # home.extraOptions.programs.zsh.initContent = ''
      #   eval "$(${getExe pkgs.devenv} hook zsh)"
      # '';

      persistence.home.directories = [
        ".local/share/devenv"
      ];
    };

    environment.systemPackages = with pkgs; [
      cachix
      devenv
    ];
  };
}
