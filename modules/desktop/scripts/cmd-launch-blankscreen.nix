{ pkgs, lib, ... }:
let
  cmd-blankscreen = lib.getExe (pkgs.callPackage ./cmd-blankscreen.nix { });
in
pkgs.writeShellScriptBin "cmd-launch-blankscreen" ''
  #!/bin/bash

  # Exit early if blankscreen is already running
  pgrep -f "alacritty --class Screensaver" && exit 0

  alacritty --class Screensaver --config-file ${./screensaver.toml} -e ${cmd-blankscreen}
''
