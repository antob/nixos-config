{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.virtualisation.virt-manager;
in
{
  options.antob.virtualisation.virt-manager = with types; {
    enable = mkEnableOption "Whether or not to enable virt-manager.";
  };

  config = mkIf cfg.enable {
    virtualisation.libvirtd.enable = true;
    programs.virt-manager.enable = true;
    antob.user.extraGroups = [ "libvirtd" ];
    antob.home.extraOptions.dconf.settings = {
      "org/virt-manager/virt-manager/connections" = {
        autoconnect = [ "qemu:///system" ];
        uris = [ "qemu:///system" ];
      };
    };
  };
}
