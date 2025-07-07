{ pkgs, ... }:

pkgs.writeShellScriptBin "check-kbd-variant" ''
  # Script name: check-kbd-variant
  # Description: Check if actvie keyboard variant is US or SE.
  # Dependencies: setxkbdmap
  # Contributors: Tobias Lindholm

  ${pkgs.xorg.setxkbmap}/bin/setxkbmap -query | ${pkgs.gnugrep}/bin/grep -q '[^,]us' && echo 'US' || echo 'SE'
''
