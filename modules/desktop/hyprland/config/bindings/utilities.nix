{
  pkgs,
  lib,
  config,
}:
let
  cmd-screenshot = lib.getExe (pkgs.callPackage ../../../scripts/cmd-screenshot.nix { });
  cmd-toggle-nightlight = lib.getExe (pkgs.callPackage ../../scripts/cmd-toggle-nightlight.nix { });
  cmd-toggle-idle = lib.getExe (pkgs.callPackage ../../scripts/cmd-toggle-idle.nix { });
  dm-keybindings = lib.getExe (pkgs.callPackage ../../scripts/dm-keybindings.nix { });
  dm-system = lib.getExe (pkgs.callPackage ../../scripts/dm-system.nix { inherit config; });
  cmd-lock-screen = lib.getExe (pkgs.callPackage ../../scripts/cmd-lock-screen.nix { });
  lockScreen = config.antob.desktop.addons.hypridle.lockScreen;
  cmd-launch-blankscreen = lib.getExe (
    pkgs.callPackage ../../../scripts/cmd-launch-blankscreen.nix { }
  );
  dm-vpn =
    if config.antob.services.networkd-vpn.enable then
      lib.getExe (pkgs.callPackage ../../../scripts/dm-networkd-vpn.nix { inherit config; })
    else
      lib.getExe (pkgs.callPackage ../../../scripts/dm-nm-vpn.nix { });
in
''
  # Screenshots
  bindd = , PRINT, Screenshot of region, exec, ${cmd-screenshot}
  bindd = SHIFT, PRINT, Screenshot of window, exec, ${cmd-screenshot}
  bindd = CTRL, PRINT, Screenshot of display, exec, ${cmd-screenshot}

  # Color picker
  bindd = SUPER, PRINT, Color picker, exec, pkill hyprpicker || hyprpicker -a

  # Notifications
  bindd = SUPER, PERIOD, Dismiss last notification, exec, makoctl dismiss
  bindd = SUPER SHIFT, PERIOD, Dismiss all notifications, exec, makoctl dismiss --all
  bindd = SUPER CTRL, PERIOD, Toggle silencing notifications, exec, makoctl mode -t do-not-disturb && makoctl mode | grep -q 'do-not-disturb' && notify-send "Silenced notifications" || notify-send "Enabled notifications"

  # Toggle nightlight
  bindd = SUPER CTRL, N, Toggle nightlight, exec, ${cmd-toggle-nightlight}

  # Toggle idling
  bindd = SUPER, U, Toggle locking on idle, exec, ${cmd-toggle-idle}

  # Lock screen
  bindd = SUPER, L, Lock screen, exec, ${
    if lockScreen then "${cmd-lock-screen}" else "${cmd-launch-blankscreen}"
  }

  # Menus
  bindd = SUPER, D, Launch apps, exec, ${pkgs.rofi}/bin/rofi -show drun
  bindd = SUPER CTRL, E, Emoji picker, exec, rofimoji --prompt Emojis --action copy
  bindd = SUPER, K, Show key bindings, exec, ${dm-keybindings}
  bindd = SUPER, X, Show system menu, exec, ${dm-system}
  bindd = SUPER, P, Show VPN menu, exec, ${dm-vpn}
''
