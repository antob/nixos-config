{ config, ... }:
let
  inherit (config.aspects) nixos homeManager;
in
{
  flake.modules.nixos.nix-search-tv =
    {
      config,
      lib,
      ...
    }:

    with lib;
    {
      imports = [ nixos.fzf ];

      config = {
        home-manager.sharedModules = [ homeManager.nix-search-tv ];

        environment.shellAliases.ns = "nix-search-tv print | fzf --tmux 100% --preview 'nix-search-tv preview {}' --scheme history";

        antob.persistence.home.directories = [ ".cache/nix-search-tv" ];
      };
    };

  flake.modules.homeManager.nix-search-tv =
    { lib, ... }:
    with lib;
    {
      programs.nix-search-tv = {
        enable = true;
      };
    };

}
