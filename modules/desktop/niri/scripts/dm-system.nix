{ pkgs, ... }:
pkgs.writeShellScriptBin "dm-system" ''
  #!/bin/bash

  menu() {
    local prompt="$1"
    local options="$2"
    local extra="$3"
    local preselect="$4"

    read -r -a args <<<"$extra"

    if [[ -n "$preselect" ]]; then
      local index
      index=$(echo -e "$options" | grep -nxF "$preselect" | cut -d: -f1)
      if [[ -n "$index" ]]; then
        args+=("-a" "$index")
      fi
    fi

    echo -e "$options" | walker --dmenu --theme dmenu_250 -p "$prompt…" "''${args[@]}"
  }

  case $(menu "System" "  Lock\n󰤄  Suspend\n󰜉  Reboot\n󰍛  Reboot to FW\n󰐥  Shutdown") in
    *Lock*) loginctl lock-session && niri msg action power-off-monitors ;;
    *Suspend) systemctl suspend ;;
    *Reboot) systemctl reboot ;;
    *Reboot\ to\ FW*) systemctl reboot --firmware-setup ;;
    *Shutdown*) systemctl -- poweroff ;;
    *) exit 0 ;;
  esac
''
