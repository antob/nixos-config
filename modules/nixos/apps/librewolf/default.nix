{ options, config, pkgs, lib, ... }:

with lib;
with lib.antob;
let cfg = config.antob.apps.librewolf;
in {
  options.antob.apps.librewolf = with types; {
    enable = mkEnableOption "Enable Librewolf";
  };

  config = mkIf cfg.enable {
    antob = {
      home.extraOptions.programs.librewolf = {
        enable = true;
        settings = {
          "privacy.clearOnShutdown.history" = false;
          "privacy.clearOnShutdown.downloads" = false;
          "browser.sessionstore.resume_from_crash" = true;
          "privacy.sanitize.sanitizeOnShutdown" = false;
          "webgl.disabled" = false;
        };
      };

      persistence.home.directories = [ ".librewolf" ];
    };
  };
}
