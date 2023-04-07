{ options, config, lib, pkgs, ... }:

with lib;
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

    antob.persistence.home.directories = [ ".local/share/direnv" ];
  };
}
