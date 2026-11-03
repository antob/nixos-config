# `restic-vaultwarden` fetches the vaultwarden backup from the hyllan "tank"
# restic repository (offsite S3) for local restore, e.g. with `vaultwarden-local`.

{
  pkgs,
  lib,
  envFile,
}:
pkgs.writeShellScriptBin "restic-vaultwarden" ''
    set -eu

    RESTIC="${pkgs.restic}/bin/restic"
    VW_PATH="/mnt/restic-snapshot/tank/services/vaultwarden"

    usage() {
      cat >&2 <<'EOF'
  usage: restic-vaultwarden <command> [args]

  commands:
    snapshots               list snapshots in the tank backup
    ls [-l] [-r] <snapshot-id>
                            list files in the vaultwarden folder of a snapshot
                            (-r lists recursively)
    restore <snapshot-id> <target-dir>
                            restore the vaultwarden folder of a snapshot;
                            contents land directly in <target-dir>, owned by you

  examples:
    restic-vaultwarden snapshots
    restic-vaultwarden ls latest
    restic-vaultwarden ls -l <snapshot-id>
    restic-vaultwarden ls -r <snapshot-id>
    restic-vaultwarden restore <snapshot-id> /tmp/vaultwarden
  EOF
      exit 1
    }

    [ $# -ge 1 ] || usage
    cmd="$1"
    shift

    # Load the restic password and S3 credentials. The sops secret file is
    # root-only, so read it via sudo unless it is already readable (e.g. when
    # this script itself was invoked with sudo).
    secretFile="${envFile}"
    if [ ! -r "${envFile}" ]; then
      secretFile="$(mktemp)"
      trap 'rm -f "$secretFile"' EXIT
      if ! sudo cat "${envFile}" > "$secretFile" 2>/dev/null; then
        rm -f "$secretFile"
        trap - EXIT
        echo "error: cannot read restic credentials file: ${envFile}" >&2
        exit 1
      fi
    fi
    set -a
    # shellcheck disable=SC1090
    . "$secretFile"
    set +a
    if [ "$secretFile" != "${envFile}" ]; then
      rm -f "$secretFile"
      trap - EXIT
    fi

    export RESTIC_REPOSITORY="${lib.hyllanBackupsBaseRepo}/tank"

    case "$cmd" in
      snapshots)
        exec "$RESTIC" snapshots "$@"
        ;;
      ls)
        flags=""
        while [ "$#" -gt 1 ]; do
          case "$1" in
            -l) flags="$flags -l"; shift ;;
            -r) flags="$flags --recursive"; shift ;;
            *) break ;;
          esac
        done
        [ $# -eq 1 ] || usage
        # shellcheck disable=SC2086
        exec "$RESTIC" ls $flags "$1" "$VW_PATH"
        ;;
      restore)
        [ $# -eq 2 ] || usage
        targetDir="$2"
        mkdir -p "$targetDir"

        "$RESTIC" restore "$1" --target "$targetDir" --include "$VW_PATH"

        # Determine the real user: when this script is invoked via sudo,
        # $(id -u) reports root, but the restored files should be owned by the
        # invoking user (SUDO_USER).
        owner="$(id -u):$(id -g)"
        if [ -n "''${SUDO_USER:-}" ]; then
          owner="$(id -u "$SUDO_USER"):$(id -g "$SUDO_USER")"
        fi

        # Change owner first: restic restores the backup's original ownership.
        sudo chown -R "$owner" "$targetDir"

        # Strip the /mnt/restic-snapshot/tank/services/vaultwarden prefix so
        # the vault contents land directly at the root of the target dir.
        stage="$targetDir/mnt/restic-snapshot/tank/services/vaultwarden"
        if [ -d "$stage" ]; then
          shopt -s dotglob nullglob
          for entry in "$stage"/*; do
            [ -e "$entry" ] || continue
            mv "$entry" "$targetDir"/
          done
          shopt -u dotglob nullglob
          # Remove the now-empty prefix dirs; never the target dir itself.
          (cd "$targetDir" && rmdir -p mnt/restic-snapshot/tank/services/vaultwarden) || true
        fi
        ;;
      *)
        usage
        ;;
    esac
''
