{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.mcfly;
in
{
  options.antob.tools.mcfly = with types; {
    enable = mkEnableOption "Whether or not to install and configure McFly.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.mcfly = {
        enable = true;
        enableZshIntegration = true;
        fuzzySearchFactor = 3;
        keyScheme = "vim";
      };

      home.packages = [ pkgs.mcfly-fzf ];
      programs.zsh.initContent = ''
        eval "$(${getExe pkgs.mcfly-fzf} init zsh)"
      '';
    };

    antob.persistence.home.files = [ ".local/share/mcfly/history.db" ];
  };
}
