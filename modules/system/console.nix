{ config, ... }:
let
  inherit (config.flake.lib) mkBoolOpt;
in
{
  flake.modules.nixos.console =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    with lib;
    let
      cfg = config.antob.console;
    in
    {
      options.antob.console = with types; {
        setFont = mkBoolOpt false "Whether or not to set custom console font.";
      };

      config = {
        console = mkIf cfg.setFont {
          earlySetup = true;
          font = "ter-124b";
          packages = with pkgs; [ terminus_font ];
        };

        systemd.services.kbdrate = {
          description = "Set console typematic delay and rate";
          wantedBy = [ "multi-user.target" ];
          serviceConfig.Type = "oneshot";
          script = with pkgs; ''
            # Set console typematic delay and rate
            ${kbd}/bin/kbdrate -d 200 -r 30
          '';
        };
      };
    };

}
