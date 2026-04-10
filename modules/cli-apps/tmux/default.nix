{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.cli-apps.tmux;
  configFiles = getFiles ./config;
  colors = config.antob.color-scheme.colors;
  alacritty = config.antob.tools.alacritty.enable;
  kitty = config.antob.tools.kitty.enable;

  plugins = with pkgs; [
    tmuxPlugins.sensible
    tmuxPlugins.tmux-fzf
    {
      plugin = tmuxPlugins.resurrect;
      extraConfig = ''
        set -g @resurrect-dir '~/.local/share/tmux/resurrect'
        set -g @resurrect-save 'S'
        set -g @resurrect-restore 'R'
      '';
    }
    {
      plugin = tmuxPlugins.catppuccin;
      extraConfig = ''
        set -g @catppuccin_flavor "frappe"
        set -g @catppuccin_status_left_separator "█"
        set -g @catppuccin_pane_active_border_style "fg=#${colors.base0C}"
        set -ogq @catppuccin_window_text " #W"
        set -ogq @catppuccin_window_current_text " #W"
      '';
    }
  ];
in
{
  options.antob.cli-apps.tmux = with types; {
    enable = mkBoolOpt false "Whether or not to enable tmux.";
    addTerminalKeybindings = mkBoolOpt true "Whether or not to add keybindings to terminals in tmux.";
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
        extraConfig = builtins.concatStringsSep "\n" (map lib.strings.fileContents configFiles);

        inherit plugins;
      };

      programs.alacritty.settings.keyboard.bindings = lib.mkIf (cfg.addTerminalKeybindings && alacritty) [
        ## Make Alacritty send Control+Shift keys
        # Cycle layout
        {
          key = "l";
          mods = "Control|Shift";
          chars = "\\uE000";
        }
        # Spawn new pane
        {
          key = "Return";
          mods = "Control|Shift";
          chars = "\\uE010";
        }
        # Toggle pane zoom
        {
          key = "m";
          mods = "Control|Shift";
          chars = "\\uE011";
        }
        # Spawn new window
        {
          key = "t";
          mods = "Control|Shift";
          chars = "\\uE020";
        }
        # Focus previous window
        {
          key = "{";
          mods = "Control|Shift";
          chars = "\\uE021";
        }
        # Focus next window
        {
          key = "}";
          mods = "Control|Shift";
          chars = "\\uE022";
        }
        # Make Alacritty send Shift+Enter for new line in tmux
        {
          key = "Return";
          mods = "Shift";
          chars = "\\u001b[13;2u";
        }
      ];

      programs.kitty.keybindings = lib.mkIf (cfg.addTerminalKeybindings && kitty) {
        ## Make Kitty send Control+Shift keys
        # Cycle layout
        "ctrl+shift+l" = "send_text all \\uE000";

        # Spawn new pane
        "ctrl+shift+enter" = "send_text all \\uE010";

        # Toggle pane zoom
        "ctrl+shift+m" = "send_text all \\uE011";

        # Spawn new window
        "ctrl+shift+t" = "send_text all \\uE020";

        # Focus previous window
        "ctrl+shift+[" = "send_text all \\uE021";

        # Focus next window
        "ctrl+shift+]" = "send_text all \\uE022";
      };
    };

    antob.persistence.home.directories = [ ".local/share/tmux" ];
  };
}
