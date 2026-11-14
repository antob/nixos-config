{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.zsh =
    { config, lib, ... }:

    with lib;
    {
      options.antob.zsh = with types; {
        extraOhMyZshPlugins = mkOpt (listOf str) [ ] "Extra plugins for OhMyZsh.";
      };

      config = {
        home-manager.sharedModules = [ homeManager.zsh ];

        programs.zsh.enable = true;

        antob.persistence.safe.home.directories = [ ".local/share/zsh" ];
      };
    };

  flake.modules.homeManager.zsh =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = osConfig.antob.zsh;
      inherit (osConfig.lib.stylix) colors;
    in
    {
      programs.zsh = {
        enable = true;
        enableCompletion = true;
        autosuggestion = {
          enable = true;
          highlight = "fg=#${colors.base04}";
        };
        syntaxHighlighting.enable = true;
        defaultKeymap = "emacs";
        dotDir = "/home/${osConfig.antob.user.name}/.config/zsh";

        historySubstringSearch = {
          enable = true;
          searchUpKey = "^[[A";
          searchDownKey = "^[[B";
        };

        history = {
          size = 100000;
          expireDuplicatesFirst = true;
          path = "$XDG_DATA_HOME/zsh/zsh_history";
        };

        siteFunctions = {
          tempe = ''
            cd "$(mktemp -d)"
            chmod -R 0700 .
            if [[ $# -eq 1 ]]; then
              \mkdir -p "$1"
              cd "$1"
              chmod -R 0700 .
            fi
          '';

          boop = ''
            local last="$?"
            if [[ "$last" == '0' ]]; then
              sfx good
            else
              sfx bad
            fi
            $(exit "$last")
          '';
        };

        initContent = lib.mkMerge [
          (lib.mkOrder 550 ''
            # Fix slow text paste
            DISABLE_MAGIC_FUNCTIONS="true"
          '')
          (lib.mkOrder 1000 ''
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

            # Sync client vars from the tmux session (kept current by tmux-sync-client-env hooks)
            function sync_tmux_client_env() {
              [[ -n $TMUX ]] || return
              local -A env
              local line var
              for line in ''${(f)"$(tmux show-environment 2>/dev/null)"}; do
                [[ $line == *=* ]] && env[''${line%%=*}]=''${line#*=}
              done
              for var in SSH_CONNECTION WAYLAND_DISPLAY DISPLAY; do
                if [[ -n ''${env[$var]} ]]; then
                  export $var=''${env[$var]}
                else
                  unset $var
                fi
              done
              [[ -n ''${env[SSH_AUTH_SOCK]} ]] && export SSH_AUTH_SOCK=''${env[SSH_AUTH_SOCK]}
            }
            precmd_functions=(sync_tmux_client_env $precmd_functions)

            # Customize ZSH highligh colors
            typeset -A ZSH_HIGHLIGHT_STYLES
            ZSH_HIGHLIGHT_STYLES[comment]='fg=245'

            # Do not emit % when starting terminal and tmux
            setopt PROMPT_CR
            setopt PROMPT_SP
            export PROMPT_EOL_MARK=""
          '')
        ];

        oh-my-zsh = {
          enable = true;
          plugins = cfg.extraOhMyZshPlugins;
        };
      };
    };

}
