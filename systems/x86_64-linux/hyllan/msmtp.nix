{ config, pkgs, ... }:

let
  secrets = config.sops.secrets;
  monCfg = config.antob.monitoring;
  emailFrom = monCfg.emailFrom;
  emailTo = monCfg.emailTo;
in
{
  programs.msmtp = {
    enable = true;
    setSendmail = true;
    defaults = {
      aliases = builtins.toFile "aliases" ''
        default: ${emailTo}
      '';
    };
    accounts.default = {
      auth = "plain";
      tls = "on";
      host = "smtp.protonmail.ch";
      port = "587";
      user = emailFrom;
      passwordeval = "${pkgs.coreutils}/bin/cat ${secrets.proton_smtp_token.path}";
      from = emailFrom;
    };
  };

  # Sops secrets
  sops = {
    defaultSopsFile = ./secrets.yaml;
    secrets.proton_smtp_token = { };
  };
}
