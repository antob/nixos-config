{ pkgs, lib, ... }:
let
  cmd-blankscreen = lib.getExe (pkgs.callPackage ./cmd-blankscreen.nix { });
  terminal = "${pkgs.alacritty}/bin/alacritty";
in
pkgs.writeShellScriptBin "cmd-launch-blankscreen" ''
  #!/bin/bash

  # Exit early if blankscreen is already running
  pgrep -f "alacritty --class Screensaver" && exit 0

  ${terminal} --class Screensaver --config-file ${./screensaver.toml} -e ${cmd-blankscreen}
''
