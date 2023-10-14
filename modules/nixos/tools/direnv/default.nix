{ options, config, lib, pkgs, ... }:

with lib;
with lib.antob;
let cfg = config.antob.tools.direnv;
in
{
  options.antob.tools.direnv = with types; {
    enable = mkBoolOpt false "Whether or not to enable direnv.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv = enabled;
      };
    };

    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    # make `direnv` silent
    antob.system.env = {
      DIRENV_LOG_FORMAT = "";
    };

    antob.persistence.home.directories = [ ".local/share/direnv" ];
  };
}
