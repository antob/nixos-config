{
  flake.modules.nixos.hyllan =
    { config, pkgs, ... }:

    let
      inherit (config.sops) secrets;
      importer = pkgs.writers.writePython3 "greenely-statistics" {
        libraries = [ pkgs.python3Packages.websockets ];
        flakeIgnore = [ "E501" ];
      } (builtins.readFile ./_files/greenely-statistics.py);
    in
    {
      # Copies Greenely usage into Home Assistant long-term statistics (greenely:consumption).
      systemd = {
        timers.greenely-statistics = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "*-*-* *:20:00";
            Persistent = true;
          };
        };

        services.greenely-statistics = {
          onFailure = [ "notify-failure@%n.service" ];
          after = [ "podman-hass.service" ];
          environment.TZ_NAME = "Europe/Stockholm";
          serviceConfig = {
            Type = "oneshot";
            DynamicUser = true;
            ExecStart = importer;
            # Long-lived Home Assistant access token (admin, needed for recorder/import_statistics).
            LoadCredential = "token:${secrets.greenely_statistics_token.path}";
          };
        };
      };

      antob.agent-access = {
        units = [ "greenely-statistics" ];
        logUnits = [ "greenely-statistics" ];
      };

      sops.secrets.greenely_statistics_token = { };
    };
}
