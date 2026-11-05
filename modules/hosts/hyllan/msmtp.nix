{
  flake.modules.nixos.hyllan =
    { config, pkgs, ... }:

    let
      inherit (config.sops) secrets;
      monCfg = config.antob.monitoring;
      inherit (monCfg) emailFrom;
      inherit (monCfg) emailTo;
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

      # Mails the unit status. Use with `onFailure = [ "notify-failure@%n.service" ];`
      systemd.services."notify-failure@" = {
        description = "Mail failure notice for %i";
        serviceConfig.Type = "oneshot";
        scriptArgs = "%i";
        script = ''
          ${pkgs.msmtp}/bin/sendmail -t <<EOF
          To: ${emailTo}
          From: ${emailFrom}
          Subject: [${config.networking.hostName}] $1 failed

          $(${pkgs.systemd}/bin/systemctl status --full --lines=50 "$1")
          EOF
        '';
      };

      sops.secrets.proton_smtp_token = { };
    };
}
