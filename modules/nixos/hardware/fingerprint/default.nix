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

    # Fix not being able to use fingerprint i GDM
    security.pam.services.gdm-fingerprint.text = mkForce ''
      auth       required                    pam_shells.so
      auth       requisite                   pam_nologin.so
      auth       requisite                   pam_faillock.so      preauth
      auth       required                    ${pkgs.fprintd}/lib/security/pam_fprintd.so
      auth       optional                    pam_permit.so
      auth       required                    pam_env.so
      auth       [success=ok default=ignore] ${pkgs.gnome.gdm}/lib/security/pam_gdm.so

      account    include                     login

      password   required                    pam_deny.so

      session    include                     login
    '';
  };
}
