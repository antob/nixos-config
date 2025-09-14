{ pkgs, ... }:

pkgs.writeShellScriptBin "mic-cam-usage" ''
  # Script name: mic-cam-usage
  # Description: Detect mic and cam usage
  # Dependencies: fuser, pactl
  # Contributors: Tobias Lindholm

  webcam_status=$(${pkgs.psmisc}/bin/fuser /dev/video[0-6])

  if [ -z "$webcam_status" ]; then
    webcam=""
  else
    webcam="󰄀"
  fi

  mic_status=$(${pkgs.pulseaudio}/bin/pactl list sources | grep RUNNING)

  if [ -z "$mic_status" ]; then
      mic=""
  else
      mic=""
  fi

  echo "$webcam $mic"
''
