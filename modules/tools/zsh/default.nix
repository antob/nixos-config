{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.zsh;
in
{
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
        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        defaultKeymap = "emacs";
        dotDir = "/home/${config.antob.user.name}/.config/zsh";

        historySubstringSearch = {
          enable = true;
          searchUpKey = "^[[A";
          searchDownKey = "^[[B";
        };

        history = {
          expireDuplicatesFirst = true;
          path = "$XDG_DATA_HOME/zsh/zsh_history";
        };

        initContent =
          (lib.mkOrder 550 ''
            # Fix slow text paste
            DISABLE_MAGIC_FUNCTIONS="true"
          '')
          // (lib.mkOrder 1000 ''
            # Use vim bindings.
            #set -o vi

            # Improved vim bindings.
            #source ${pkgs.zsh-vi-mode}/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh

            # zsh-window-title plugin.
            export DISABLE_AUTO_TITLE="true" # Disable oh-my-zsh auto title
            export ZSH_WINDOW_TITLE_DIRECTORY_DEPTH=1
            source ${pkgs.zsh-window-title}/share/zsh-window-title/zsh-window-title.plugin.zsh

            # ZSH Widget bindings
            bindkey "^b" backward-word
            bindkey "^f" forward-word

            # Fix cursor changing to block style
            function restore_cursor(){
              printf "\x1b[\x36 q"
            }
            precmd_functions+=(restore_cursor)

            # Customize ZSH highligh colors
            typeset -A ZSH_HIGHLIGHT_STYLES
            ZSH_HIGHLIGHT_STYLES[comment]='fg=245'

            # Do not emit % when starting alacritty and tmux
            setopt PROMPT_CR
            setopt PROMPT_SP
            export PROMPT_EOL_MARK=""
          '');

        oh-my-zsh = {
          enable = true;
          plugins = [ "git" ] ++ cfg.extraOhMyZshPlugins;
        };
      };
    };

    antob.persistence.safe.home.directories = [ ".local/share/zsh" ];
  };
}
