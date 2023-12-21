{ pkgs, ... }:

pkgs.writeShellScriptBin "sleep" ''
    # Script name: sleep
    # Contributors: Tobias Lindholm

  ${pkgs.swayidle}/bin/swayidle -w \
    lock swaylock \
    before-sleep swaylock \
    timeout 300 'swaylock -f' \
    timeout 600 'hyprctl dispatch dpms off' \
    resume 'hyprctl dispatch dpms on' \
    timeout 900 'systemctl suspend'
''
