{ options, config, pkgs, lib, ... }:

with lib;
let cfg = config.host.hardware.fingerprint;
in {
  options.host.hardware.fingerprint = with types; {
    enable = mkOption {
      type = bool;
      default = false;
      description = "Whether or not to enable fingerprint support.";
    };
  };

  config = mkIf cfg.enable { services.fprintd.enable = true; };
}
