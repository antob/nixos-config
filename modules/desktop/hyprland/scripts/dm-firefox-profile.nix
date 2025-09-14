{ pkgs, ... }:

pkgs.writeShellScriptBin "dm-firefox-profile" ''
  # Script name: dm-firefox-profile
  # Description: Start Firefox with selected profile.
  # Dependencies: grep, awk, firefox, uwsm
  # Contributors: Tobias Lindholm

  # Where to get firefox profile names
  PROFILES="$HOME/.mozilla/firefox/profiles.ini"
  [[ ! -f $PROFILES ]] && exit

  names=$(cat $PROFILES | grep 'Name=' | grep -v 'default' | awk -F '=' '{print $2}')
  choice=$(echo "$names" | ${pkgs.walker}/bin/walker --dmenu --theme dmenu_250 -p 'Firefox profiles…') || exit

  if [ -z "$choice" ]; then
    exit 0
  fi

  uwsm app -- firefox -P $choice &
''
