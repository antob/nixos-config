{ config, pkgs, ... }:

# Public cache key: nix-cache.antob.net-1:yrIa59Q68kwhCAU42Fh8p6FelDTyfcTWFEBDHRgY9C0=

let
  subdomain = "nix-cache";
  port = 5000;
  secrets = config.sops.secrets;
in
{
  services = {
    nix-serve = {
      enable = true;
      package = pkgs.nix-serve-ng;
      bindAddress = "127.0.0.1";
      port = port;
      secretKeyFile = secrets.nix-cache-private-key.path;
      extraParams = "--priority 50";
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
    };
  };

  sops.secrets.nix-cache-private-key = { };
}
