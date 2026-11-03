{ inputs, config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.base =
    { config, ... }:
    {
      imports = [ inputs.home-manager.nixosModules.home-manager ];

      home-manager = {
        useUserPackages = true;
        useGlobalPkgs = true;
        backupFileExtension = "backup";
        sharedModules = [ homeManager.base ];
        users.${config.antob.user.name} = { };
      };
    };

  flake.modules.homeManager.base =
    { osConfig, ... }:
    {
      home.stateVersion = osConfig.system.stateVersion;
      xdg.enable = true;
      xdg.mimeApps.enable = true;

      # Nicely reload system units when changing configs
      systemd.user.startServices = "sd-switch";
    };
}
