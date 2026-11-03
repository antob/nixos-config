{
  flake.modules.nixos.fingerprint =
    {
      config,
      lib,
      ...
    }:

    {
      config = {
        antob.persistence.safe.directories = [ "/var/lib/fprint" ];
        services.fprintd.enable = true;

        # Noctalia drives fprintd itself over D-Bus; pam_fprintd in the login
        # stack would stall password unlock for its 30s timeout.
        security.pam.services.login.fprintAuth = false;
      };
    };

}
