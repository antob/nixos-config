{ options, config, lib, pkgs, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.cli-apps.tmux;
  configFiles = lib.snowfall.fs.get-files ./config;

  plugins = with pkgs; [
    tmuxPlugins.sensible
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
    environment.systemPackages = with pkgs; [
      (writeShellScriptBin "tmux-attach-unused" ''
        tmux attach -t $(tmux ls | grep -v attached | cut -f1 -d: | grep -E "^[0-9]+$" | head -1) || tmux
      '')
      sesh
    ];

    antob.home.extraOptions = {
      programs.tmux = {
        enable = true;
        terminal = "screen-256color";
        clock24 = true;
        historyLimit = 100000;
        extraConfig = builtins.concatStringsSep "\n"
          (builtins.map lib.strings.fileContents configFiles);

        inherit plugins;
      };
    };
  };
}
