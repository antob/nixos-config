{ pkgs, ... }:

pkgs.writeShellScriptBin "sfx" ''
  #!/bin/bash

  set -e
  set -u
  set -o pipefail

  exec ${pkgs.mpv}/bin/mpv --really-quiet --no-video "${./sfx}/$1.ogg" &
''
