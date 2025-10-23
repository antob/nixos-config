# Analyze postfix logs:
# $ nix shell nixpkgs#pflogsumm
# $ journalctl -u postfix --no-pager | pflogsumm --detail 10 --problems_first --verbose_msg_detail

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
    domains = [
      "antob.se"
      "antob.com"
    ];

    useUTF8FolderNames = true;

    enableImap = false;
    enableImapSsl = true;
    enableSubmission = false;
    enableSubmissionSsl = true;
    openFirewall = false; # Manually open required ports

    indexDir = "/var/lib/dovecot/indices";

    # A list of all login accounts. To create the password hashes, use
    # nix-shell -p mkpasswd --run 'mkpasswd -sm bcrypt'
    loginAccounts = {
      "tob@antob.se" = {
        hashedPasswordFile = secrets.tob_hashed_password.path;
        aliases = [
          "tobias@antob.se"
          "tobias.lindholm@antob.se"
          "info@antob.se"
          "abuse@antob.se"
          "postmaster@antob.se"
          "admin@antob.se"
          "tob@antob.com"
          "tobias@antob.com"
          "tobias.lindholm@antob.com"
          "info@antob.com"
          "abuse@antob.com"
          "postmaster@antob.com"
          "admin@antob.com"
        ];
        catchAll = [
          "antob.se"
          "antob.com"
        ];
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

  # Open required ports in firewall
  networking.firewall.allowedTCPPorts = [
    465 # SubmissionSsl
    993 # ImapSsl
    25 # SMTP (inbound delivery)
  ];

  # Setup SMTP-relay for Postfix
  services.postfix = {
    enable = true;
    config = {
      relayhost = [ "[mail.smtp2go.com]:587" ];
      smtp_sasl_auth_enable = "yes";
      smtp_sasl_password_maps = "texthash:${secrets.postfix_sasl_passwd.path}";
      smtp_sasl_security_options = "noanonymous";
      smtp_tls_security_level = lib.mkForce "may";
      smtp_destination_concurrency_limit = "20";
      header_size_limit = "4096000";
    };
  };

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
  sops.secrets = {
    tob_hashed_password = { };
    postfix_sasl_passwd = {
      owner = config.services.postfix.user;
    };
  };

  environment.systemPackages = [
  ];
}
