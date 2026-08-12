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
in
{
  services = {
    nix-serve = {
      enable = true;
      package = pkgs.nix-serve-ng;
      bindAddress = "127.0.0.1";
      port = port;
      secretKeyFile = secrets.nix-cache-private-key.path;
      extraParams = "--priority 50 --store ${dataDir}";
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
    };
  };

  sops.secrets.nix-cache-private-key = { };

  # Manually create the nix-serve user and group to be able to build as that user on hyllan.
  systemd.services.nix-serve.serviceConfig.DynamicUser = lib.mkForce false;
  users.groups."${group}" = { };
  users.users."${user}" = {
    group = group;
    isNormalUser = true;
  };

  fileSystems = {
    "${dataDir}" = {
      device = "zpool/nix-cache";
      fsType = "zfs";
    };
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0755 ${user} ${group} -"
  ];
}
