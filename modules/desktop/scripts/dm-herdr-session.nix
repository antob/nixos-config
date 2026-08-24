{ pkgs, config, ... }:

pkgs.writeShellScriptBin "dm-herdr-session" ''
  # Script name: dm-herdr-session
  # Description: Select, attach to, or create a Herdr session.
  # Dependencies: rofi, kitty, herdr
  # Contributors: Tobias Lindholm

  # List existing named sessions.
  existing=$(${pkgs.herdr}/bin/herdr session list --json 2>/dev/null | grep -o '"name":"[^"]*"' | sed 's/"name":"//; s/"$//')

  choice=$(echo -e "$existing" | ${pkgs.rofi}/bin/rofi -dmenu -p 'Herdr: ') || exit

  if [ -z "$choice" ]; then
    ${config.antob.desktop.addons.rofi.launchPrefix}kitty herdr &
    exit 0
  fi

  known=$(echo -e "$existing" | grep -qxF "$choice")
  if [ -n "$known" ]; then
    ${config.antob.desktop.addons.rofi.launchPrefix}kitty herdr session attach "$choice" &
    exit 0
  fi

  ${config.antob.desktop.addons.rofi.launchPrefix}kitty herdr --session "$choice" &
''
