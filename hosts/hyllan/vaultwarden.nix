{ config, ... }:

let
  secrets = config.sops.secrets;
  subdomain = "vault";
  port = 8222;
  dataDir = "/mnt/tank/services/vaultwarden";
in
{
  services = {
    vaultwarden = {
      enable = true;
      backupDir = dataDir;
      environmentFile = secrets.vaultwarden_env_variables.path;
      config = {
        DOMAIN = "https://${subdomain}.antob.net";
        SIGNUPS_ALLOWED = false;
        ROCKET_ADDRESS = "127.0.0.1";
        ROCKET_PORT = port;
        ROCKET_LOG = "critical";
        SMTP_HOST = "mail.smtp2go.com";
        SMTP_FROM = "bitwarden@antob.se";
        SMTP_FROM_NAME = "Bitwarden server";
        SMTP_PORT = 587;
        SMTP_SECURITY = "starttls";
        PUSH_ENABLED = true;
        PUSH_RELAY_URI = "https://api.bitwarden.eu";
        PUSH_IDENTITY_URI = "https://identity.bitwarden.eu";
      };
    };

    caddy.antobProxies."${subdomain}" = {
      hostName = "127.0.0.1";
      port = port;
      extraHandleConfig = ''
        encode zstd gzip
      '';
      extraConfig = ''
        header_up X-Real-IP {remote_host}
      '';
    };
  };

  networking.firewall.allowedTCPPorts = [ port ];

  sops.secrets.vaultwarden_env_variables = { };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 ${config.users.users.vaultwarden.name} ${config.users.groups.vaultwarden.name} -"
  ];
}
