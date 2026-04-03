{ pkgs, launchPrefix, ... }:

pkgs.writeShellScriptBin "cmd-launch-webapp" ''
  #!/bin/bash

  ${launchPrefix}chromium --app="$1" "''${@:2}"
''
