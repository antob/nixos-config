{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.keyring =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    {
      config = {
        home-manager.sharedModules = [ homeManager.keyring ];

        services.gnome.gnome-keyring.enable = mkForce false;

        services.dbus.packages = with pkgs; [ gcr_3 ];

        environment.systemPackages = with pkgs; [
          seahorse
          libsecret
        ];

        antob.persistence.safe.home.directories = [ ".local/share/keyrings" ];
      };
    };

  flake.modules.homeManager.keyring =
    { lib, ... }:
    with lib;
    {
      services.gnome-keyring = {
        enable = true;
        components = [
          "pkcs11"
          "secrets"
        ];
      };
    };

}
