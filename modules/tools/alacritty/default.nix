{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.tools.alacritty;
in
{
  options.antob.tools.alacritty = with types; {
    enable = mkEnableOption "Enable alacritty";
    fontSize = mkOpt int 12 "Font size.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      programs.alacritty = {
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
            size = cfg.fontSize;
            offset.y = 2;
          };

          scrolling = {
            history = 100000;
          };

          selection = {
            save_to_clipboard = true;
          };

          colors = import ./themes/tokyonight-night.nix;

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
          ];
        };
      };

      fonts.fontconfig.configFile."alacritty-emoji-fallback" = {
        enable = true;
        priority = 99;
        text = ''
          <?xml version="1.0"?>
          <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
          <fontconfig>
            <match target="pattern">
              <test name="prgname">
                <string>alacritty</string>
              </test>
              <edit name="family" mode="append" binding="weak">
                <string>Noto Color Emoji</string>
              </edit>
            </match>
          </fontconfig>
        '';
      };
    };
  };
}
