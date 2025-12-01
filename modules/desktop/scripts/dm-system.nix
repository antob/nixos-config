{
  pkgs,
  lib,
  config,
  ...
}:
let
  lockScreen = config.antob.desktop.addons.swayidle.lockScreen;
  cmd-launch-blankscreen = lib.getExe (pkgs.callPackage ./cmd-launch-blankscreen.nix { });
in
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

  case $(menu "System" "  Lock\n󱄄  Screensaver\n󰤄  Suspend\n󰜉  Reboot\n󰍛  Reboot to FW\n󰐥  Shutdown") in
    *Lock*) ${
      if lockScreen then
        "loginctl lock-session && ${pkgs.wlr-dpms}/bin/wlr-dpms off"
      else
        "${cmd-launch-blankscreen}"
    } ;;
    *Screensaver*) cmd-launch-screensaver ;;
    *Suspend) systemctl suspend ;;
    *Reboot) systemctl reboot ;;
    *Reboot\ to\ FW*) systemctl reboot --firmware-setup ;;
    *Shutdown*) systemctl -- poweroff ;;
    *) exit 0 ;;
  esac
''
