{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.antob;
let
  cfg = config.antob.services.printing;
in
{
  options.antob.services.printing = with types; {
    enable = mkEnableOption "Whether or not to configure printing support.";
  };

  config = mkIf cfg.enable {
    services.printing = {
      enable = true;
      extraConf = ''
        ErrorPolicy retry-job
        DefaultEncryption Never
      '';
    };

    services.colord.enable = true;

    environment.systemPackages = with pkgs; [
      pkgs.system-config-printer
      hplip
    ];

    antob.persistence.directories = [ "/etc/cups" ];
  };
}
