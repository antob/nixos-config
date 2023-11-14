{ pkgs, ... }:

pkgs.writeShellScriptBin "wcwd" ''
  # Script name: wcwd
  # Description: Outputs working directory of current window. Hyprland version of xcwd.
  # Dependencies: setxkbdmap
  # Contributors: Tobias Lindholm

  pid=$(${pkgs.hyprland}/bin/hyprctl -j activewindow | jq '.pid')
  ppid=$(${pkgs.procps}/bin/pgrep --newest --parent $pid)
  readlink /proc/$ppid/cwd || echo $HOME
''
