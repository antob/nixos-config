{
  pkgs,
  # Private key pidesk uses to log in to desktob (only authorised for wake-desktob-guard)
  keyFile ? "/run/secrets/desktob_wake_key",
  ...
}:
let
  wakeCmd = "sudo etherwake 9c:bf:0d:00:f8:21";
  desktob = "desktob.antob.net";
in
pkgs.writeShellScriptBin "wake-desktob" ''
  #!/bin/bash

  set -e
  set -u

  # Everything below runs on pidesk, so only one YubiKey touch is needed from elsewhere
  if [[ $(hostname) != "pidesk" ]]; then
    echo "Touch the YubiKey (pidesk)..."
    exec timeout 300 ssh pidesk.antob.net wake-desktob
  fi

  ${wakeCmd}

  # Wait for sshd on desktob
  echo "Waiting for ${desktob}..."
  up=
  SECONDS=0
  while (( SECONDS < 180 )); do
    if timeout 2 bash -c 'exec 3<>/dev/tcp/${desktob}/22' 2>/dev/null; then
      up=1
      break
    fi
    sleep 1
  done

  if [[ -z $up ]]; then
    echo "${desktob} did not come up within 3 minutes" >&2
    exit 1
  fi

  # Display off and suspend blocked until the first keypress on desktob.
  # The key is restricted on desktob to running wake-desktob-guard start.
  timeout 60 ssh -l "$USER" \
    -i ${keyFile} -o IdentitiesOnly=yes -o IdentityAgent=none \
    -o BatchMode=yes -o ControlPath=none -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=accept-new \
    ${desktob} wake-desktob-guard start
  echo "${desktob} is awake with the display off. First keypress there restores both."
''
