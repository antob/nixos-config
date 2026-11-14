{ pkgs, ... }:
# Runs on desktob (called over SSH by wake-desktob). Keeps the display off and
# suspend blocked (logind inhibitor) until the first keyboard input on desktob.
pkgs.writeShellScriptBin "wake-desktob-guard" ''
  set -u

  # A forced SSH command may start with a minimal environment
  export PATH=/run/current-system/sw/bin:$PATH
  export XDG_RUNTIME_DIR="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"

  unit=wake-desktob-guard

  case "''${1:-}" in
    start)
      systemctl --user stop "$unit.service" 2>/dev/null || true

      # The unit inherits the user manager's environment (WAYLAND_DISPLAY),
      # which noctalia msg needs and a plain SSH session lacks.
      # RuntimeMaxSec bounds a forgotten guard, ExecStopPost always restores the display
      systemd-run --user --quiet --collect --unit="$unit" -p IgnoreSIGPIPE=no \
        -p RuntimeMaxSec=12h -p ExecStopPost="$0 restore" \
        systemd-inhibit --what=sleep:idle --mode=block \
          --who="$unit" --why="Remote wake, waiting for keyboard input" \
          "$0" guard

      sleep 3
      if ! systemctl --user is-active --quiet "$unit.service" \
        || ! systemd-inhibit --list --no-legend | grep -q "$unit"; then
        echo "$unit failed to start:" >&2
        journalctl --user -u "$unit.service" -n 20 --no-pager >&2
        exit 1
      fi
      ;;

    guard)
      # Start listening first so a key pressed during setup is not missed
      exec 3< <(${pkgs.libinput}/bin/libinput debug-events)

      ready=
      for _ in $(seq 30); do
        if noctalia msg status >/dev/null 2>&1; then
          ready=1
          break
        fi
        sleep 1
      done
      if [[ -z $ready ]]; then
        echo "noctalia did not answer within 30s" >&2
        exit 1
      fi

      noctalia msg dpms-off || echo "dpms-off failed" >&2
      # Resume can switch the display back on once more
      sleep 5
      noctalia msg dpms-off || echo "dpms-off failed" >&2

      pressed=
      while IFS= read -r line <&3; do
        if [[ $line == *KEYBOARD_KEY* ]]; then
          pressed=1
          break
        fi
      done

      # The display is switched on again by ExecStopPost when this exits
      if [[ -z $pressed ]]; then
        echo "libinput exited before any key was seen" >&2
        exit 1
      fi
      ;;

    restore)
      noctalia msg dpms-on || echo "dpms-on failed" >&2
      ;;

    stop)
      systemctl --user stop "$unit.service"
      ;;

    *)
      echo "usage: wake-desktob-guard start|stop" >&2
      exit 1
      ;;
  esac
''
