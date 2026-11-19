{
  flake.modules.nixos.hyllan =
    { config, pkgs, ... }:

    let
      subdomain = "syncthing";
      port = 8384;
      dataDir = "/mnt/tank/services/syncthing";
      guiAddress = "127.0.0.1:${toString port}";

      # Read-only Syncthing queries for the agent: fixed GET requests to the REST API, plus
      # du/find inside folder roots. The API key is read as root and never printed.
      syncthingCtl = pkgs.writeShellApplication {
        name = "syncthing-ctl";
        runtimeInputs = with pkgs; [
          coreutils
          curl
          findutils
          gnugrep
          gnused
          jq
        ];
        text = ''
          key=$(sed -n 's:.*<apikey>\(.*\)</apikey>.*:\1:p' "${config.services.syncthing.configDir}/config.xml")
          api() { curl -fsS -H "X-API-Key: $key" "http://${guiAddress}/rest/$1"; }
          uri() { jq -rn --arg v "$1" '$v | @uri'; }
          die() { echo "syncthing-ctl: $*" >&2; exit 2; }

          usage() {
            cat >&2 <<'EOF'
          usage: sudo syncthing-ctl <command> [args]
            status                      overview: devices, folders, out-of-sync peers, errors
            config                      folders (id, path, devices) and devices
            folder <folder>             full folder status, errors and completion per device
            errors                      system errors and folder pull errors
            ignores <folder>            loaded ignore patterns, with includes expanded
            pending                     devices and folders waiting to be accepted
            need <folder>               items this device still needs (first 100)
            remoteneed <folder> <dev>   items a peer still needs (dev: name or ID prefix)
            file <folder> <path>        index entry and availability of one file
            du <folder> [subpath]       sizes and newest mtime of entries under a folder path
            find <folder> <name>...     directories with these names, with size and newest mtime
          EOF
            exit 2
          }

          folder_path() {
            local p
            p=$(api config/folders | jq -r --arg f "$1" '.[] | select(.id == $f) | .path')
            [ -n "$p" ] || die "unknown folder: $1"
            realpath -- "$p"
          }

          device_id() {
            local id
            id=$(api config/devices | jq -r --arg d "$1" \
              '[.[] | select(.name == $d or (.deviceID | startswith($d)))] | if length == 1 then .[0].deviceID else empty end')
            [ -n "$id" ] || die "no unique device matches: $1"
            echo "$id"
          }

          completion() {
            local folder=$1 devices my names dev
            my=$(api system/status | jq -r .myID)
            names=$(api config/devices)
            devices=$(api config/folders | jq -r --arg f "$folder" '.[] | select(.id == $f) | [.devices[].deviceID] | join(" ")')
            read -ra devs <<<"$devices"
            for dev in "''${devs[@]}"; do
              [ "$dev" = "$my" ] && continue
              api "db/completion?folder=$(uri "$folder")&device=$dev" | jq -r --argjson n "$names" --arg d "$dev" \
                '"  \(($n[] | select(.deviceID == $d) | .name) // $d[0:7]): completion=\(.completion) needItems=\(.needItems) needDeletes=\(.needDeletes) remoteState=\(.remoteState)"'
            done
          }

          folder_errors() {
            api "folder/errors?folder=$(uri "$1")" | jq -r --arg f "$1" '.errors // [] | .[] | "\($f): \(.path): \(.error)"'
          }

          cmd=''${1:-status}
          [ $# -gt 0 ] && shift

          case "$cmd" in
            status)
              api system/version | jq -c '{version, os, arch}'
              api system/status | jq -c '{myID: .myID[0:7], uptime, startTime}'
              echo "-- devices"
              api system/connections | jq -r --argjson n "$(api config/devices)" '.connections | to_entries[] | .key as $id |
                "\(($n[] | select(.deviceID == $id) | .name) // $id[0:7]) connected=\(.value.connected) paused=\(.value.paused) \(.value.address)"'
              echo "-- folders"
              for f in $(api config/folders | jq -r '.[].id'); do
                api "db/status?folder=$(uri "$f")" | jq -r --arg f "$f" \
                  '"\($f) state=\(.state) needFiles=\(.needFiles) needDeletes=\(.needDeletes) needBytes=\(.needBytes) pullErrors=\(.pullErrors)"'
                completion "$f" | grep -v 'completion=100 ' || true
              done
              echo "-- errors"
              api system/error | jq -r '.errors // [] | .[] | "\(.when) \(.message)"'
              for f in $(api config/folders | jq -r '.[].id'); do folder_errors "$f" | head -20; done
              ;;
            config)
              api config/folders | jq '[.[] | {id, label, path, type, paused, rescanIntervalS, fsWatcherEnabled, versioning: .versioning.type, devices: [.devices[].deviceID[0:7]]}]'
              api config/devices | jq '[.[] | {id: .deviceID[0:7], name, addresses, paused, introducer, autoAcceptFolders}]'
              ;;
            folder)
              [ $# -eq 1 ] || usage
              api "db/status?folder=$(uri "$1")" | jq .
              completion "$1"
              folder_errors "$1"
              ;;
            errors)
              api system/error | jq -r '.errors // [] | .[] | "\(.when) \(.message)"'
              for f in $(api config/folders | jq -r '.[].id'); do folder_errors "$f"; done
              ;;
            ignores)
              [ $# -eq 1 ] || usage
              api "db/ignores?folder=$(uri "$1")" | jq '{error, ignore, expanded}'
              ;;
            pending)
              api cluster/pending/devices | jq .
              api cluster/pending/folders | jq .
              ;;
            need)
              [ $# -eq 1 ] || usage
              api "db/need?folder=$(uri "$1")&perpage=100" | jq '{total, progress: [.progress[].name], queued: [.queued[].name], rest: [.rest[].name]}'
              ;;
            remoteneed)
              [ $# -eq 2 ] || usage
              api "db/remoteneed?folder=$(uri "$1")&device=$(device_id "$2")&perpage=100" | jq '{total, files: [.files[] | {name, deleted, size}]}'
              ;;
            file)
              [ $# -eq 2 ] || usage
              api "db/file?folder=$(uri "$1")&file=$(uri "$2")" | jq .
              ;;
            du)
              if [ $# -lt 1 ] || [ $# -gt 2 ]; then usage; fi
              base=$(folder_path "$1")
              target=$(realpath -m -- "$base/''${2:-.}")
              case "$target" in "$base" | "$base"/*) ;; *) die "path outside folder: ''${2:-}" ;; esac
              du -h -d1 --time --time-style=+%F -- "$target" | sort -rh | head -60
              ;;
            find)
              [ $# -ge 2 ] || usage
              base=$(folder_path "$1")
              shift
              names=()
              for n in "$@"; do
                [[ "$n" =~ ^[A-Za-z0-9._-]+$ ]] || die "invalid name: $n"
                [ ''${#names[@]} -gt 0 ] && names+=(-o)
                names+=(-name "$n")
              done
              find "$base" -name .git -prune -o -type d \( "''${names[@]}" \) -print -prune |
                while read -r d; do du -s --time --time-style=+%F -- "$d"; done |
                sort -rn | numfmt --to=iec --from-unit=1024 --field=1 | sed "s:$base/::"
              ;;
            *) usage ;;
          esac
        '';
      };
    in
    {
      services = {
        syncthing = {
          enable = true;
          inherit dataDir;
          openDefaultPorts = true;
          overrideDevices = false;
          overrideFolders = false;
          inherit guiAddress;
        };
      };

      antob.agent-access = {
        logUnits = [ "syncthing" ];
        sudoPackages = [ syncthingCtl ];
      };

      fileSystems = {
        "${dataDir}" = {
          device = "zpool/syncthing";
          fsType = "zfs";
        };
      };

      systemd.tmpfiles.rules = [
        "d ${dataDir} 0700 syncthing syncthing -"
      ];

      services.caddy.antobProxies."${subdomain}" = {
        hostName = "127.0.0.1";
        inherit port;
        # Syncthing rejects non-localhost Host headers when the GUI listens on localhost
        extraConfig = ''
          header_up Host {upstream_hostport}
        '';
      };
    };
}
