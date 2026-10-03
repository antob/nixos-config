{
  config,
  pkgs,
  lib,
  ...
}:

# Public cache key: nix-cache.antob.net-1:yrIa59Q68kwhCAU42Fh8p6FelDTyfcTWFEBDHRgY9C0=

let
  subdomain = "nix-cache";
  port = 5000;
  inherit (config.sops) secrets;
  dataDir = "/mnt/tank/services/nix-cache";
  # Pre-compressed file binary cache, served statically by Caddy in front of harmonia.
  # Harmonia streams NARs file by file from the HDD pool, which is seek-bound for paths
  # with many small files (e.g. nixpkgs source).
  cacheDir = "${dataDir}/binary-cache";
  user = "nix-serve";
  group = "nix-serve";

  repoUrl = "https://github.com/antob/nixos-config";
  workDir = "/tmp/nix-cache-build";
  rootsDir = "${dataDir}/roots";
  buildHosts = [
    "desktob"
    "laptob"
    "hyllan"
    "wiggum"
    "pidesk"
    "pihole"
    "pikvm"
  ];

  # Nightly pre-build of the target hosts' toplevels into the cache store.
  buildScript = pkgs.writeShellScript "nix-cache-build" ''
    set -u
    store="${dataDir}"
    work="${workDir}"

    rm -rf "$work"
    echo "=== Fetching nixos-config from ${repoUrl} into $work"
    if ! git clone --depth 1 --branch main "${repoUrl}" "$work"; then
      echo "Failed to clone ${repoUrl}"
      exit 1
    fi
    cd "$work"

    echo "=== Updating flake"
    if ! nix --store "$store" flake update; then
      echo "Failed to update flake"
      exit 1
    fi

    failed=0
    for host in ${lib.concatStringsSep " " buildHosts}; do
      echo "=== Starting build for host $host"
      if [ "$host" = "pikvm" ]; then
        echo "--- Pre-fetching PiKVM kernel from aostanin.cachix.org"
        ./scripts/fetch-pikvm-kernel.sh --store "$store" pikvm || echo "--- Pre-fetch failed, will build kernel from source if needed"
      fi
      if nix --store "$store" build ".#nixosConfigurations.$host.config.system.build.toplevel" --out-link "${rootsDir}/$host"; then
        echo "=== Build succeeded for host $host"
      else
        echo "=== Build failed for host $host, keeping its previous root"
        failed=1
      fi
    done

    echo "=== Copying roots and flake inputs to file binary cache"
    cacheUrl="file://${cacheDir}?compression=zstd&parallel-compression=true&secret-key=$CREDENTIALS_DIRECTORY/sign-key"
    roots=$(readlink ${rootsDir}/*)
    inputs=$(nix --store "$store" flake archive --json --dry-run | jq -r '.. | .path? // empty')
    if nix --store "$store" copy --to "$cacheUrl" $roots \
      && nix --store "$store" flake archive --to "$cacheUrl"; then
      echo "=== Pruning file binary cache"
      cd ${cacheDir} || exit 1
      if nix --store "$store" path-info -r $roots $inputs \
        | sed 's|^/nix/store/\([a-z0-9]*\)-.*|\1.narinfo|' | sort -u > "$work/live-narinfos" \
        && [ -s "$work/live-narinfos" ]; then
        find . -maxdepth 1 -name '*.narinfo' -printf '%f\n' | sort \
          | comm -23 - "$work/live-narinfos" | xargs -r rm -f
        find . -maxdepth 1 -name '*.narinfo' -exec sed -n 's|^URL: ||p' {} + | sort -u > "$work/live-nars"
        find nar -type f | sort | comm -23 - "$work/live-nars" | xargs -r rm -f
      else
        echo "Failed to compute live paths, skipping prune"
      fi
      cd "$work" || exit 1
    else
      echo "Failed to copy to file binary cache"
    fi

    # Publish the lock this run built from, so clients can pin to it for full cache hits
    # (`just up-cached`). Published even if some hosts failed; those hosts will miss.
    echo "=== Publishing flake.lock"
    cp flake.lock ${cacheDir}/.flake.lock.tmp && mv ${cacheDir}/.flake.lock.tmp ${cacheDir}/flake.lock

    if [ "$failed" -eq 0 ]; then
      echo "=== Running garbage collection"
      nix --store "$store" store gc || echo "Garbage collection failed"
    else
      echo "=== Skipping garbage collection: at least one host failed to build"
    fi

    exit 0
  '';

  # Serve narinfos and compressed NARs from the file cache when present, else fall
  # through to harmonia. nix-cache-info is left to harmonia (it carries the priority).
  staticCacheConfig = ''
    @nixCacheStatic {
      path *.narinfo /nar/*.nar.zst /flake.lock
      file {
        root ${cacheDir}
      }
    }
    handle @nixCacheStatic {
      root * ${cacheDir}
      file_server
    }
  '';
in
{
  services = {
    harmonia.cache = {
      enable = true;
      signKeyPaths = [ secrets.nix-cache-private-key.path ];
      settings = {
        bind = "127.0.0.1:${toString port}";
        real_nix_store = "${dataDir}/nix/store";
        priority = 30;
      };
    };

    caddy = {
      antobProxies."${subdomain}" = {
        hostName = "127.0.0.1";
        inherit port;
        extraHandleConfig = staticCacheConfig;
      };

      virtualHosts."nix-cache.hyllan.lan:80".extraConfig = ''
        ${staticCacheConfig}
        reverse_proxy 127.0.0.1:${toString port}
      '';
    };
  };

  sops.secrets.nix-cache-private-key = { };

  # Configure nix to allow building as the nix-serve user.
  # `qemu-user` is needed to build packages for other architectures.
  nix.settings = {
    extra-sandbox-paths = [ "${pkgs.qemu-user}" ];
    trusted-users = [ user ];
  };

  # Manually create the nix-serve user and group to be able to build as that user on hyllan.
  users.groups."${group}" = { };
  users.users."${user}" = {
    isNormalUser = true;
    inherit group;
    extraGroups = [ "nixbld" ];
  };

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/nix-cache";
      fsType = "zfs";
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d ${dataDir} 0755 ${user} ${group} -"
      "d ${rootsDir} 0755 ${user} ${group} -"
      "d ${cacheDir} 0755 ${user} ${group} -"
      "d ${workDir} 0755 ${user} ${group} -"
    ];

    timers.nix-cache-build = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "03:00";
      };
    };

    services.nix-cache-build = {
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      path = with pkgs; [
        bash
        git
        nix
        jq
      ];
      serviceConfig = {
        Type = "oneshot";
        User = user;
        Group = group;
        TimeoutStartSec = "infinity";
        ExecStart = buildScript;
        # Signing key for the file binary cache, readable by the unprivileged build user.
        LoadCredential = "sign-key:${secrets.nix-cache-private-key.path}";
      };
      unitConfig.RequiresMountsFor = [ dataDir ];
    };
  };
}
