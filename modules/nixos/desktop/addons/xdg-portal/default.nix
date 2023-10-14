{ options, config, lib, pkgs, ... }:

with lib;
with lib.antob;
let cfg = config.antob.desktop.addons.xdg-portal;
in {
  options.antob.desktop.addons.xdg-portal = with types; {
    enable = mkEnableOption "Whether or not to add support for xdg portal.";
  };

  config = mkIf cfg.enable {
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };
  };
}
