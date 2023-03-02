{ options, config, pkgs, lib, inputs, ... }:

with lib;
let cfg = config.antob.home;
in
{
  imports = with inputs; [
    home-manager.nixosModules.home-manager
  ];

  options.antob.home = with types; {
    file = mkOpt attrs { }
      "A set of files to be managed by home-manager's <option>home.file</option>.";
    configFile = mkOpt attrs { }
      "A set of files to be managed by home-manager's <option>xdg.configFile</option>.";
    extraOptions = mkOpt attrs { } "Options to pass directly to home-manager.";
  };

  config = {
    antob.home.extraOptions = {
      home.stateVersion = config.system.stateVersion;
      home.file = mkAliasDefinitions options.antob.home.file;
      xdg.enable = true;
      xdg.configFile = mkAliasDefinitions options.antob.home.configFile;

      # Nicely reload system units when changing configs
      systemd.user.startServices = "sd-switch";
    };

    home-manager = {
      useUserPackages = true;
      useGlobalPkgs = true;

      users.${config.antob.user.name} =
        mkAliasDefinitions options.antob.home.extraOptions;
    };
  };
}

