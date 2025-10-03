{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
let
  cfg = config.antob.apps.thunderbird;
  secrets = config.sops.secrets;
in
{
  options.antob.apps.thunderbird = with types; {
    enable = mkEnableOption "Enable Thunderbird";
  };

  config = mkIf cfg.enable {
    antob = {
      home.extraOptions = {
        programs.thunderbird = {
          enable = true;
          profiles = {
            ${config.antob.user.name} = {
              isDefault = true;
              search = {
                default = "ddg";
                privateDefault = "ddg";
                force = true;
              };
            };
          };
          settings = {
            "mailnews.start_page.enabled" = false;
            "datareporting.healthreport.uploadEnabled" = false;
            "intl.regional_prefs.use_os_locales" = true;
            "mail.accounthub.enabled" = false;
            "mail.biff.play_sound" = false;
            "mail.compose.big_attachments.notify" = false;
            "mail.pane_config.dynamic" = 0;
            "mail.shell.checkDefaultClient" = false;
            "mail.spam.manualMark" = true;
            "mail.spellcheck.inline" = false;
            "mail.uidensity" = 2;
            "messenger.startup.action" = 0;
          };
        };

        accounts.email.accounts = {
          ${config.antob.user.name} = {
            enable = true;
            primary = true;
            realName = config.antob.user.fullName;
            address = config.antob.user.email;
            userName = config.antob.user.shortEmail;
            passwordCommand = "${pkgs.coreutils}/bin/cat ${secrets.email_account_password.path}";
            aliases = [
              "tob@antob.se"
              "tobias@antob.se"
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
            imap = {
              authentication = "plain";
              host = "mail.antob.se";
              port = 993;
              tls.enable = true;
            };
            smtp = {
              authentication = "plain";
              host = "mail.antob.se";
              port = 465;
              tls.enable = true;
            };
            thunderbird.enable = true;
          };
        };
      };

      persistence.home.directories = [ ".thunderbird" ];
    };

    sops.secrets.email_account_password = { };
  };
}
