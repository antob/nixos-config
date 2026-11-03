{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.virt-manager =
    {
      config,
      lib,
      ...
    }:

    with lib;
    {
      config = {
        home-manager.sharedModules = [ homeManager.virt-manager ];

        virtualisation.libvirtd.enable = true;
        programs.virt-manager.enable = true;
        antob.user.extraGroups = [ "libvirtd" ];
      };
    };

  flake.modules.homeManager.virt-manager =
    { lib, ... }:
    with lib;
    {
      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };
    };

}
