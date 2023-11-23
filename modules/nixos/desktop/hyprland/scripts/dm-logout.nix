{ pkgs, ... }:

pkgs.writeShellScriptBin "dm-logout" ''
  # An array of options to choose.
  declare -a options=(
  "Suspend"
  "Hibernate"
  "Reboot"
  "Shutdown"
  "Logout"
  "Lock screen"
  )

  # Piping the above array into tofi.
  # We use "printf '%s\n'" to format the array one item to a line.
  choice=$(printf '%s\n' "''${options[@]}" | ${pkgs.tofi}/bin/tofi --prompt-text 'Shutdown menu:')


  # What to do when/if we choose one of the options.
  case $choice in
      'Logout')
          ${pkgs.hyprland}/bin/hyprctl dispatch exit
          ;;
      'Lock screen')
          ;;
      'Reboot')
          systemctl -i reboot 
          ;;
      'Shutdown')
          systemctl -i poweroff 
          ;;
      'Suspend')
          systemctl -i suspend
          # swaylock
          ;;
      'Hibernate')
          systemctl -i suspend
          # swaylock
          ;;
      *)
          exit 0
          ;;
  esac
''
