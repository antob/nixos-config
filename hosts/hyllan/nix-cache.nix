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
  buildHosts = [
    "desktob"
    "laptob-fw"
    "hyllan"
    "wiggum"
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

    for host in ${lib.concatStringsSep " " buildHosts}; do
      echo "=== Starting build for host $host"
      if nix --store "$store" build ".#nixosConfigurations.$host.config.system.build.toplevel" --no-link; then
        echo "=== Build succeeded for host $host"
      else
        echo "=== Build failed for host $host"
      fi
    done

    exit 0
  '';
in
{
  services = {
    nix-serve = {
      enable = true;
      # lix engine (nixpkgs unstable) crashes on aborted nar fetch. stable channel
      # binds classic nix 2.28.7 instead, no abort crash.
      package = pkgs.stable.nix-serve-ng;
      bindAddress = "127.0.0.1";
      port = port;
      secretKeyFile = secrets.nix-cache-private-key.path;
      extraParams = "--priority 30 --store ${dataDir}";
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
  systemd.services.nix-serve.serviceConfig.DynamicUser = lib.mkForce false;
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
