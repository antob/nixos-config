{ pkgs, ... }:

pkgs.writeShellScriptBin "mic-cam-usage" ''
  # Script name: mic-cam-usage
  # Description: Detect mic and cam usage
  # Dependencies: fuser, pactl
  # Contributors: Tobias Lindholm

  webcam_status=$(${pkgs.psmisc}/bin/fuser /dev/video[0-6] 2>/dev/null)

  if [ -z "$webcam_status" ]; then
    webcam=""
  else
    webcam="󰄀"
  fi

  current_source=$(${pkgs.pulseaudio}/bin/pactl info | ${pkgs.gnugrep}/bin/grep "Default Source" | ${pkgs.coreutils}/bin/cut -f3 -d" ")
  mic_status=$(${pkgs.pulseaudio}/bin/pactl list sources | ${pkgs.gnugrep}/bin/grep -B 2 $current_source | ${pkgs.gnugrep}/bin/grep RUNNING)

  if [ -z "$mic_status" ]; then
      mic=""
  else
      mic=""
  fi

  echo "$webcam $mic"
''
