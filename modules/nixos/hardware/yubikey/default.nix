{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
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
    environment.systemPackages = with pkgs; [ reload-yubikey ];

    services.udev.extraRules = ''
      # Autosuspend Yubikey
      ACTION=="add", SUBSYSTEM=="usb", TEST=="power/control", ATTR{idVendor}=="1050", ATTR{idProduct}=="0406", ATTR{power/control}="auto"
    '';
  };
}
