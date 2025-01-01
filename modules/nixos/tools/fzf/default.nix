{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.tools.fzf;
in
{
  options.antob.tools.fzf = with types; {
    enable = mkEnableOption "Whether or not to install and configure fzf.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.fzf = {
        enable = true;
        enableZshIntegration = true;

        defaultOptions = [
          "--color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8"
          "--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc"
          "--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8"
          "--color=selected-bg:#45475a --multi"
        ];

        defaultCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";

        fileWidgetCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";
        fileWidgetOptions = [ "--preview '${pkgs.bat}/bin/bat -n --color=always --line-range :500 {}'" ];

        changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type=d --hidden --strip-cwd-prefix --exclude .git";
        changeDirWidgetOptions = [ "--preview '${pkgs.eza}/bin/eza --tree --color=always {} | head -200'" ];
      };

      programs.zsh.initExtra = mkOrder 200 ''
        # Use fd for listing path candidates.
        _fzf_compgen_path() {
          fd --hidden --exclude ".git" . "$1"
        }

        # Use fd to generate the list for directory completion
        _fzf_compgen_dir() {
          fd --type d --hidden --exclude ".git" . "$1"
        }

        # Advanced customization of fzf options via _fzf_comprun function
        _fzf_comprun() {
          local command=$1
          shift

          case "$command" in
            cd)           fzf --preview '${pkgs.eza}/bin/eza --tree --color=always {} | head -200' "$@" ;;
            export|unset) fzf --preview "eval 'echo \$'{}" "$@" ;;
            ssh)          fzf --preview '${pkgs.dig}/bin/dig {}' "$@" ;;
            *)            fzf --preview '${pkgs.bat}/bin/bat -n --color=always --line-range :500 {}' "$@" ;;
          esac
        }
      '';
    };

    environment.sessionVariables = {
      FZF_COMPLETION_TRIGGER = "?";
    };
  };
}
