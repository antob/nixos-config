{ config, lib, ... }:

with lib;

let
  mkOpt = type: default: description:
    mkOption { inherit type default description; };
  mkBoolOpt = mkOpt types.bool;

  cfg = config.host.system.locale;

in {
  options.host.system.locale = with types; {
    enable = mkBoolOpt false "Whether or not to manage locale settings.";
  };

  config = mkIf cfg.enable {
    i18n = {
      defaultLocale = "en_US.UTF-8";

      extraLocaleSettings = {
        LC_ADDRESS = "sv_SE.UTF-8";
        LC_IDENTIFICATION = "sv_SE.UTF-8";
        LC_MEASUREMENT = "sv_SE.UTF-8";
        LC_MONETARY = "sv_SE.UTF-8";
        LC_NAME = "sv_SE.UTF-8";
        LC_NUMERIC = "sv_SE.UTF-8";
        LC_PAPER = "sv_SE.UTF-8";
        LC_TELEPHONE = "sv_SE.UTF-8";
        LC_TIME = "sv_SE.UTF-8";
      };
    };

    console = { keyMap = mkForce "us"; };
    # console = { keyMap = mkForce "sv-latin1"; };
  };
}
