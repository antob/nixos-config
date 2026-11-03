{
  flake.modules.nixos.cosmic =
    {
      config,
      lib,
      ...
    }:

    {
      config = {
        services = {
          displayManager.cosmic-greeter.enable = true;

          desktopManager.cosmic.enable = true;

          displayManager.autoLogin = {
            enable = true;
            user = config.antob.user.name;
          };

          system76-scheduler.enable = true;
        };

        antob.persistence.home.directories = [
          ".config/cosmic"
        ];
      };
    };

}
