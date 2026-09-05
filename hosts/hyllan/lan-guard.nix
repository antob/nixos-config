{
  config,
  lib,
  ...
}:

let
  secrets = config.sops.secrets;
  subdomain = "lan-guard";
  port = 8680;
  dataDir = "/mnt/tank/services/lan-guard";
in
{
  virtualisation.oci-containers.containers = {
    "languard-backend" = {
      image = "ghcr.io/hillaliy/languard-backend:latest";
      environment = {
        "ALLOWED_HOSTS" = "${subdomain}.antob.net";
        "BACKEND_LISTEN_PORT" = "8660";
      };
      environmentFiles = [
        secrets.lan_guard_environment.path
      ];
      volumes = [
        "${dataDir}/data:/data:rw"
        "${dataDir}/static:/static:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=host"
        "--privileged"
      ];
    };

    "languard-frontend" = {
      image = "ghcr.io/hillaliy/languard-frontend:latest";
      environment = {
        "BACKEND_UPSTREAM" = "127.0.0.1:8660";
        "FRONTEND_LISTEN_ADDRESS" = ":${toString port}";
      };
      dependsOn = [
        "languard-backend"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=host"
      ];
    };

    "languard-scanner" = {
      image = "ghcr.io/hillaliy/languard-scheduler:latest";
      environment = {
        "ALLOWED_HOSTS" = "${subdomain}.antob.net";
      };
      environmentFiles = [
        secrets.lan_guard_environment.path
      ];
      volumes = [
        "${dataDir}/data:/data:rw"
        "${dataDir}/static:/static:rw"
      ];
      cmd = [
        "python"
        "-u"
        "manage.py"
        "run_scheduler"
        "--run-now"
      ];
      dependsOn = [
        "languard-backend"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network=host"
        "--privileged"
      ];
    };
  };

  systemd.services = {
    "podman-languard-backend" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      partOf = [
        "podman-compose-languard.target"
      ];
      wantedBy = [
        "podman-compose-languard.target"
      ];
    };

    "podman-languard-frontend" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      partOf = [
        "podman-compose-languard.target"
      ];
      wantedBy = [
        "podman-compose-languard.target"
      ];
    };

    "podman-languard-scanner" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      partOf = [
        "podman-compose-languard.target"
      ];
      wantedBy = [
        "podman-compose-languard.target"
      ];
    };
  };

  # Main service. When started, this will automatically create all resources
  # and start the containers. When stopped, this will teardown all resources.
  systemd.targets."podman-languard" = {
    unitConfig = {
      Description = "Lan Guard main target.";
    };
    wantedBy = [ "multi-user.target" ];
  };

  services.caddy.antobProxies."${subdomain}" = {
    hostName = "127.0.0.1";
    port = port;
  };

  systemd.tmpfiles.rules = [
    "d ${dataDir} 0750 root root -"
    "d ${dataDir}/data 0750 root root -"
    "d ${dataDir}/static 0750 root root -"
  ];

  sops.secrets.lan_guard_environment = { };
}
