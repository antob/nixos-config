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

    # environment.systemPackages = with pkgs; [
    # ];

    antob.system.env = {
      MOZ_ENABLE_WAYLAND = "1";
    };
  };
}
