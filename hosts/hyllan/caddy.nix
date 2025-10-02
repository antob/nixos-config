{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Define a new option for Antob proxies
  options.services.caddy.antobProxies =
    with lib;
    mkOption {
      type =
        with types;
        attrsOf (submodule {
          options = {
            hostName = mkOption {
              type = str;
              default = "127.0.0.1";
              description = "Canonical hostname for the server.";
            };
            port = mkOption {
              type = int;
              default = 80;
              description = "Port of the service on the server.";
            };
            extraConfig = mkOption {
              type = lines;
              default = "";
              description = ''
                Additional lines of configuration appended to this proxy host in the
                automatically generated `Caddyfile`.
              '';
            };
            extraHandleConfig = mkOption {
              type = lines;
              default = "";
              description = ''
                Additional lines of configuration appended within the handle block,
                but outside of the proxy block, for this proxy.
              '';
            };
          };
        });
      default = { };
      example = literalExpression ''
        {
          "photos" = {
            hostName = "127.0.0.1";
            port = 8080;
            extraConfig = '''
              encode gzip
            ''';
          };
        };
      '';
      description = ''
        Declarative specification of Antob proxies (<name>.antob.net) served by Caddy.
      '';
    };

  config =
    let
      email = "tob@antob.se";
      dataDir = "/mnt/tank/services/caddy";
      secrets = config.sops.secrets;
      cfg = config.services.caddy;
    in
    {
      services.caddy = with lib; {
        enable = true;
        email = email;
        # acmeCA = "https://acme-staging-v02.api.letsencrypt.org/directory";
        dataDir = dataDir;
        package = pkgs.caddy.withPlugins {
          plugins = [ "github.com/caddy-dns/digitalocean@v0.0.0-20250606074528-04bde2867106" ];
          hash = "sha256-dw99Ob9LwfQHFIEYQWbg9ozu9jbg8uVb11lkD8Z61fA=";
        };
        environmentFile = secrets.caddy_env_variables.path;
        extraConfig = ''
          (deny_external_access) {
            @from_router remote_ip 192.168.1.1
            abort @from_router

            @public_ip not remote_ip 192.168.1.0/24 127.0.0.1/8 100.64.0.0/24
            abort @public_ip
          }
        '';

        virtualHosts = mkIf (cfg.antobProxies != { }) {
          "*.antob.net" = {
            logFormat = ''
              output file ${cfg.logDir}/access-antob.log
            '';
            extraConfig = ''
              tls {
                dns digitalocean {$DO_AUTH_TOKEN}
              }

              import deny_external_access

            ''
            + builtins.concatStringsSep "\n" (
              mapAttrsToList (name: attrs: ''
                @${name} host ${name}.antob.net
                handle @${name} {
                  ${attrs.extraHandleConfig}
                  reverse_proxy {
                    to ${attrs.hostName}:${toString attrs.port}
                    ${attrs.extraConfig}
                  }
                }

              '') cfg.antobProxies
            )
            + ''
              handle {
                abort
              }
            '';
          };
        };
      };

      systemd.tmpfiles.rules = [
        "d ${dataDir} 0750 caddy caddy -"
      ];

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];

      # Caddy secrets.
      sops.secrets.caddy_env_variables = { };

      # Make custom Caddy package available in the system environment
      environment.systemPackages = [
        cfg.package
      ];
    };
}
