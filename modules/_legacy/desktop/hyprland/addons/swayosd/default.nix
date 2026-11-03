{
  config,
  lib,
  ...
}:

let
  cfg = config.antob.desktop.hyprland;
  colors = config.antob.color-scheme.colors;
in
{
  config = lib.mkIf cfg.enable {
    antob.home.extraOptions = {
      xdg.configFile."swayosd/config.toml".text = ''
        [server]
        show_percentage = true
        max_volume = 100
        style = "./style.css"
      '';

      xdg.configFile."swayosd/style.css".text = ''
        window {
          border-radius: 8px;
          opacity: 0.97;
          border: 2px solid #${colors.base0C};
          background-color: #${colors.base01};
        }

        label {
          font-family: 'SFNS Display 12';
          font-size: 11pt;

          color: #${colors.base06};
        }

        image {
          color: #${colors.base06};
        }

        progressbar {
          border-radius: 0;
        }

        progress {
          background-color: #${colors.base06};
        }
      '';
    };
  };
}
