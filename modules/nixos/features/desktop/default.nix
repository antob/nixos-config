{ options, config, lib, pkgs, ... }:

with lib;
with lib.antob;
let
  cfg = config.antob.features.desktop;
in
{
  options.antob.features.desktop = with types; {
    enable = mkBoolOpt false "Whether or not to enable desktop configuration.";
  };

  config = mkIf cfg.enable {
    antob = {
      apps = {
        firefox = enabled;
        librewolf = enabled;
        vscodium = enabled;
        vscode = enabled;
        slack = enabled;
      };

      services = {
        printing = enabled;
        syncthing = enabled;
        avahi = enabled;
      };
    };

    environment.systemPackages = with pkgs; [
      arandr
      chromium
      libreoffice-still
      gimp
      mpv
      vlc
      v4l-utils
      guvcview
      gnome.gnome-calculator
      # rustdesk
      remmina
    ];
  };
}
