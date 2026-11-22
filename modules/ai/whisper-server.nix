{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
in
{
  flake.modules.nixos.whisper-server =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    let
      cfg = config.antob.whisper-server;
    in
    {
      options.antob.whisper-server = with types; {
        package = mkOpt package pkgs.whisper-cpp "The whisper-cpp package to use.";
        model = mkOpt package (pkgs.fetchurl {
          name = "ggml-large-v3-turbo.bin";
          url = "https://huggingface.co/ggerganov/whisper.cpp/resolve/5359861c739e955e79d9a303bcbc70fb988958b1/ggml-large-v3-turbo.bin";
          sha256 = "1fc70f774d38eb169993ac391eea357ef47c88757ef72ee5943879b7e8e2bc69";
        }) "The ggml model file.";
        host = mkOpt str "127.0.0.1" "Address whisper-server listens on.";
        port = mkOpt port 8091 "Port whisper-server listens on.";
        language = mkOpt str "auto" "Spoken language, or auto to detect it per request.";
        allowedClients = mkOpt (attrsOf (listOf str)) { } ''
          Client addresses allowed to reach the port, per interface (e.g. { wg0 = [ "10.64.1.2" ]; }).
          whisper-server has no authentication, so access is limited by source address.
        '';
      };

      config = {
        systemd.services.whisper-server = {
          description = "whisper.cpp transcription server";
          after = [ "network.target" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            # --convert accepts OGG (Telegram voice notes); the package puts ffmpeg on PATH.
            ExecStart = concatStringsSep " " [
              "${cfg.package}/bin/whisper-server"
              "--host ${cfg.host}"
              "--port ${toString cfg.port}"
              "--model ${cfg.model}"
              "--language ${cfg.language}"
              "--convert"
              "--tmp-dir /tmp"
              "--flash-attn"
            ];
            Restart = "on-failure";
            RestartSec = 10;

            # The GPU render node is world-accessible, so no device or group access is needed.
            DynamicUser = true;
            PrivateTmp = true;
            PrivateDevices = false;
            PrivateUsers = true;
            PrivateMounts = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ProtectClock = true;
            ProtectControlGroups = true;
            ProtectHostname = true;
            ProtectKernelLogs = true;
            ProtectKernelModules = true;
            ProtectKernelTunables = true;
            ProtectProc = "invisible";
            ProcSubset = "pid";
            NoNewPrivileges = true;
            LockPersonality = true;
            MemoryDenyWriteExecute = true;
            RestrictNamespaces = true;
            RestrictRealtime = true;
            RestrictSUIDSGID = true;
            RemoveIPC = true;
            CapabilityBoundingSet = [ "" ];
            AmbientCapabilities = [ "" ];
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
            SystemCallArchitectures = "native";
            SystemCallFilter = [
              "@system-service"
              "~@privileged"
            ];
          };
        };

        networking.firewall.extraInputRules = concatStrings (
          mapAttrsToList (iface: clients: ''
            iifname "${iface}" ip saddr { ${concatStringsSep ", " clients} } tcp dport ${toString cfg.port} accept
          '') cfg.allowedClients
        );

        assertions = [
          {
            assertion = cfg.allowedClients == { } || config.networking.nftables.enable;
            message = "antob.whisper-server.allowedClients needs networking.nftables.enable.";
          }
        ];
      };
    };
}
