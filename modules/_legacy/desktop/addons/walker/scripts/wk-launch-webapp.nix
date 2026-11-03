{ pkgs, launchPrefix, ... }:

pkgs.writeShellScriptBin "wk-launch-webapp" ''
  #!/bin/bash

  ${launchPrefix}chromium --app="$1" "''${@:2}"
''
