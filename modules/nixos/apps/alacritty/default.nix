{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
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
          decorations = "full";
        };

        font = {
          normal = {
            family = "Hack Nerd Font";
            style = "Regular";
          };
          size = 11.5;
        };

        # colors = import ./themes/custom.nix;
        # colors = import ./themes/catppuccin-mocha.nix;
        colors = import ./themes/one-dark.nix;

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
