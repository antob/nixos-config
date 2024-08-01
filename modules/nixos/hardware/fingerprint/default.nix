{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.hardware.fingerprint;
in
{
  options.antob.hardware.fingerprint = with types; {
    enable = mkBoolOpt false "Whether or not to enable fingerprint support.";
  };

  config = mkIf cfg.enable {
    antob.persistence.directories = [ "/var/lib/fprint" ];
    services.fprintd.enable = true;
  };
}
