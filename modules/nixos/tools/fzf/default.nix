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

        defaultOptions = import ./themes/tokyonight-night.nix ++ [
          "--tmux 80%"
        ];

        defaultCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";

        fileWidgetCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";
        fileWidgetOptions = [
          "--tmux 90% --preview '${pkgs.bat}/bin/bat -n --color=always --line-range :500 {}'"
        ];

        changeDirWidgetCommand = "${pkgs.fd}/bin/fd --type=d --hidden --strip-cwd-prefix --exclude .git";
        changeDirWidgetOptions = [ "--preview '${pkgs.eza}/bin/eza --tree --color=always {} | head -200'" ];
      };

      programs.zsh.initContent = mkOrder 200 ''
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
  };
}
