{
  flake.modules.nixos.avahi =
    {
      lib,
      config,
      ...
    }:

    let

      inherit (lib) mkEnableOption mkIf;
    in
    {
      config = {
        services.avahi = {
          enable = true;
          nssmdns4 = true;
          ipv6 = false;
          openFirewall = true;
        };

        antob.persistence.directories = [ "/etc/avahi/services" ];
      };
    };

}
