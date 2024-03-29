{ options, config, lib, pkgs, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.cli-apps.tmux;
  configFiles = lib.snowfall.fs.get-files ./config;

  plugins = with pkgs; [
    tmuxPlugins.sensible
    tmuxPlugins.vim-tmux-navigator
    tmuxPlugins.tmux-fzf
    tmux-onedark-theme
    tmuxPlugins.yank
    tmuxPlugins.resurrect
  ];
in
{
  options.antob.cli-apps.tmux = with types; {
    enable = mkBoolOpt false "Whether or not to enable tmux.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.tmux = {
        enable = true;
        terminal = "screen-256color";
        clock24 = true;
        historyLimit = 20000;
        newSession = true;
        extraConfig = builtins.concatStringsSep "\n"
          (builtins.map lib.strings.fileContents configFiles);

        inherit plugins;
      };
    };
  };
}
