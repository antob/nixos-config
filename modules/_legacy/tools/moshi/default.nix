{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.tools.moshi;
in
{
  options.antob.tools.moshi = with types; {
    enable = mkEnableOption "Whether or not to enable moshi.";
    authorizedKey = mkOpt (nullOr str) null "The authorized key to use for SSH access.";
  };

  config = mkIf cfg.enable {

    environment.systemPackages = with pkgs; [
      mosh
      moshi-hook
    ];

    antob.home.extraOptions = {
      xdg.configFile."moshi/config.toml".text = /* toml */ ''
        [gateway]
        always_on_discovery = true
        suppress_nested_agent_push = false
        usage_collection = true
      '';

      systemd.user.services.moshi-hook = {
        Unit = {
          Description = "Moshi hook daemon";
          After = [ "network-online.target" ];
        };

        Service = {
          Type = "simple";
          ExecStart = "${pkgs.moshi-hook}/bin/moshi-hook serve";
          Restart = "on-failure";
          RestartSec = 5;
        };

        Install = {
          WantedBy = [ "default.target" ];
        };
      };

    };

    antob.services.openssh.authorizedKeys = mkIf (cfg.authorizedKey != null) [
      cfg.authorizedKey
    ];

    networking.firewall.allowedUDPPortRanges = [
      {
        from = 60000;
        to = 61000;
      }
    ];

    antob.persistence.safe.home.directories = [
      ".local/state/moshi"
    ];
  };
}
