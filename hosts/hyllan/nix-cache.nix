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
  secrets = config.sops.secrets;
  dataDir = "/mnt/tank/services/nix-cache";
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
    # "pikvm"
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
      if nix --store "$store" build ".#nixosConfigurations.$host.config.system.build.toplevel" --out-link "${rootsDir}/$host"; then
        echo "=== Build succeeded for host $host"
      else
        echo "=== Build failed for host $host, keeping its previous root"
        failed=1
      fi
    done

    if [ "$failed" -eq 0 ]; then
      echo "=== Running garbage collection"
      nix --store "$store" store gc || echo "Garbage collection failed"
    else
      echo "=== Skipping garbage collection: at least one host failed to build"
    fi

    exit 0
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

    caddy.antobProxies."${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
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
    group = group;
    extraGroups = [ "nixbld" ];
  };

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/nix-cache";
      fsType = "zfs";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 ${user} ${group} -"
    "d ${rootsDir} 0755 ${user} ${group} -"
    "d ${workDir} 0755 ${user} ${group} -"
  ];

  systemd.timers.nix-cache-build = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "03:00";
    };
  };

  systemd.services.nix-cache-build = {
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    path = with pkgs; [
      git
      nix
    ];
    serviceConfig = {
      Type = "oneshot";
      User = user;
      Group = group;
      TimeoutStartSec = "infinity";
      ExecStart = buildScript;
    };
    unitConfig.RequiresMountsFor = [ dataDir ];
  };
}
