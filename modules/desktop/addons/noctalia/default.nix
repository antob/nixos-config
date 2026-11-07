{ config, ... }:
let
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules.nixos.noctalia =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      imports = [ nixos.swappy ];

      config = mkMerge [
        { home-manager.sharedModules = [ homeManager.noctalia ]; }

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

            persistence.home.directories = [
              ".local/state/noctalia"
            ];

          };
        }

        (mkIf (config.antob ? networkd-vpn) {
          # Local plugins in the data dir take precedence over every plugin source.
          # Enable once with `noctalia msg plugins enable antob/vpn-status`.
        })
      ];
    };

  flake.modules.homeManager.noctalia =
    {
      osConfig,
      lib,
      pkgs,
      ...
    }:
    with lib;
    let
      vpnCfg = osConfig.antob.networkd-vpn;
      theme = import ./_files/stylix-palette.nix {
        inherit (osConfig.lib.stylix) colors;
        inherit lib;
      };
      # Input for the vpn-status plugin: the VPNs to watch and the menu opened on click.
      vpnStatusConfig = builtins.toJSON {
        vpns = mapAttrsToList (name: vpn: {
          interface = name;
          inherit (vpn) label;
        }) vpnCfg.vpns;
        menu = getExe (pkgs.callPackage ../../_scripts/dm-networkd-vpn.nix { config = osConfig; });
      };
    in
    {
      config = lib.mkMerge [
        {
          xdg.configFile = {
            "noctalia/palettes/${theme.name}.json".text = builtins.toJSON theme.palette;

            "noctalia/theme.toml".text = /* toml */ ''
              [theme]
              source = "custom"
              custom_palette = "${theme.name}"
              mode = "dark"
            '';
          };
        }
        (lib.mkIf (osConfig.antob ? networkd-vpn) {
          xdg.dataFile = {
            "noctalia/plugins/vpn-status" = {
              source = ./_files/plugins/vpn-status;
              recursive = true;
            };
            "noctalia/plugins/vpn-status/vpns.json".text = vpnStatusConfig;
          };
        })
      ];
    };

}
