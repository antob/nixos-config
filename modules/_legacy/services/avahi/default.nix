{
  lib,
  config,
  ...
}:

let
  cfg = config.antob.services.avahi;

  inherit (lib) mkEnableOption mkIf;
in
{
  options.antob.services.avahi = {
    enable = mkEnableOption "Avahi";
  };

  config = mkIf cfg.enable {
    services.avahi = {
      enable = true;
      nssmdns4 = true;
      ipv6 = false;
      openFirewall = true;
    };

    antob.persistence.directories = [ "/etc/avahi/services" ];
  };
}
