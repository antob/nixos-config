# shellcheck shell=bash
# Server mode runs on hyllan as root (the /run/secrets credentials are root-only); ssh-es there from elsewhere.
set -euo pipefail
export LC_ALL=C

HOST="hyllan.antob.net"
HOST_NAME="hyllan"

# Keep in sync with hosts/hyllan/restic-server.nix and backup.nix.
DATA_DIR="/mnt/tank/services/restic-server"
CLIENT_PW="/run/secrets/restic_client_backup_password"
S3_ENV="/run/secrets/restic_env_file"
S3_STALE_H=48
CLIENT_STALE_H=36

usage() {
  cat <<'EOF_USAGE'
Usage: backup-status [--color | --no-color]
       backup-status -c | --client [HOST...] [--color | --no-color]

Without --client: the status of all restic backups, seen from hyllan:
client repos on the REST server, hyllan's offsite S3 repos, and hyllan's
backup systemd units. Runs anywhere; it ssh-es to hyllan and runs there.

With --client: this host's backup, checked from here against the REST
server (no ssh). Name other hosts to check their repos as well; systemd
unit details are only available for this host.

Options:
  -c, --client           client view (see above)
  --color / --no-color   force colors on/off (default: on for a terminal,
                         off when NO_COLOR is set or output is piped)
  -h, --help             show this help

Exit code is 1 when any repo or unit is in a failed state. STALE alone
(e.g. a laptop that has been offline) is a warning, not a failure.
EOF_USAGE
}

mode=server
color=auto
hosts=()
for arg in "$@"; do
  case "$arg" in
    -h | --help) usage; exit 0 ;;
    -c | --client) mode=client ;;
    --color) color=always ;;
    --no-color) color=never ;;
    -*) echo "unknown option: $arg (see --help)" >&2; exit 2 ;;
    *) hosts+=("$arg") ;;
  esac
done
if [ "$mode" = server ] && [ "${#hosts[@]}" -gt 0 ]; then
  echo "host names are only accepted with --client (see --help)" >&2
  exit 2
fi
if [ "$color" = auto ]; then
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then color=always; else color=never; fi
fi
color_flag="--no-color"
[ "$color" = always ] && color_flag="--color"

if [ "$mode" = server ] && [ "$(hostname)" != "$HOST_NAME" ]; then
  # Remote stdout is never a tty, so pass on the local color choice.
  exec ssh "$HOST" "sudo bash -s -- $color_flag" <"${BASH_SOURCE[0]}"
fi
if [ "$(id -u)" -ne 0 ]; then
  args=("$color_flag")
  [ "$mode" = server ] || args+=(--client "${hosts[@]}")
  exec sudo bash "$(realpath "${BASH_SOURCE[0]}")" "${args[@]}"
fi

export PATH="$PATH:/run/current-system/sw/bin"

for bin in restic jq curl; do
  command -v "$bin" >/dev/null || {
    echo "error: $bin not in PATH on $(hostname)" >&2
    exit 1
  }
done

ERR_FILE=$(mktemp)
trap 'rm -f "$ERR_FILE"' EXIT

if [ "$color" = always ]; then
  BOLD=$'\e[1m' DIM=$'\e[2m' RED=$'\e[31m' GREEN=$'\e[32m' YELLOW=$'\e[33m' CYAN=$'\e[36m' RESET=$'\e[0m'
else
  BOLD="" DIM="" RED="" GREEN="" YELLOW="" CYAN="" RESET=""
fi

# STATUS stays last so its color codes don't break the alignment.
DISK_FMT='  %-15s %5s  %-16s  %8s  %8s  %8s  %s\n'
REPO_FMT='  %-15s %5s  %-16s  %8s  %8s  %s\n'
UNIT_FMT='  %-32s  %-16s  %7s  %-9s  %s\n'

section() {
  printf '\n%s%s%s  %s%s%s\n' "$BOLD$CYAN" "$1" "$RESET" "$DIM" "$2" "$RESET"
}
header() {
  local fmt="$1"
  shift
  # shellcheck disable=SC2059
  printf "$DIM${fmt%\\n}$RESET\\n" "$@"
}
badge() {
  case "$1" in
    OK) printf '%s✓ OK%s' "$GREEN" "$RESET" ;;
    RUNNING) printf '%s✓ running%s' "$GREEN" "$RESET" ;;
    STALE) printf '%s! STALE%s' "$YELLOW" "$RESET" ;;
    NO-RUNS) printf '%s- no runs yet%s' "$DIM" "$RESET" ;;
    *) printf '%s✗ %s%s' "$RED" "$1" "$RESET" ;;
  esac
}
detail() {
  local m="$1"
  [ "${#m}" -le 110 ] || m="${m:0:107}..."
  printf '  %s└─ %s%s\n' "$DIM" "$m" "$RESET"
}

now=$(date +%s)
n_ok=0
n_fail=0
stale_names=()
fail_names=()

tally() {
  case "$1" in
    OK | RUNNING) n_ok=$((n_ok + 1)) ;;
    STALE) stale_names+=("$2") ;;
    NO-RUNS) ;;
    *)
      n_fail=$((n_fail + 1))
      fail_names+=("$2")
      ;;
  esac
}

human() { numfmt --to=iec --format='%.1f' "$1"; }

span_str() {
  local s=$1
  if [ "$s" -lt 60 ]; then
    echo "${s}s"
  elif [ "$s" -lt 3600 ]; then
    echo "$((s / 60))m $((s % 60))s"
  elif [ "$s" -lt 86400 ]; then
    echo "$((s / 3600))h $(((s % 3600) / 60))m"
  else
    echo "$((s / 86400))d $(((s % 86400) / 3600))h"
  fi
}

err_msg() {
  local m
  m=$(grep '^{' "$1" 2>/dev/null |
    jq -r 'select(.message_type? == "exit_error") | .message' 2>/dev/null | head -n 1 || true)
  [ -n "$m" ] || m=$(grep -m 1 -v '^[[:space:]]*$' "$1" 2>/dev/null || true)
  [ -n "$m" ] || m="restic failed without an error message"
  printf '%s' "$m"
}

unit_env() {
  systemctl show -p Environment --value "$1" | tr ' ' '\n' | sed -n "s/^$2=//p" | head -n 1
}

# Fails fast instead of waiting out restic's retries when the server is down.
rest_check() {
  local url="${1#rest:}" code
  code=$(curl -s -o /dev/null -m 5 -I -w '%{http_code}' "$url/config" || true)
  case "$code" in
    200) ;;
    000) echo "REST server unreachable at ${url%/*} (is WireGuard up?)" ;;
    404) echo "no repository at $url" ;;
    *) echo "REST server answered HTTP $code for $url/config (see journalctl -u restic-rest-server on hyllan)" ;;
  esac
}

# pw is ".env" (S3 env file) or a password file; --no-lock avoids clashing with running backups.
run_restic() {
  local pw="$1" repo="$2"
  shift 2
  if [ "$pw" = ".env" ]; then
    (
      set -a
      # shellcheck disable=SC1090
      . "$S3_ENV"
      set +a
      exec restic -r "$repo" --no-lock "$@"
    )
  else
    restic -r "$repo" --password-file "$pw" --no-lock "$@"
  fi
}

repo_row() {
  local kind="$1" name="$2" repo="$3" pw="$4" stale_h="$5"
  local status="OK" count="-" latest="-" age="-" size="-" disk="-" msg=""
  local out newest idx epoch s

  if [ -z "$repo" ]; then
    status="ERR" msg="no RESTIC_REPOSITORY set on the systemd unit"
  elif [ -z "$pw" ]; then
    status="ERR" msg="no RESTIC_PASSWORD_FILE set on the systemd unit"
  elif [ "$kind" = rest ] && msg=$(rest_check "$repo") && [ -n "$msg" ]; then
    status="ERR"
  elif out=$(run_restic "$pw" "$repo" snapshots --json 2>"$ERR_FILE") &&
    jq -e 'type == "array"' <<<"$out" >/dev/null 2>&1; then
    count=$(jq -r 'length' <<<"$out")
    if [ "$count" -eq 0 ]; then
      status="EMPTY" msg="repository has no snapshots"
    else
      # Oldest first, and UTC offsets differ across DST, so compare epochs.
      newest=$(jq -r '.[].time' <<<"$out" | date -f - +%s |
        awk '{ print NR - 1 "\t" $1 }' | sort -t $'\t' -k 2,2n | tail -n 1)
      idx="${newest%%$'\t'*}"
      epoch="${newest#*$'\t'}"
      latest=$(date -d "@$epoch" '+%Y-%m-%d %H:%M')
      age=$(span_str $((now - epoch)))
      [ $(((now - epoch) / 3600)) -lt "$stale_h" ] || status="STALE"

      s=$(jq -r ".[$idx].summary.total_bytes_processed // empty" <<<"$out")
      if [ -z "$s" ]; then
        s=$(run_restic "$pw" "$repo" stats "$(jq -r ".[$idx].id" <<<"$out")" --json 2>/dev/null |
          jq -r '.total_size // empty' 2>/dev/null || true)
      fi
      [ -z "$s" ] || size=$(human "$s")
    fi
  else
    status="ERR" msg=$(err_msg "$ERR_FILE")
  fi

  if [ "$kind" = disk ]; then
    s=$(du -sb "$repo" 2>/dev/null | cut -f1 || true)
    [ -z "$s" ] || disk=$(human "$s")
    # shellcheck disable=SC2059
    printf "$DISK_FMT" "$name" "$count" "$latest" "$age" "$size" "$disk" "$(badge "$status")"
  else
    # shellcheck disable=SC2059
    printf "$REPO_FMT" "$name" "$count" "$latest" "$age" "$size" "$(badge "$status")"
  fi
  [ -z "$msg" ] || detail "$msg"
  tally "$status" "$name"
}

# From the journal, since systemd forgets unit results and timestamps on switch.
unit_last_run() {
  journalctl -u "$1" _PID=1 -o json -n 60 --no-pager 2>/dev/null | jq -rs '
    def ts: .__REALTIME_TIMESTAMP | tonumber / 1000000 | floor;
    (map(select(.JOB_TYPE == "start" and .JOB_RESULT != null)) | last) as $end
    | if $end == null then empty else
        (map(select(.MESSAGE_ID == "7d4958e842da4a758f6c1cdc7b36dcc5" and ts <= ($end | ts))) | last) as $start
        | [(($start // $end) | ts), ($end | ts), $end.JOB_RESULT] | @tsv
      end' 2>/dev/null || true
}

declare -A next_run=()
load_next_runs() {
  local unit next
  while IFS=$'\t' read -r unit next; do
    next_run[$unit]=$next
  done < <(systemctl list-timers --all --output=json --no-pager |
    jq -r '.[] | select(.activates | startswith("restic")) | [.activates, ((.next // 0) / 1000000 | floor)] | @tsv')
}

unit_row() {
  local u="$1" state last="-" took="-" next="-" msg="" status="" n
  local t_start="" t_end="" job_result=""
  state=$(systemctl show -p ActiveState --value "$u" 2>/dev/null || echo "unknown")
  IFS=$'\t' read -r t_start t_end job_result <<<"$(unit_last_run "$u")" || true

  if [ -n "$t_start" ]; then
    last=$(date -d "@$t_start" '+%Y-%m-%d %H:%M')
    took=$(span_str $((t_end - t_start)))
  fi
  n="${next_run[$u]:-0}"
  [ "$n" -le 0 ] || next=$(date -d "@$n" '+%a %H:%M')

  case "$state" in
    active)
      status="RUNNING" took="-"
      ;;
    activating | reloading)
      status="RUNNING" took="…"
      ;;
    failed)
      status="FAILED" msg="unit is in failed state; see journalctl -u $u"
      ;;
    *)
      if [ -z "$job_result" ]; then
        status="NO-RUNS"
      elif [ "$job_result" = "done" ]; then
        status="OK"
      else
        status="FAILED" msg="last run ended with '$job_result'; see journalctl -u $u"
      fi
      ;;
  esac

  # shellcheck disable=SC2059
  printf "$UNIT_FMT" "${u%.service}" "$last" "$took" "$next" "$(badge "$status")"
  [ -z "$msg" ] || detail "$msg"
  tally "$status" "${u%.service}"
}

list_units() {
  systemctl list-units --all --type=service --no-legend --no-pager --plain "$1" | awk '{print $1}' | sort -u
}

join() {
  local out="$1"
  shift
  for i in "$@"; do out+=", $i"; done
  printf '%s' "$out"
}

title() {
  printf '%sRestic backups%s  %s%s · %s%s\n' "$BOLD" "$RESET" "$DIM" "$1" "$(date '+%Y-%m-%d %H:%M %Z')" "$RESET"
}

summary() {
  echo
  printf '%sSummary%s  %s✓ %d ok%s' "$BOLD" "$RESET" "$GREEN" "$n_ok" "$RESET"
  if [ "${#stale_names[@]}" -gt 0 ]; then
    printf '   %s! %d stale (%s)%s' "$YELLOW" "${#stale_names[@]}" "$(join "${stale_names[@]}")" "$RESET"
  fi
  if [ "$n_fail" -gt 0 ]; then
    printf '   %s✗ %d failed (%s)%s' "$RED" "$n_fail" "$(join "${fail_names[@]}")" "$RESET"
  fi
  echo
  [ "${#stale_names[@]}" -eq 0 ] ||
    printf '%sSTALE = no snapshot within the schedule; for a laptop that is usually just being offline.%s\n' "$DIM" "$RESET"
}

server_main() {
  local dir u
  title "on $HOST_NAME"

  section "Client repos" "$DATA_DIR · stale after ${CLIENT_STALE_H}h"
  header "$DISK_FMT" REPO SNAPS LATEST AGE CONTENT "ON DISK" STATUS
  for dir in "$DATA_DIR"/*; do
    [ -d "$dir" ] || continue
    if [ ! -f "$dir/config" ]; then
      # shellcheck disable=SC2059
      printf "$DISK_FMT" "$(basename "$dir")" - - - - - "$(badge NOT-INITIALIZED)"
      detail "directory exists but holds no restic repository (no config file)"
      tally NOT-INITIALIZED "$(basename "$dir")"
      continue
    fi
    repo_row disk "$(basename "$dir")" "$dir" "$CLIENT_PW" "$CLIENT_STALE_H"
  done

  local backup_units s3_base=""
  mapfile -t backup_units < <(list_units 'restic-backups-*')
  for u in "${backup_units[@]}"; do
    s3_base=$(unit_env "$u" RESTIC_REPOSITORY)
    [ -z "$s3_base" ] || break
  done
  section "Offsite repos" "${s3_base%/*}/ · stale after ${S3_STALE_H}h"
  header "$REPO_FMT" REPO SNAPS LATEST AGE CONTENT STATUS
  for u in "${backup_units[@]}"; do
    local name="${u#restic-backups-}"
    repo_row s3 "${name%.service}" "$(unit_env "$u" RESTIC_REPOSITORY)" ".env" "$S3_STALE_H"
  done

  load_next_runs
  section "Systemd units" "last run from the journal · times in $(date +%Z)"
  header "$UNIT_FMT" UNIT "LAST RUN" TOOK NEXT STATUS
  while read -r u; do
    [ -z "$u" ] || unit_row "$u"
  done < <(list_units 'restic*')
}

client_main() {
  local u local_unit="" base pw self h show_units=no
  for u in $(list_units 'restic-backups-*'); do
    if [[ "$(unit_env "$u" RESTIC_REPOSITORY)" == rest:* ]]; then
      local_unit="$u"
      break
    fi
  done
  if [ -z "$local_unit" ]; then
    echo "error: $(hostname) has no client backup (antob.services.restic-backup)" >&2
    [ "$(hostname)" != "$HOST_NAME" ] || echo "run backup-status without --client for the server view" >&2
    exit 1
  fi
  base=$(unit_env "$local_unit" RESTIC_REPOSITORY)
  pw=$(unit_env "$local_unit" RESTIC_PASSWORD_FILE)
  self="${base##*/}"
  [ "${#hosts[@]}" -gt 0 ] || hosts=("$self")

  title "client view from $(hostname)"
  section "Client repos" "${base%/*}/ · stale after ${CLIENT_STALE_H}h"
  header "$REPO_FMT" REPO SNAPS LATEST AGE CONTENT STATUS
  for h in "${hosts[@]}"; do
    repo_row rest "$h" "${base%/*}/$h" "$pw" "$CLIENT_STALE_H"
    [ "$h" != "$self" ] || show_units=yes
  done

  if [ "$show_units" = yes ]; then
    load_next_runs
    section "Systemd units" "last run from the journal · times in $(date +%Z)"
    header "$UNIT_FMT" UNIT "LAST RUN" TOOK NEXT STATUS
    unit_row "$local_unit"
  fi
}

if [ "$mode" = server ]; then server_main; else client_main; fi
summary
[ "$n_fail" -eq 0 ]
