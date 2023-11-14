{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.tools.zsh;
in {
  options.antob.tools.zsh = with types; {
    enable = mkEnableOption "Whether or not to install and configure zsh.";
    extraOhMyZshPlugins = mkOpt (listOf str) [ ] "Extra plugins for OhMyZsh.";
  };

  config = mkIf cfg.enable {
    programs.zsh.enable = true;
    antob.home.extraOptions = {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        enableAutosuggestions = true;
        syntaxHighlighting.enable = true;
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

        initExtraBeforeCompInit = ''
          # Fix slow text paste
          DISABLE_MAGIC_FUNCTIONS="true"
        '';

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

          # Customize ZSH highligh colors
          typeset -A ZSH_HIGHLIGHT_STYLES
          ZSH_HIGHLIGHT_STYLES[comment]='fg=245'
        '';

        oh-my-zsh = {
          enable = true;
          plugins = [ "git" ] ++ cfg.extraOhMyZshPlugins;
        };
      };

      programs.fzf = {
        enable = true;
        enableZshIntegration = true;
      };
    };

    antob.persistence.safe.home.directories = [ ".local/share/zsh" ];
  };
}
