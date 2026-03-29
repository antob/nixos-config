{ pkgs, lib, ... }:
let
  cmd-screensaver = lib.getExe (pkgs.callPackage ../../scripts/cmd-screensaver.nix { });
  terminal = "${pkgs.alacritty}/bin/alacritty";
in
pkgs.writeShellScriptBin "cmd-launch-screensaver" ''
  #!/bin/bash

  # Exit early if screensave is already running
  pgrep -f "${terminal} --class Screensaver" && exit 0

  focused=$(hyprctl monitors -j | jq -r '.[] | select(.focused == true).name')

  for m in $(hyprctl monitors -j | jq -r '.[] | .name'); do
    hyprctl dispatch focusmonitor $m
    hyprctl dispatch exec -- \
      ${terminal} --class Screensaver \
      --config-file ${../../scripts/screensaver.toml} \
      -e ${cmd-screensaver}
  done

  hyprctl dispatch focusmonitor $focused
''
