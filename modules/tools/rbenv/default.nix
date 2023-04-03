{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.antob.tools.rbenv;
in {
  options.antob.tools.rbenv = with types; {
    enable = mkEnableOption "Whether or not to install and configure rbenv.";
  };

  config = mkIf cfg.enable {
    environment.sessionVariables = { RBENV_HOME = "$XDG_DATA_HOME/rbenv"; };
    antob.persistence.home.directories = [ ".local/share/rbenv" ];

    antob.home.extraOptions = {
      programs.rbenv = {
        enable = true;
        enableZshIntegration = true;
        plugins = [{
          name = "ruby-build";
          src = pkgs.fetchFromGitHub {
            owner = "rbenv";
            repo = "ruby-build";
            rev = "latest";
            hash = "sha256-Kuq0Z1kh2mvq7rHEgwVG9XwzR5ZUtU/h8SQ7W4/mBU0=";
          };
        }];
      };
    };
  };
}
