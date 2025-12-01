{ pkgs, ... }:
let
  tte = "${pkgs.terminaltexteffects}/bin/tte";
in
pkgs.writeShellScriptBin "cmd-screensaver" ''
  #!/bin/bash

  function exit_screensaver {
    pkill -x .tte-wrapped 2>/dev/null
    pkill -f "alacritty --class Screensaver" 2>/dev/null
    exit 0
  }

  trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT

  while true; do
    effect=$(${tte} 2>&1 | grep -oP '{\K[^}]+' | tr ',' ' ' | tr ' ' '\n' | sed -n '/^beams$/,$p' | sort -u | shuf -n1)
    ${tte} -i ${./branding/logo.txt} \
      --frame-rate 240 --canvas-width 0 --canvas-height $(($(tput lines) - 2)) --anchor-canvas c --anchor-text c \
      "$effect" &

    while pgrep -x .tte-wrapped >/dev/null; do
      if read -t 3 -n 1; then
        exit_screensaver
      fi
    done
  done
''
