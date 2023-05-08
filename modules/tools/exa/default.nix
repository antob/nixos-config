{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.antob.tools.exa;
in {
  options.antob.tools.exa = with types; {
    enable = mkEnableOption "Whether or not to install and configure exa.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      home.shellAliases =
        let treeIgnore = "'cache|log|logs|node_modules|vendor|.git'";
        in {
          ".." = "cd ..";
          ls = "${pkgs.exa}/bin/exa --group-directories-first";
          la = "ls -a";
          l = "ls -l";
          ll = "ls -al";
          lt = "ls --tree -D -L 2 -I ${treeIgnore}";
          ltt = "ls --tree -D -L 3 -I ${treeIgnore}";
        };
    };
  };
}
