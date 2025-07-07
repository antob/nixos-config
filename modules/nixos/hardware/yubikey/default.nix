{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.hardware.yubikey;

  reload-yubikey = pkgs.writeShellScriptBin "reload-yubikey" ''
    ${pkgs.gnupg}/bin/gpg-connect-agent "scd serialno" "learn --force" /bye
  '';
in
{
  options.antob.hardware.yubikey = with types; {
    enable = mkBoolOpt false "Whether or not to enable yubikey support.";
  };

  config = mkIf cfg.enable {
    services.udev.packages = with pkgs; [ yubikey-personalization ];
    environment.systemPackages = [
      reload-yubikey
    ];

    services.udev.extraRules = ''
      # Autosuspend Yubikey
      ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{idVendor}=="1050", ATTR{idProduct}=="0406", ATTR{power/control}="auto"
    '';

    antob.home.extraOptions = {
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
  };
}
