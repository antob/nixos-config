{ options, config, lib, pkgs, ... }:

with lib;
let cfg = config.antob.desktop.addons.autorandr;
in {
  options.antob.desktop.addons.autorandr = with types; {
    enable = mkEnableOption "Whether to enable autorandr.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.autorandr ];

    antob.home.extraOptions = {
      services.autorandr.enable = true;
      programs.autorandr = {
        enable = true;
        hooks = {
          postswitch = mkIf config.antob.desktop.xfce-xmonad.enable {
            "notify-xmonad" = "xmonad --restart";
          };
        };
      };
    };
  };
}
