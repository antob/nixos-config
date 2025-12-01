{ pkgs, lib, ... }:
let
  cmd-screensaver = lib.getExe (pkgs.callPackage ../../scripts/cmd-screensaver.nix { });
in
pkgs.writeShellScriptBin "cmd-launch-screensaver" ''
  #!/bin/bash

  # Exit early if screensave is already running
  pgrep -f "alacritty --class Screensaver" && exit 0

  focused=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')

  for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
    hyprctl dispatch focusmonitor $m
    hyprctl dispatch exec -- \
      alacritty --class Screensaver \
      --config-file ${../../scripts/screensaver.toml} \
      -e ${cmd-screensaver}
  done

  hyprctl dispatch focusmonitor $focused
''
