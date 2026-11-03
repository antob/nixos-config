{ pkgs, ... }:

pkgs.writeShellScriptBin "cmd-toggle-swayidle" ''
  #!/bin/bash

  STATUS=$(systemctl --user is-active swayidle.service)

  if [[ "$STATUS" == "active" ]]; then
    systemctl --user stop swayidle.service
    notify-send "Stop locking computer when idle"
  else
    systemctl --user start swayidle.service
    notify-send "Now locking computer when idle"
  fi
''
