{ pkgs, ... }:

pkgs.writeShellScriptBin "cmd-launch-webapp" ''
  #!/bin/bash

  exec setsid uwsm app -- chromium --app="$1" "''${@:2}"
''
