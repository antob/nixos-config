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

    # Restart fprintd after resume.
    systemd.services.fprintd-resume-stop = {
      description = "Stop fprintd after resume";
      after = [
        "suspend.target"
        "hibernate.target"
        "suspend-then-hibernate.target"
        "hybrid-sleep.target"
      ];
      wantedBy = [
        "suspend.target"
        "hibernate.target"
        "suspend-then-hibernate.target"
        "hybrid-sleep.target"
      ];
      serviceConfig.Type = "oneshot";
      script = ''
        systemctl stop fprintd.service || true
      '';
    };
  };
}
