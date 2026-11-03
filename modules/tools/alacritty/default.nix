{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.alacritty =
    { lib, ... }:

    with lib;
    {
      config.home-manager.sharedModules = [ homeManager.alacritty ];

      options.antob.alacritty = with types; {
        fontSize = mkOpt int 12 "Font size.";
      };

    };

  flake.modules.homeManager.alacritty =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      cfg = osConfig.antob.alacritty;
    in
    {
      programs.alacritty = {
        enable = true;
        package = pkgs.alacritty;

        settings = {
          env = {
            TERM = "alacritty";
          };

          window = {
            padding = {
              x = 12;
              y = 9;
            };
            decorations = "None";
            # startup_mode = "Maximized";
          };

          font = {
            normal = {
              family = "Hack Nerd Font";
              style = "Regular";
            };
            size = cfg.fontSize;
            offset = {
              y = 0;
              x = 0;
            };
          };

          scrolling = {
            history = 100000;
          };

          selection = {
            save_to_clipboard = true;
          };

          colors = import ./_files/themes/tokyonight-night.nix;

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
              <edit name="family" mode="append" binding="strong">
                <string>Noto Color Emoji</string>
              </edit>
            </match>
          </fontconfig>
        '';
      };
    };

}
