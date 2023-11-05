{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.services.printing;
in {
  options.antob.services.printing = with types; {
    enable = mkEnableOption "Whether or not to configure printing support.";
  };

  config = mkIf cfg.enable {
    services.printing.enable = true;

    environment.systemPackages = with pkgs; [
      pkgs.system-config-printer
      hplip
    ];

    antob.persistence.directories = [ "/etc/cups" ];
  };
}
