{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.host.tools.zsh;
in {
  options.host.tools.zsh = with types; {
    enable = mkEnableOption "Whether or not to install and configure zsh.";
  };

  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      enableAutosuggestions = true;
      enableSyntaxHighlighting = true;

      history = {
        expireDuplicatesFirst = true;
        path = "${config.xdg.dataHome}/zsh/zsh_history";
      };

      initExtra = ''
        # Use vim bindings.
        set -o vi

        # Improved vim bindings.
        source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
      '';

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
      };
    };
  };
}
