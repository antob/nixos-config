{ inputs, config, ... }:
let
  inherit (config.aspects) homeManager nixos;
in
{
  flake.modules.nixos.rpi =
    { lib, pkgs, ... }:
    {
      imports = [ nixos.shell ];

      # Stylix master targets newer nixpkgs than nixos-raspberrypi's.
      disabledModules = map (m: "${inputs.stylix}/modules/${m}/nixos.nix") [
        "kmscon"
        "regreet"
      ];

      config = {
        home-manager.sharedModules = [ homeManager.rpi ];

        environment.systemPackages = with pkgs; [
          impala
          libraspberrypi
          raspberrypi-eeprom
        ];

        stylix.enableReleaseChecks = false;
        nix.settings.filter-syscalls = false;
        documentation.enable = lib.mkDefault false;

        # Bootloader.
        boot = {
          loader.systemd-boot.enable = false;
          zfs.forceImportRoot = false;
          supportedFilesystems.zfs = false;
        };
      };
    };

  flake.modules.homeManager.rpi = {
    home.enableNixpkgsReleaseCheck = false;
  };
}
