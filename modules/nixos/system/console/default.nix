{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.system.console;
in
{
  options.antob.system.console = with types; {
    enable = mkEnableOption "Whether or not to manage console settings.";
    setFont = mkBoolOpt true "Whether or not to set custom console font.";
  };

  config = mkIf cfg.enable {
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
}
