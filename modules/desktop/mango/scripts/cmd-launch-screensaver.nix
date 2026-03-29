{ pkgs, lib, ... }:
let
  cmd-screensaver = lib.getExe (pkgs.callPackage ../../scripts/cmd-screensaver.nix { });
  terminal = "${pkgs.alacritty}/bin/alacritty";
in
pkgs.writeShellScriptBin "cmd-launch-screensaver" ''
  #!/bin/bash

  # Exit early if screensave is already running
  pgrep -f "${terminal} --class Screensaver" && exit 0

  for m in $(mmsg -O); do
    mmsg -o $m -d spawn,"${terminal} --class Screensaver --config-file ${../../scripts/screensaver.toml} -e ${cmd-screensaver}"
  done
''
