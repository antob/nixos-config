{ pkgs, ... }:

pkgs.writeShellScriptBin "cmd-lock-screen" ''
  #!/bin/bash

  # Lock the screen
  pidof hyprlock || hyprlock &

  # Avoid running screensaver when locked
  pkill -f "alacritty --class Screensaver"
''
