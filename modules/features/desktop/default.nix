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
      };

      services = {
        printing = enabled;
        syncthing = enabled;
        avahi = enabled;
      };

      home.extraOptions = {
        # Default apps
        xdg.mimeApps.defaultApplications = {
          # Open all images with imv
          "image/png" = [ "imv.desktop" ];
          "image/jpeg" = [ "imv.desktop" ];
          "image/gif" = [ "imv.desktop" ];
          "image/webp" = [ "imv.desktop" ];
          "image/bmp" = [ "imv.desktop" ];
          "image/tiff" = [ "imv.desktop" ];

          # Open PDFs with the Document Viewer
          "application/pdf" = [ "org.gnome.Evince.desktop" ];

          # Open video files with mpv
          "video/mp4" = [ "mpv.desktop" ];
          "video/x-msvideo" = [ "mpv.desktop" ];
          "video/x-matroska" = [ "mpv.desktop" ];
          "video/x-flv" = [ "mpv.desktop" ];
          "video/x-ms-wmv" = [ "mpv.desktop" ];
          "video/mpeg" = [ "mpv.desktop" ];
          "video/ogg" = [ "mpv.desktop" ];
          "video/webm" = [ "mpv.desktop" ];
          "video/quicktime" = [ "mpv.desktop" ];
          "video/3gpp" = [ "mpv.desktop" ];
          "video/3gpp2" = [ "mpv.desktop" ];
          "video/x-ms-asf" = [ "mpv.desktop" ];
          "video/x-ogm+ogg" = [ "mpv.desktop" ];
          "video/x-theora+ogg" = [ "mpv.desktop" ];
          "application/ogg" = [ "mpv.desktop" ];
        };
      };
    };

    environment.systemPackages = with pkgs; [
      arandr
      ungoogled-chromium
      libreoffice-still
      gimp
      mpv
      imv
      vlc
      v4l-utils
      nixpkgs-prev.guvcview # webcam tool
      gnome-calculator
      evince
      # remmina # Remote Desktop Client
      obsidian
      discord
    ];

    antob.persistence.home.directories = [
      ".config/discord"
      ".config/irb"
      ".config/obsidian"
      ".config/chromium"
    ];
  };
}
