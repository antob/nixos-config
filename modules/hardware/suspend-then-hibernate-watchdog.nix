{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.antob.hardware.suspend-then-hibernate-watchdog;

  # Deferred check, run on a timer (never as a direct system-sleep hook).
  # $1 is the originating cycle's MainPID, scoping state to that cycle.
  checkScript = pkgs.writeShellScript "suspend-then-hibernate-watchdog-check" ''
    CYCLE_ID="$1"
    RETRY="''${2:-0}"
    MAX_RETRIES=10
    RETRY_DELAY_SEC=20
    STATE_FILE="/run/suspend-then-hibernate-watchdog.$CYCLE_ID.started-at"
    DELAY=${toString cfg.hibernateDelaySec}
    # Actual sleep duration usually lands a few seconds under the target.
    TOLERANCE=60

    log() {
      ${pkgs.util-linux}/bin/logger -t suspend-then-hibernate-watchdog "$1"
    }

    # A running Type=oneshot unit without RemainAfterExit shows
    # ActiveState=activating, not "active".
    sth_running() {
      state=$(${pkgs.systemd}/bin/systemctl show --property=ActiveState --value systemd-suspend-then-hibernate.service)
      [ "$state" = "active" ] || [ "$state" = "activating" ]
    }

    on_ac_power() {
      for f in /sys/class/power_supply/*/online; do
        dir=$(${pkgs.coreutils}/bin/dirname "$f")
        type=$(${pkgs.coreutils}/bin/cat "$dir/type" 2>/dev/null)
        [ "$type" = "Mains" ] || [ "$type" = "USB" ] || continue
        [ "$(${pkgs.coreutils}/bin/cat "$f" 2>/dev/null)" = "1" ] && return 0
      done
      return 1
    }

    # The check can fire when the user came back and is actively using
    # the machine; don't hibernate out from under an unlocked session.
    session_in_use() {
      for s in $(${pkgs.systemd}/bin/loginctl list-sessions --no-legend | ${pkgs.gawk}/bin/awk '{print $1}'); do
        type=$(${pkgs.systemd}/bin/loginctl show-session "$s" -p Type --value 2>/dev/null)
        [ "$type" = "wayland" ] || [ "$type" = "x11" ] || continue
        locked=$(${pkgs.systemd}/bin/loginctl show-session "$s" -p LockedHint --value 2>/dev/null)
        [ "$locked" = "yes" ] || return 0
      done
      return 1
    }

    # A concurrent cycle may be stealing this check's window; retry rather
    # than give up, so one lost race can't starve it forever.
    reschedule_retry() {
      next=$((RETRY + 1))
      if [ "$next" -gt "$MAX_RETRIES" ]; then
        log "cycle $CYCLE_ID: giving up after $MAX_RETRIES retries waiting for a clear window"
        ${pkgs.coreutils}/bin/rm -f "$STATE_FILE"
        exit 0
      fi
      # Use $0: interpolating this derivation's store path here would be
      # circular, and systemd-run passes the store path as argv[0].
      ${pkgs.systemd}/bin/systemd-run \
        --unit="suspend-then-hibernate-watchdog-check-$CYCLE_ID-$next.service" \
        --on-active="''${RETRY_DELAY_SEC}s" \
        --collect \
        "$0" "$CYCLE_ID" "$next" \
        >/dev/null 2>&1 || log "cycle $CYCLE_ID: failed to reschedule retry $next"
      exit 0
    }

    [ -f "$STATE_FILE" ] || exit 0

    if sth_running; then
      reschedule_retry
    fi

    started_at=$(${pkgs.coreutils}/bin/cat "$STATE_FILE")
    now=$(${pkgs.coreutils}/bin/date +%s)
    elapsed=$((now - started_at))

    if [ "$elapsed" -lt $((DELAY - TOLERANCE)) ]; then
      ${pkgs.coreutils}/bin/rm -f "$STATE_FILE"
      exit 0
    fi

    if on_ac_power; then
      log "cycle $CYCLE_ID slept ''${elapsed}s (>= ''${DELAY}s target) but on AC power, leaving to systemd's own HibernateOnACPower handling"
      ${pkgs.coreutils}/bin/rm -f "$STATE_FILE"
      exit 0
    fi

    if session_in_use; then
      log "cycle $CYCLE_ID slept ''${elapsed}s (>= ''${DELAY}s target) but an unlocked session is active - user appears to be back at the machine, not forcing hibernate"
      ${pkgs.coreutils}/bin/rm -f "$STATE_FILE"
      exit 0
    fi

    # Re-check: a fresh cycle may have started since the check above.
    if sth_running; then
      reschedule_retry
    fi

    ${pkgs.coreutils}/bin/rm -f "$STATE_FILE"
    log "cycle $CYCLE_ID slept ''${elapsed}s (>= ''${DELAY}s target) on battery without hibernating - forcing hibernate (systemd bug #38193 workaround)"

    # systemctl hibernate has no retry of its own; a transient failure
    # would otherwise leave this missed window uncaught.
    attempt=1
    while [ "$attempt" -le 3 ]; do
      if ${pkgs.systemd}/bin/systemctl hibernate; then
        exit 0
      fi
      log "cycle $CYCLE_ID: systemctl hibernate failed (attempt $attempt/3)"
      attempt=$((attempt + 1))
      [ "$attempt" -le 3 ] && ${pkgs.coreutils}/bin/sleep 5
    done
    log "cycle $CYCLE_ID: giving up after 3 failed hibernate attempts"
  '';
in
{
  options.antob.hardware.suspend-then-hibernate-watchdog = with types; {
    enable = mkEnableOption "Whether to force a hibernate if suspend-then-hibernate silently fails to do so on time.";
    hibernateDelaySec = mkOption {
      type = int;
      description = ''
        Must match systemd.sleep.settings.Sleep.HibernateDelaySec (in
        seconds); kept separate because sleep.conf's timespan syntax
        (e.g. "4h") isn't trivial to parse from a shell hook.
      '';
    };
  };

  config = mkIf cfg.enable {
    # Workaround for systemd bug #38193: after a periodic wake, systemd-sleep
    # can silently skip hibernation and end the cycle.
    #
    # The post hook runs before systemd-sleep's hibernate decision, so it
    # only schedules a deferred check, scoped to the cycle's MainPID so
    # newer cycles can't cancel it.
    environment.etc."systemd/system-sleep/suspend-then-hibernate-watchdog.sh" = {
      mode = "0755";
      text = ''
        #!/bin/sh
        # Use $SYSTEMD_SLEEP_ACTION, not $2: $2 stays "suspend-then-hibernate"
        # for all sub-phases; SYSTEMD_SLEEP_ACTION names the current one.
        # Below logind's 30s HoldoffTimeoutSec so the lid-retriggered
        # resuspend can't pause the check; above the ~5s slowest hook.
        GRACE_SEC=20

        log() {
          ${pkgs.util-linux}/bin/logger -t suspend-then-hibernate-watchdog "$1"
        }

        # Same activating-state gotcha as checkScript's sth_running.
        sth_running() {
          state=$(${pkgs.systemd}/bin/systemctl show --property=ActiveState --value systemd-suspend-then-hibernate.service)
          [ "$state" = "active" ] || [ "$state" = "activating" ]
        }

        cycle_id() {
          ${pkgs.systemd}/bin/systemctl show --property=MainPID --value systemd-suspend-then-hibernate.service
        }

        case "$1" in
          pre)
            sth_running || exit 0
            cycle_id=$(cycle_id)
            ${pkgs.coreutils}/bin/date +%s > "/run/suspend-then-hibernate-watchdog.$cycle_id.started-at"
            case "$SYSTEMD_SLEEP_ACTION" in
              hibernate)
                # A real hibernate is happening: cancel this cycle's pending check.
                log "cycle $cycle_id: hibernate starting, cancelling any pending check"
                ${pkgs.systemd}/bin/systemctl stop "suspend-then-hibernate-watchdog-check-$cycle_id.service" 2>/dev/null || true
                ${pkgs.coreutils}/bin/rm -f "/run/suspend-then-hibernate-watchdog.$cycle_id.started-at"
                ;;
            esac
            ;;
          post)
            # sth_running already excludes plain `systemctl suspend` cycles.
            sth_running || exit 0
            case "$SYSTEMD_SLEEP_ACTION" in
              suspend | suspend-after-failed-hibernate) ;;
              *) exit 0 ;;
            esac
            cycle_id=$(cycle_id)
            state_file="/run/suspend-then-hibernate-watchdog.$cycle_id.started-at"
            check_unit="suspend-then-hibernate-watchdog-check-$cycle_id.service"
            [ -f "$state_file" ] || exit 0

            # Replace any check already scheduled within this same cycle.
            ${pkgs.systemd}/bin/systemctl stop "$check_unit" 2>/dev/null || true
            if ${pkgs.systemd}/bin/systemd-run \
              --unit="$check_unit" \
              --on-active="''${GRACE_SEC}s" \
              --collect \
              ${checkScript} "$cycle_id" \
              >/dev/null 2>&1; then
              log "cycle $cycle_id: scheduled check for +''${GRACE_SEC}s"
            else
              log "cycle $cycle_id: systemd-run FAILED to schedule $check_unit - watchdog check will not run for this cycle"
            fi
            ;;
        esac
      '';
    };
  };
}
