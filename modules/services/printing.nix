{
  flake.modules.nixos.printing =
    # Add printer with: `$ lpadmin -p HP -E -v "ipp://192.168.1.120/ipp/print" -m everywhere`
    {
      config,
      pkgs,
      lib,
      ...
    }:

    with lib;
    {
      config = {
        services.printing = {
          enable = true;
          extraConf = ''
            ErrorPolicy retry-job
            DefaultEncryption Never
          '';
        };

        services.colord.enable = true;

        environment.systemPackages = with pkgs; [
          pkgs.system-config-printer
          hplip
        ];

        antob.persistence.directories = [ "/var/lib/cups" ];
      };
    };

}
