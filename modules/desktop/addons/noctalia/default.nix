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
  inherit (config.antob.color-scheme) colors;
  theme = import ./themes/doomed-cyan.nix { inherit colors; };

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
      antob = {
        tools.swappy.enable = true;

        persistence.home.directories = [
          ".local/state/noctalia"
        ];

        home.configFile = {
          "noctalia/palettes/${theme.name}.json".text = builtins.toJSON theme.palette;

          "noctalia/theme.toml".text = /* toml */ ''
            [theme]
            source = "custom"
            custom_palette = "${theme.name}"
          '';
        };
      };
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
