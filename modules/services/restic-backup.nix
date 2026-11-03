{ config, ... }:
let
  inherit (config.flake.lib) mkOpt mkBoolOpt;
in
{
  flake.modules.nixos.restic-backup =
    {
      config,
      lib,
      ...
    }:
    with lib;
    let
      cfg = config.antob.restic-backup;
    in
    {
      options.antob.restic-backup = with types; {
        serverAddress = mkOpt str "10.64.1.2" "Address of the restic REST server.";
        serverPort = mkOpt port 8000 "Port of the restic REST server.";
        repoName =
          mkOpt str config.networking.hostName
            "Repo name on the server. Defaults to the host name.";
        paths = mkOpt (listOf str) [ ] "Absolute paths to back up.";
        exclude =
          mkOpt (listOf str) [ ]
            "Patterns to exclude when backing up. See restic's exclude syntax.";
        interval =
          mkOpt str "12h"
            "Backup timer re-arm interval (systemd monotonic, see OnUnitInactiveSec).";
        initialize = mkBoolOpt true "Create the repository if it does not exist yet.";
        passwordFile = mkOpt (nullOr path) null "File containing the repository password.";
        afterService =
          mkOpt (nullOr str) "wg-quick-wg0.service"
            "Only run when the given server is up. Defaults to the Wireguard wg0 service.";
      };

      config = {
        assertions = [
          {
            assertion = cfg.passwordFile != null;
            message = "antob.restic-backup.passwordFile must be set.";
          }
        ];

        services.restic.backups.${cfg.repoName} = {
          repository = "rest:http://${cfg.serverAddress}:${toString cfg.serverPort}/${cfg.repoName}";
          inherit (cfg) passwordFile;
          inherit (cfg) paths;
          inherit (cfg) exclude;
          inherit (cfg) initialize;
          # Re-arms relative to the last completed run so a roaming unit keeps
          # retrying rather than waiting for a fixed wall-clock deadline.
          timerConfig = {
            OnBootSec = "15m";
            OnUnitInactiveSec = cfg.interval;
            RandomizedDelaySec = "1h";
          };
        };

        systemd.services = mkIf (cfg.afterService != null) {
          "restic-backups-${cfg.repoName}" = {
            after = [ cfg.afterService ];
            wants = [ cfg.afterService ];
          };
        };
      };
    };

}
