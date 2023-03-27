{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.antob.tools.git;
in {
  options.antob.tools.zsh = with types; {
    enable = mkEnableOption "Whether or not to install and configure zsh.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        enableAutosuggestions = true;
        enableSyntaxHighlighting = true;
        defaultKeymap = "emacs";
        dotDir = ".config/zsh";

        historySubstringSearch = {
          enable = true;
          searchUpKey = "^[[A";
          searchDownKey = "^[[B";
        };

        history = {
          expireDuplicatesFirst = true;
          path = "$XDG_DATA_HOME/zsh/zsh_history";
        };

        initExtra = ''
          # Use vim bindings.
          #set -o vi

          # Improved vim bindings.
          #source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

          # Fix cursor changing to block style
          function restore_cursor(){
            printf "\x1b[\x36 q"
          }
          precmd_functions+=(restore_cursor)
        '';

        oh-my-zsh = {
          enable = true;
          plugins = [ "git" "docker-compose" ];
        };
      };

      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };
    };
  };
}
