{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.addons.swayosd;
in
{
  options.antob.desktop.addons.swayosd = with types; {
    enable = mkEnableOption "Whether to enable swayosd.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      home.packages = [ pkgs.swayosd ];

      systemd.user = {
        services.swayosd = {
          Unit = {
            Description = "Volume/backlight OSD indicator";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };

          Service = {
            Type = "simple";
            ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
            Restart = "always";
          };

          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };
      };
    };

    services.udev.extraRules = ''
      # Rules for SwayOSD brightness control
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness"
      ACTION=="add", SUBSYSTEM=="backlight", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
    '';

    antob.user.extraGroups = [ "video" ];
  };
}
