{ pkgs, ... }:

pkgs.writeShellScriptBin "timer" ''
  #!/bin/bash

  msg='󰀠   Timer complete'
  if [[ -n "$2" ]]; then
    msg="󰀠   $2"
  fi

  sleep "$1"
  sfx ringaling
  ${pkgs.libnotify}/bin/notify-send -t 0 "$msg"
''
