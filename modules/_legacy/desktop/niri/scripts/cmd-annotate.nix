{ pkgs, ... }:

pkgs.writeShellScriptBin "cmd-annotate" ''
  #!/bin/bash

  set -e;

  [[ -f ~/.config/user-dirs.dirs ]] && source ~/.config/user-dirs.dirs
  OUTPUT_DIR="''${SCREENSHOT_DIR:-''${XDG_PICTURES_DIR:-$HOME/Pictures/Screenshots}}"

  if [[ ! -d "$OUTPUT_DIR" ]]; then
    notify-send "Screenshot directory does not exist: $OUTPUT_DIR" -u critical -t 3000
    exit 1
  fi

  wl-paste | ${pkgs.satty}/bin/satty --filename - \
      --output-filename "$OUTPUT_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png" \
      --early-exit \
      --actions-on-enter save-to-clipboard \
      --save-after-copy \
      --initial-tool rectangle
      --disable-notifications
      --copy-command 'wl-copy'
''
