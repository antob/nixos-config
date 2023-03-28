{ options, config, lib, pkgs, ... }:

with lib;
let cfg = config.antob.desktop.addons.keyring;
in {
  options.antob.desktop.addons.keyring = with types; {
    enable = mkEnableOption "Whether to enable the gnome keyring.";
  };

  config = mkIf cfg.enable {
    services.gnome.gnome-keyring.enable = true;

    environment.systemPackages = with pkgs; [ gnome.seahorse ];
  };
}
