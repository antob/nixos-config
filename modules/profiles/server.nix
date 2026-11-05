{ config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.server =
    { lib, pkgs, ... }:
    {
      imports = with nixos; [
        shell
        env
        console
        yazi
        gpg
      ];

      environment.systemPackages = with pkgs; [
        dmidecode
        gnumake
        nvd
        witr
        bun
        nmap
        arp-scan
      ];

      services = {
        upower.enable = true;
        dbus.enable = true;
      };

      # Bootloader.
      boot.loader = {
        systemd-boot = {
          enable = lib.mkDefault true;
          consoleMode = "max";
          configurationLimit = 10;
          editor = false;
        };

        efi = {
          canTouchEfiVariables = true;
          efiSysMountPoint = "/efi";
        };
      };
    };
}
