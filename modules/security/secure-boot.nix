{ inputs, ... }:
{
  flake.modules.nixos.secure-boot =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    {
      imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

      config = {
        environment.systemPackages = [
          pkgs.sbctl
        ];

        # Lanzaboote currently replaces the systemd-boot module.
        boot.loader.systemd-boot.enable = lib.mkForce false;

        boot.lanzaboote = {
          enable = true;
          pkiBundle = "/var/lib/sbctl";
        };

        antob.persistence.safe.directories = [
          "/var/lib/sbctl"
        ];
      };
    };

}
