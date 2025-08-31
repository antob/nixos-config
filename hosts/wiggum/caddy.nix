{ pkgs, ... }:
let
  email = "tob@antob.se";
in
{
  services.caddy = {
    enable = true;
    email = email;
    # acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  environment.systemPackages = [
    pkgs.caddy
  ];
}
