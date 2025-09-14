{ pkgs, ... }:

pkgs.writeShellScriptBin "cmd-toggle-nightlight" ''
  #!/bin/bash

  # Default temperature values
  ON_TEMP=4000
  OFF_TEMP=6000

  # Query the current temperature
  CURRENT_TEMP=$(hyprctl hyprsunset temperature 2>/dev/null | grep -oE '[0-9]+')

  if [[ "$CURRENT_TEMP" == "$OFF_TEMP" ]]; then
    hyprctl hyprsunset temperature $ON_TEMP
    hyprctl hyprsunset gamma 80
    notify-send "  Nightlight screen temperature"
  else
    hyprctl hyprsunset temperature $OFF_TEMP
    hyprctl hyprsunset gamma 100
    notify-send "   Daylight screen temperature"
  fi
''
