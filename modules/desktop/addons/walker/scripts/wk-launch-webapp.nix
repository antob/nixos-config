{ pkgs, ... }:

pkgs.writeShellScriptBin "wk-launch-webapp" ''
  #!/bin/bash

  exec setsid uwsm app -- chromium --app="$1" "''${@:2}"
''
