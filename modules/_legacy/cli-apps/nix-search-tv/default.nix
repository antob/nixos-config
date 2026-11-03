{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.nix-search-tv;
in
{
  options.antob.cli-apps.nix-search-tv = with types; {
    enable = mkBoolOpt false "Whether or not to enable nix-search-tv.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.nix-search-tv = {
        enable = true;
      };
    };

    environment.shellAliases.ns = mkIf config.antob.tools.fzf.enable "nix-search-tv print | fzf --tmux 100% --preview 'nix-search-tv preview {}' --scheme history";

    antob.persistence.home.directories = [ ".cache/nix-search-tv" ];
  };
}
