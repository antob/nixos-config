{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
let
  cfg = config.antob.desktop.addons.dms-shell;
in
{
  imports = [ inputs.dms-plugin-registry.modules.default ];

  options.antob.desktop.addons.dms-shell = with types; {
    enable = mkEnableOption "Enable DankMaterialShell.";
  };

  config = mkIf cfg.enable {

    programs.dms-shell = {
      enable = true;

      systemd = {
        enable = true; # Systemd service for auto-start
        restartIfChanged = true; # Auto-restart dms.service when dms-shell changes
      };

      # Core features
      enableSystemMonitoring = true; # System monitoring widgets (dgop)
      # enableVPN = true; # VPN management widget
      # enableDynamicTheming = true; # Wallpaper-based theming (matugen)
      # enableAudioWavelength = true; # Audio visualizer (cava)
      # enableCalendarEvents = true; # Calendar integration (khal)
      enableClipboardPaste = true; # Pasting from the clipboard history (wtype)

      plugins = {
        displayManager.enable = true;
        usbManager.enable = true;
        dmsScreenshot.enable = true;
        emojiLauncher.enable = true;
      };
    };

    environment.systemPackages = with pkgs; [
      swappy
      # wf-recorder
      # grim
      # slurp
      # hyprpicker
      # wl-clipboard
      # tesseract
      # imagemagick
      # zbar
      # curl
      # translate-shell
      # wl-screenrec
      # ffmpeg
      # gifski
      # jq
      # xdg-desktop-portal
    ];

    antob.persistence.home.directories = [
      ".config/DankMaterialShell"
      ".local/state/DankMaterialShell"
      ".cache/DankMaterialShell"
    ];
  };
}
