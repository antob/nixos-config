{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.antob.desktop.addons.volumeicon;
in
{
  options.antob.desktop.addons.volumeicon = with types; {
    enable = mkEnableOption "Whether or not to install and configure volumeicon.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      home.packages = [
        pkgs.volumeicon
        pkgs.at-spi2-atk
      ];
      xdg.configFile."volumeicon/volumeicon".source = ./config.ini;

      systemd.user.services.volumeicon = {
        Unit = {
          Description = "Volumeicon applet";
          Requires = [ "tray.target" ];
          After = [
            "graphical-session-pre.target"
            "tray.target"
          ];
          PartOf = [ "graphical-session.target" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };

        Service = {
          ExecStart = "${pkgs.volumeicon}/bin/volumeicon";
        };
      };
    };
  };
}
