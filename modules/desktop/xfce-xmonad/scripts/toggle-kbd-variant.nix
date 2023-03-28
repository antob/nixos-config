{ pkgs, ... }:

pkgs.writeShellScriptBin "toggle-kbd-variant" ''
  # Script name: toggle-kbd-variant
  # Description: Toggle between US and SE keyboard variants.
  # Dependencies: setxkbdmap
  # Contributors: Tobias Lindholm

  ${pkgs.xorg.setxkbmap}/bin/setxkbmap -query | grep -q '[^,]us' && ${pkgs.xorg.setxkbmap}/bin/setxkbmap -layout se || ${pkgs.xorg.setxkbmap}/bin/setxkbmap -layout se -variant us
''
