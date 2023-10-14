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

  # Piping the above array into dmenu.
  # We use "printf '%s\n'" to format the array one item to a line.
  choice=$(printf '%s\n' "''${options[@]}" | ${pkgs.dmenu}/bin/dmenu -i -p 'Shutdown menu:' "$@")


  # What to do when/if we choose one of the options.
  case $choice in
      'Logout')
          #pkill X
          ${pkgs.xfce.xfce4-session}/bin/xfce4-session-logout --fast --logout
          ;;
      'Lock screen')
          ${pkgs.xfce.xfce4-session}/bin/xflock4
          ;;
      'Reboot')
          ${pkgs.xfce.xfce4-session}/bin/xfce4-session-logout --reboot
          ;;
      'Shutdown')
          ${pkgs.xfce.xfce4-session}/bin/xfce4-session-logout --halt
          ;;
      'Suspend')
          ${pkgs.xfce.xfce4-session}/bin/xfce4-session-logout --suspend
          ;;
      'Hibernate')
          ${pkgs.xfce.xfce4-session}/bin/xfce4-session-logout --hibernate
          ;;
      *)
          exit 0
          ;;
  esac
''
