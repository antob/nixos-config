{ pkgs, ... }:
pkgs.writeShellScriptBin "dm-herdr-session" /* bash */ ''
  # Script name: dm-herdr-session
  # Description: Select, attach to, or create a Herdr session.
  # Dependencies: rofi, kitty, herdr-kitty
  # Contributors: Tobias Lindholm

  existing=$(${pkgs.herdr}/bin/herdr session list --json 2>/dev/null | grep -o '"name":"[^"]*"' | sed 's/"name":"//; s/"$//')
  choice=$(echo -e "$existing" | ${pkgs.rofi}/bin/rofi -dmenu -p 'Herdr: ') || exit
  herdr-kitty --session "$choice" &
''
