{ pkgs, ... }:
let
  wakeCmd = "sudo etherwake 9c:bf:0d:00:f8:21";
in
pkgs.writeShellScriptBin "wake-desktob" ''
  #!/bin/bash

  set -e
  set -u

  hostname=$(hostname)

  if [[ $hostname == "pidesk" ]]; then
    ${wakeCmd}
  else
    ssh pidesk.antob.net ${wakeCmd}
  fi
''
