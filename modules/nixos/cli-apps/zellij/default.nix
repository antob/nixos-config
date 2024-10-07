{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.cli-apps.zellij;
in {
  options.antob.cli-apps.zellij = with types; {
    enable = mkEnableOption "Whether or not to install and configure Zellij.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      home.file = { ".config/zellij/config.kdl".source = ./config.kdl; };

      programs.zellij = {
        enable = true;
        # enableZshIntegration = true;
      };

      # Generate auto completion.
      # Include work around for issue https://github.com/zellij-org/zellij/issues/1933
      programs.zsh.initExtra = mkOrder 200 ''
        autoload -U +X compinit && compinit
        . <( zellij setup --generate-completion zsh | sed -Ee 's/^(_(zellij) ).*/compdef \1\2/' )
      '';
    };

    environment.shellAliases = {
      z = "zellij";
    };
  };
}
