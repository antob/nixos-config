{ pkgs, ... }:

pkgs.writeShellScriptBin "dm-librewolf-profile" ''
  # Script name: dm-librewolf-profile
  # Description: Start Librewolf with selected profile..
  # Dependencies: grep, awk, librewolf
  # Contributors: Tobias Lindholm

  # Where to get librewolf profile names
  PROFILES="$HOME/.librewolf/profiles.ini"
  [[ ! -f $PROFILES ]] && exit

  names=$(cat $PROFILES | grep 'Name=' | grep -v 'default' | awk -F '=' '{print $2}')
  choice=$(echo "$names" | ${pkgs.tofi}/bin/tofi --prompt-text 'Open Librewolf profile:') || exit

  if [ -z "$choice" ]; then
    exit 0
  fi

  ${pkgs.librewolf}/bin/librewolf -P $choice &
''
