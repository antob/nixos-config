{ pkgs, ... }:

pkgs.writeShellScriptBin "toggle-laptop-display" ''
  # Script name: toggle-laptop-display
  # Description: Toggle display eDP-1 on and off
  # Contributors: Tobias Lindholm

  enabled=$(${pkgs.hyprland}/bin/hyprctl monitors | grep 'eDP-1')

  if [ -z "$enabled" ]; then
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1, highres, 0x0, 1.5"
  else
    ${pkgs.hyprland}/bin/hyprctl keyword monitor "eDP-1, disable"
  fi
''
