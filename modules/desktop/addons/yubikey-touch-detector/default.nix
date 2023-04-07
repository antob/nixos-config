{ config, options, lib, pkgs, ... }:

with lib;

let cfg = config.antob.desktop.addons.yubikey-touch-detector;
in {
  options.antob.desktop.addons.yubikey-touch-detector = with types; {
    enable =
      mkEnableOption "Whether or not to install and configure yubikey-touch-detector.";
  };

  config = mkIf cfg.enable {
    antob.home.extraOptions = {
      home.packages = [ pkgs.yubikey-touch-detector ];
      home.file = { ".local/share/icons/yubikey-touch-detector.png".source = ./yubikey-touch-detector.png; };
    };
  };
}
