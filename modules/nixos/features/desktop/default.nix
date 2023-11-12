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
    antob.apps = {
      kitty = enabled;
      firefox = enabled;
      librewolf = enabled;
      vscodium = enabled;
      slack = enabled;
    };

    environment.systemPackages = with pkgs; [
      arandr
      chromium
      libreoffice-still
      gimp
    ];
  };
}
