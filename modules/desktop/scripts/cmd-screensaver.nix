{ pkgs, ... }:
let
  tte = "${pkgs.terminaltexteffects}/bin/tte";
  terminal = "${pkgs.alacritty}/bin/alacritty";
in
pkgs.writeShellScriptBin "cmd-screensaver" ''
  #!/bin/bash

  function exit_screensaver {
    pkill -x .tte-wrapped 2>/dev/null
    pkill -f "${terminal} --class Screensaver" 2>/dev/null
    exit 0
  }

  trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT

  while true; do
    ${tte} -i ${./branding/logo.txt} -R \
      --frame-rate 240 --canvas-width 0 --canvas-height $(($(tput lines) - 2)) --anchor-canvas c --anchor-text c &

    while pgrep -x .tte-wrapped >/dev/null; do
      if read -t 3 -n 1; then
        exit_screensaver
      fi
    done
  done
''
