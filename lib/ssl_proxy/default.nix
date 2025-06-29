{ ... }:

{
  mkSslProxy = domain: target: {
    "${domain}".extraConfig = ''
      import deny_external_access

      tls {
        dns digitalocean {$DO_AUTH_TOKEN}
      }

      reverse_proxy ${target}
    '';
  };

  mkProxy = domain: target: {
    "${domain}".extraConfig = ''
      import deny_external_access

      tls internal
      reverse_proxy ${target}
    '';
  };
}
