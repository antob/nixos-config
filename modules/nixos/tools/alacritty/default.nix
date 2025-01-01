{
  config,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.tools.alacritty;
in
{
  options.antob.tools.alacritty = with types; {
    enable = mkEnableOption "Enable alacritty";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.programs.alacritty = {
      enable = true;

      settings = {
        env = {
          TERM = "xterm-256color";
        };

        window = {
          padding = {
            x = 12;
            y = 9;
          };
          decorations = "None";
          startup_mode = "Maximized";
        };

        font = {
          normal = {
            family = "Hack Nerd Font";
            style = "Regular";
          };
          size = 12;
          offset.y = 2;
        };

        scrolling = {
          history = 100000;
        };

        selection = {
          save_to_clipboard = true;
        };

        colors = import ./themes/catppuccin-mocha.nix;

        cursor = {
          style.shape = "Beam";
          thickness = 0.2;
        };

        keyboard.bindings = [
          {
            key = "+";
            mods = "Control|Shift";
            action = "IncreaseFontSize";
          }
          {
            key = "_";
            mods = "Control|Shift";
            action = "DecreaseFontSize";
          }
          {
            key = ")";
            mods = "Control|Shift";
            action = "ResetFontSize";
          }

          ## Tmux shortcuts
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
        ];
      };
    };
  };
}
