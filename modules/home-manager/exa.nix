{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.host.tools.exa;
in {
  options.host.tools.exa = with types; {
    enable = mkEnableOption "Whether or not to install and configure exa.";
  };

  config = mkIf cfg.enable {
    programs.exa = { enable = true; };

    programs.zsh.shellAliases =
      let treeIgnore = "'cache|log|logs|node_modules|vendor|.git'";
      in {
        ls = "exa --group-directories-first";
        la = "ls -a";
        l = "ls --git -l";
        ll = "ls --git -al";
        lt = "ls --tree -D -L 2 -I ${treeIgnore}";
        ltt = "ls --tree -D -L 3 -I ${treeIgnore}";
        lttt = "ls --tree -D -L 4 -I ${treeIgnore}";
        ltttt = "ls --tree -D -L 5 -I ${treeIgnore}";
      };
  };
}
