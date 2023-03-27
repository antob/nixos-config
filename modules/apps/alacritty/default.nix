{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.antob.apps.alacritty;
in {
  options.antob.apps.alacritty = with types; {
    enable = mkEnableOption "Enable alacritty";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions.programs.alacritty = {
      enable = true;

      settings = {
        env = { TERM = "xterm-256color"; };

        window = {
          padding = {
            x = 8;
            y = 6;
          };
          # decorations = "none";
          decorations = "full";
        };

        font = {
          normal = {
            family = "Hack Nerd Font";
            style = "Regular";
          };
          size = 11.0;
        };

        colors = {
          primary = {
            background = "#282828";
            foreground = "#ebdbb2";
          };
          cursor = {
            text = "#555555";
            cursor = "#add8e6";
          };
          normal = {
            black = "#282828";
            red = "#cc241d";
            green = "#98971a";
            yellow = "#d79921";
            blue = "#458588";
            magenta = "#b16286";
            cyan = "#689d6a";
            white = "#a89984";
          };
          bright = {
            black = "#928374";
            red = "#fb4934";
            green = "#b8bb26";
            yellow = "#fabd2f";
            blue = "#83a598";
            magenta = "#d3869b";
            cyan = "#8ec07c";
            white = "#ebdbb2";
          };
        };

        cursor.style.shape = "Beam";

        key_bindings = [
          {
            key = "Tab";
            mods = "Control";
            chars = "x1b[9;5u";
          }
          {
            key = "Tab";
            mods = "Control|Shift";
            chars = "x1b[9;6u";
          }
        ];
      };
    };
  };
}
