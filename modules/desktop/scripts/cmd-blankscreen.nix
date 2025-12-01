{ pkgs, ... }:
pkgs.writeShellScriptBin "cmd-blankscreen" ''
  #!/bin/bash

  function exit_script {
    ${pkgs.wlr-dpms}/bin/wlr-dpms on
    exit 0
  }

  trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT

  ${pkgs.wlr-dpms}/bin/wlr-dpms off

  while true; do
    if read -t 3 -n 1; then
      exit_script
    fi
  done
''
