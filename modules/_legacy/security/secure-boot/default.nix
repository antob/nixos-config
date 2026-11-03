{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.security.secure-boot;
in
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  options.antob.security.secure-boot = with types; {
    enable = mkEnableOption "Whether or not to enable Secure Boot.";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.sbctl
    ];

    # Lanzaboote currently replaces the systemd-boot module.
    boot.loader.systemd-boot.enable = lib.mkForce false;

    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    antob.persistence.safe.directories = [
      "/var/lib/sbctl"
    ];
  };
}
