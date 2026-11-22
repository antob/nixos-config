{
  flake.modules.nixos.hyllan =
    { pkgs, ... }:
    let
      python = pkgs.python3.withPackages (ps: [ ps.wyoming ]);
    in
    {
      # ZeroClaw's Telegram voice replies need an OpenAI-style TTS endpoint; Piper speaks Wyoming.
      systemd.services.tts-bridge = {
        description = "OpenAI-style TTS endpoint for Wyoming Piper";
        after = [ "wyoming-piper-home.service" ];
        wants = [ "wyoming-piper-home.service" ];
        wantedBy = [ "multi-user.target" ];
        path = [ pkgs.ffmpeg-headless ];
        serviceConfig = {
          ExecStart = "${python}/bin/python3 -I ${./_files/tts-bridge/tts_bridge.py}";
          Restart = "on-failure";
          RestartSec = 5;

          DynamicUser = true;
          PrivateTmp = true;
          PrivateDevices = true;
          PrivateUsers = true;
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

      antob.agent-access.logUnits = [ "tts-bridge" ];
    };
}
