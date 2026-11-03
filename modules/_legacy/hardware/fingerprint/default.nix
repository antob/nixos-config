{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.hardware.fingerprint;
in
{
  options.antob.hardware.fingerprint = with types; {
    enable = mkBoolOpt false "Whether or not to enable fingerprint support.";
  };

  config = mkIf cfg.enable {
    antob.persistence.safe.directories = [ "/var/lib/fprint" ];
    services.fprintd.enable = true;

    # Noctalia drives fprintd itself over D-Bus; pam_fprintd in the login
    # stack would stall password unlock for its 30s timeout.
    security.pam.services.login.fprintAuth = false;
  };
}
