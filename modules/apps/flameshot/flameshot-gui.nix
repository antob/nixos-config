{ pkgs, ... }:

pkgs.writeShellScriptBin "flameshot-gui" ''
  # Script name: flameshot-gui
  # Description: Starts Flameshot in GUI mode

  bash -c -- "${pkgs.flameshot}/bin/flameshot gui"
''
