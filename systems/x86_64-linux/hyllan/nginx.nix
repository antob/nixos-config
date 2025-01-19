{ ... }:

{
  services.nginx = {
    enable = true;
    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;
    clientMaxBodySize = "500m";
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "tob@antob.se";
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];
}
