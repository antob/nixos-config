{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.hardware.webcam;
in
{
  options.antob.hardware.webcam = with types; {
    enable = mkBoolOpt false "Whether or not to enable webcam support.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      v4l-utils
      guvcview
    ];

    antob.persistence.home.directories = [
      ".config/guvcview2"
    ];
  };
}
