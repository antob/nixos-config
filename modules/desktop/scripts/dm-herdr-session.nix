{ pkgs, ... }:
let
  kittyCmd = "${pkgs.kitty}/bin/kitty --config $HOME/.config/kitty/kitty-no-bindings.conf";
in
pkgs.writeShellScriptBin "dm-herdr-session" /* bash */ ''
  # Script name: dm-herdr-session
  # Description: Select, attach to, or create a Herdr session.
  # Dependencies: rofi, kitty, herdr
  # Contributors: Tobias Lindholm

  existing=$(${pkgs.herdr}/bin/herdr session list --json 2>/dev/null | grep -o '"name":"[^"]*"' | sed 's/"name":"//; s/"$//')
  choice=$(echo -e "$existing" | ${pkgs.rofi}/bin/rofi -dmenu -p 'Herdr: ') || exit
  ${kittyCmd} herdr --session "$choice" &
''
