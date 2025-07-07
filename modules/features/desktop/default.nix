{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
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
      ungoogled-chromium
      libreoffice-still
      gimp
      mpv
      vlc
      v4l-utils
      guvcview # webcam tool
      gnome-calculator
      # remmina # Remote Desktop Client
      obsidian
      discord
    ];
  };
}
