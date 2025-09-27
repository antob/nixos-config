{
  config,
  pkgs,
  lib,
  ...
}:
let
  secrets = config.sops.secrets;
  fqdn = "mail.antob.se";
  caddyCertDir = "/var/lib/caddy/.local/share/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${fqdn}";
  certDir = "/var/certs";
in
{
  mailserver = {
    enable = true;
    stateVersion = 3;
    fqdn = fqdn;
    domains = [ "antob.com" ];

    useUTF8FolderNames = true;

    enableImap = false;
    enableImapSsl = true;
    enableSubmission = false;
    enableSubmissionSsl = false;

    indexDir = "/var/lib/dovecot/indices";

    # A list of all login accounts. To create the password hashes, use
    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "tob@antob.com" = {
        hashedPasswordFile = secrets.tob_hashed_password.path;
        aliases = [
          "info@antob.com"
          "abuse@antob.com"
          "postmaster@antob.com"
        ];
        catchAll = [ "antob.com" ];
      };
    };

    certificateScheme = "manual";
    certificateFile = "${certDir}/${fqdn}.crt";
    keyFile = "${certDir}/${fqdn}.key";

    fullTextSearch = {
      enable = true;
      # index new email as they arrive
      autoIndex = true;
      enforced = "body";
      languages = [
        "sv"
      ];
    };
  };

  # Mailserver has its on DNS on port 53
  services.dnsmasq.enable = lib.mkForce false;

  # Create a systemd service to import certificates from Caddy to mailserver
  systemd.services.mailserver-import-certs = {
    description = "Import certs from Caddy to Mailserver.";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";

    script = ''
      ${pkgs.coreutils}/bin/mkdir -p ${certDir}
      ${pkgs.coreutils}/bin/cp -f ${caddyCertDir}/${fqdn}.crt ${certDir}/
      ${pkgs.coreutils}/bin/cp -f ${caddyCertDir}/${fqdn}.key ${certDir}/
      ${pkgs.coreutils}/bin/chown -R ${config.mailserver.vmailUserName}:${config.mailserver.vmailGroupName} ${certDir}
    '';
  };

  # Trigger cert import service when certificate changes
  systemd.paths.mailserver-import-certs = {
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      PathModified = "${caddyCertDir}/${fqdn}.crt";
      Unit = "mailserver-import-certs.service";
    };
  };

  # Secret values
  sops.secrets.tob_hashed_password = { };

  environment.systemPackages = [
  ];
}
