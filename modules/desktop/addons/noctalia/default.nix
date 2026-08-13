{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.noctalia;
in
{
  options.antob.desktop.addons.noctalia = with types; {
    enable = mkEnableOption "Enable Noctalia.";
  };

  config = mkIf cfg.enable {
    programs.noctalia = {
      enable = true;
    };

    antob.tools.swappy.enable = true;

    environment.systemPackages = with pkgs; [
      grim
      slurp
      # wf-recorder
      wl-clipboard
      hyprpicker
      tesseract
      imagemagick
      zbar
      curl
      translate-shell
      wl-screenrec
      ffmpeg
      # gifski
      jq
    ];

    antob.persistence.home.directories = [
      ".local/state/noctalia"
    ];
  };
}
