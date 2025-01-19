{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.desktop.addons.autorandr;
in
{
  options.antob.desktop.addons.autorandr = with types; {
    enable = mkEnableOption "Whether to enable autorandr.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.autorandr ];
    services.udev.packages = [ pkgs.autorandr ];
    antob.persistence.home.directories = [ ".config/autorandr" ];

    antob.home.extraOptions = {
      services.autorandr.enable = true;
      programs.autorandr = {
        enable = true;
        hooks = {
          postswitch = {
            feh = "~/.fehbg";
          };
        };
      };
    };
  };
}
