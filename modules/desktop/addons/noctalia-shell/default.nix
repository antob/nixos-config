# noctalia-shell ipc call state all | jq .settings > modules/desktop/addons/noctalia-shell/settings.json
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.noctalia-shell;
in
{
  options.antob.desktop.addons.noctalia-shell = with types; {
    enable = mkEnableOption "Enable Noctalia shell.";
    enableCache = mkEnableOption "Enable Noctalia shell build cache.";
  };

  config = mkMerge [
    (mkIf cfg.enableCache {
      nix.settings = {
        extra-substituters = [ "https://noctalia.cachix.org" ];
        extra-trusted-public-keys = [
          "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4="
        ];
      };
    })
    (mkIf cfg.enable {
      antob.home.extraOptions = {
        imports = [
          inputs.noctalia.homeModules.default
        ];

        programs.noctalia-shell = {
          enable = true;
          # settings = ./settings.json;
        };
      };

      environment.systemPackages = with pkgs; [
        inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
        swappy
        wf-recorder
        grim
        slurp
        hyprpicker
        wl-clipboard
        tesseract
        imagemagick
        zbar
        curl
        translate-shell
        wl-screenrec
        ffmpeg
        gifski
        jq
        # python3
        # python3Packages.pygobject
        xdg-desktop-portal
      ];

      antob.persistence.home.directories = [
        ".config/noctalia"
      ];
    })
  ];
}
