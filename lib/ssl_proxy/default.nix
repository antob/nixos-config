{ lib, ... }:

{
  mkSslProxy = domain: target:
    {
      "${domain}" = {
        forceSSL = true;
        enableACME = true;
        http2 = true;
        locations."/" = {
          proxyPass = target;
          proxyWebsockets = true;
          extraConfig = ''
            proxy_buffering off;
            proxy_headers_hash_max_size 512;
            proxy_headers_hash_bucket_size 128; 
          '';
        };
      };
    };
}

