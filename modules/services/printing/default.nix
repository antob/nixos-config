# Add printer with: `$ lpadmin -p HP -E -v "ipp://192.168.1.120/ipp/print" -m everywhere`
{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
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
