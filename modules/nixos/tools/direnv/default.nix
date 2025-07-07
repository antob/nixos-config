{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.direnv;
in
{
  options.antob.tools.direnv = with types; {
    enable = mkBoolOpt false "Whether or not to enable direnv.";
  };

  config = mkIf cfg.enable {

    programs.direnv = {
      enable = true;
      silent = true;
      nix-direnv.enable = true;
      loadInNixShell = true;
      enableZshIntegration = true;
    };

    nix.extraOptions = ''
      keep-outputs = true
      keep-derivations = true
    '';

    antob.persistence.home.directories = [ ".local/share/direnv" ];
  };
}
