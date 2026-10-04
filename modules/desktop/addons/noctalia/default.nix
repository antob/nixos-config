{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.noctalia;
  vpnCfg = config.antob.services.networkd-vpn;

  # Input for the vpn-status plugin: the VPNs to watch and the menu opened on click.
  vpnStatusConfig = builtins.toJSON {
    vpns = mapAttrsToList (name: vpn: {
      interface = name;
      inherit (vpn) label;
    }) vpnCfg.vpns;
    menu = getExe (pkgs.callPackage ../../scripts/dm-networkd-vpn.nix { inherit config; });
  };
in
{
  options.antob.desktop.addons.noctalia = with types; {
    enable = mkEnableOption "Enable Noctalia.";
  };

  config = mkIf cfg.enable (mkMerge [
    {
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
    }

    (mkIf vpnCfg.enable {
      # Local plugins in the data dir take precedence over every plugin source.
      # Enable once with `noctalia msg plugins enable antob/vpn-status`.
      antob.home.extraOptions.xdg.dataFile = {
        "noctalia/plugins/vpn-status" = {
          source = ./plugins/vpn-status;
          recursive = true;
        };
        "noctalia/plugins/vpn-status/vpns.json".text = vpnStatusConfig;
      };
    })
  ]);
}
