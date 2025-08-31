{ pkgs, ... }:
let
  email = "tob@antob.se";
in
{
  services.caddy = {
    enable = true;
    email = email;
    # acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
    extraConfig = ''
      (logging) {
        log {
          output file /var/log/caddy/access.log {
            roll_size 10mb
            roll_keep 20
            roll_keep_for 720h
          }
          level info
        }
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  environment.systemPackages = [
    pkgs.caddy
  ];
}
