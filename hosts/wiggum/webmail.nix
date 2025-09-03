{ ... }:
let
  siteDomain = "mail.antob.se";
in
{
  services.caddy.virtualHosts."${siteDomain}".extraConfig = ''
    respond "Hello, world!"
    import logging
  '';
}
