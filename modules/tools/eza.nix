{ config, ... }:
let
  inherit (config.flake.modules) homeManager;
in
{
  flake.modules.nixos.eza = {
    home-manager.sharedModules = [ homeManager.eza ];
  };

  flake.modules.homeManager.eza =
    { pkgs, ... }:
    {
      home.shellAliases =
        let
          treeIgnore = "'cache|log|logs|node_modules|vendor|.git'";
        in
        {
          ".." = "cd ..";
          ls = "${pkgs.eza}/bin/eza --group-directories-first --icons";
          la = "ls -a";
          l = "ls -lg";
          ll = "ls -alg";
          lt = "ls --tree -D -L 2 -I ${treeIgnore}";
          ltt = "ls --tree -D -L 3 -I ${treeIgnore}";
        };
    };

}
