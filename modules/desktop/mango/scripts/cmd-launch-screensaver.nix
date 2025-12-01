{ pkgs, lib, ... }:
let
  cmd-screensaver = lib.getExe (pkgs.callPackage ../../scripts/cmd-screensaver.nix { });
in
pkgs.writeShellScriptBin "cmd-launch-screensaver" ''
  #!/bin/bash

  # Exit early if screensave is already running
  pgrep -f "alacritty --class Screensaver" && exit 0

  for m in $(mmsg -O); do
    mmsg -o $m -d spawn,"alacritty --class Screensaver --config-file ${../../scripts/screensaver.toml} -e ${cmd-screensaver}"
  done
''
