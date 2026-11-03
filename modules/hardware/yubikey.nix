{ config, ... }:
let
  inherit (config.aspects) homeManager;
in
{
  flake.modules.nixos.yubikey =
    {
      config,
      pkgs,
      lib,
      ...
    }:

    with lib;
    let

      reload-yubikey = pkgs.writeShellScriptBin "reload-yubikey" ''
        ${pkgs.gnupg}/bin/gpg-connect-agent "scd serialno" "learn --force" /bye
      '';
    in
    {
      config = {
        home-manager.sharedModules = [ homeManager.yubikey ];

        services.udev.packages = with pkgs; [ yubikey-personalization ];
        environment.systemPackages = [
          reload-yubikey
          pkgs.yubikey-manager
        ];

        services.udev.extraRules = ''
          # Autosuspend Yubikey
          ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{idVendor}=="1050", ATTR{idProduct}=="0406", ATTR{power/control}="auto"
        '';

      };
    };

  flake.modules.homeManager.yubikey =
    { lib, pkgs, ... }:
    with lib;
    {
      systemd.user.services.yubikey-touch-detector = {
        Unit = {
          Description = "Detects when your YubiKey is waiting for a touch";
        };

        Service = {
          ExecStart = "${pkgs.yubikey-touch-detector}/bin/yubikey-touch-detector --libnotify";
          EnvironmentFile = "-%E/yubikey-touch-detector/service.conf";
        };

        # Install = { WantedBy = [ "default.target" ]; };
      };

      # Start the detector with a delay, otherwise it eats CPU for some reason..
      systemd.user.timers.yubikey-touch-detector = {
        Timer = {
          OnActiveSec = "30s";
        };
        Install = {
          WantedBy = [ "timers.target" ];
        };
      };
    };

}
