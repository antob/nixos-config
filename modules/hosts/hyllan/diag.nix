{
  flake.modules.nixos.hyllan =
    { config, pkgs, ... }:
    {
      # Read-only diagnosis tools for the ZeroClaw ops agent. Runs as `agent` to reuse its sudo rules.
      systemd.services.hyllan-diag = {
        description = "Read-only diagnosis MCP server";
        wantedBy = [ "multi-user.target" ];
        path = [
          config.systemd.package
          config.boot.zfs.package
          pkgs.coreutils
          "/run/wrappers"
          "/etc/profiles/per-user/agent"
        ];
        serviceConfig = {
          ExecStart = "${pkgs.python3}/bin/python3 -I ${./_files/hyllan-diag/hyllan_diag.py}";
          Restart = "on-failure";
          RestartSec = 5;
          User = "agent";

          # sudo needs setuid and no user namespace, so NoNewPrivileges, PrivateUsers and a
          # capability bound are left out.
          PrivateTmp = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          ProtectClock = true;
          ProtectControlGroups = true;
          ProtectHostname = true;
          ProtectKernelModules = true;
          ProtectKernelTunables = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          RestrictNamespaces = true;
          RestrictRealtime = true;
          SystemCallArchitectures = "native";
        };
      };

      antob.agent-access.logUnits = [ "hyllan-diag" ];
    };
}
