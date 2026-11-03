{
  config,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.cosmic;
in
{
  options.antob.desktop.cosmic = with types; {
    enable = mkEnableOption "Enable Cosmic Desktop.";
  };

  config = mkIf cfg.enable {
    services.displayManager.cosmic-greeter.enable = true;
    services.desktopManager.cosmic.enable = true;
    services.displayManager.autoLogin = {
      enable = true;
      user = config.antob.user.name;
    };

    services.system76-scheduler.enable = true;

    antob.persistence.home.directories = [
      ".config/cosmic"
    ];
  };
}
