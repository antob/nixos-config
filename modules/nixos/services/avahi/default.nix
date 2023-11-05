{ lib, config, options, ... }:

let
  cfg = config.antob.services.avahi;

  inherit (lib) types mkEnableOption mkIf;
in
{
  options.antob.services.avahi = with types; {
    enable = mkEnableOption "Avahi";
  };

  config = mkIf cfg.enable {
    services.avahi = {
      enable = true;
      nssmdns = true;
      openFirewall = true;
    };
  };
}
