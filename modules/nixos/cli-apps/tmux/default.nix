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
        tmux attach 2> /dev/null -t $(tmux ls 2> /dev/null | grep -v attached | cut -f1 -d: | grep -E "^[0-9]+$" | head -1) || tmux
      '')
      sesh
      wl-clipboard
    ];

    antob.home.extraOptions = {
      programs.tmux = {
        enable = true;
        terminal = "xterm-256color";
        clock24 = true;
        historyLimit = 100000;
        extraConfig = builtins.concatStringsSep "\n"
          (builtins.map lib.strings.fileContents configFiles);

        inherit plugins;
      };
    };
  };
}
