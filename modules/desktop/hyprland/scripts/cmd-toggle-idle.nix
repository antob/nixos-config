{ pkgs, ... }:

pkgs.writeShellScriptBin "cmd-toggle-idle" ''
  #!/bin/bash

  if pgrep -x hypridle >/dev/null; then
    systemctl --user stop hypridle.service
    notify-send "Stop locking computer when idle"
  else
    systemctl --user start hypridle.service
    notify-send "Now locking computer when idle"
  fi
''
