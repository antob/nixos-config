{ pkgs, ... }:

pkgs.writeShellScriptBin "getsong" ''
  #!/bin/bash
  set -e
  set -u
  set -o pipefail

  exec ${pkgs.yt-dlp}/bin/yt-dlp -f bestaudio -o '%(title)s.%(ext)s' "$@"
''
