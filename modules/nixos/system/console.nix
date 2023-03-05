{ config, lib, pkgs, ... }:

with lib;

let
  mkOpt = type: default: description:
    mkOption { inherit type default description; };
  mkBoolOpt = mkOpt types.bool;

  cfg = config.host.system.console;

in {
  options.host.system.console = with types; {
    enable = mkBoolOpt false "Whether or not to manage console settings.";
  };

  config = mkIf cfg.enable {
    console = {
      earlySetup = true;
      font = "${pkgs.terminus_font}/share/consolefonts/ter-124n.psf.gz";
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
}
