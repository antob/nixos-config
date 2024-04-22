{ options, config, lib, pkgs, ... }:

with lib;
with lib.antob;
let cfg = config.antob.desktop.addons.keyring;
in {
  options.antob.desktop.addons.keyring = with types; {
    enable = mkEnableOption "Whether to enable the gnome keyring.";
  };

  config = mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = mkForce false;
    antob.home.extraOptions.services.gnome-keyring = {
      enable = true;
      components = [ "pkcs11" "secrets" ];
    };

    environment.systemPackages = with pkgs; [ gnome.seahorse ];
    antob.persistence.home.directories = [ ".local/share/keyrings" ];
  };
}
