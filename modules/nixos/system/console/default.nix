{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.system.console;
in {
  options.antob.system.console = with types; {
    enable = mkEnableOption "Whether or not to manage console settings.";
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
