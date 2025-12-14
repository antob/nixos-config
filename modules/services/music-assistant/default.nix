{
  config,
  lib,
  pkgs,
  utils,
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    mkPackageOption
    types
    ;

  inherit (types)
    listOf
    enum
    str
    ;

  cfg = config.antob.services.music-assistant;

  finalPackage = cfg.package.override {
    inherit (cfg) providers;
  };

  # YouTube Music needs deno with JIT to solve yt-dlp challenges
  useYTMusic = lib.elem "ytmusic" cfg.providers;
in

{
  meta.buildDocsInSandbox = false;

  options.antob.services.music-assistant = {
    enable = mkEnableOption "Music Assistant";

    package = mkPackageOption pkgs "music-assistant" { };

    extraOptions = mkOption {
      type = listOf str;
      default = [
        "--config"
        "/var/lib/music-assistant"
      ];
      example = [
        "--log-level"
        "DEBUG"
      ];
      description = ''
        List of extra options to pass to the music-assistant executable.
      '';
    };

    providers = mkOption {
      type = listOf (enum cfg.package.providerNames);
      default = [ ];
      example = [
        "opensubsonic"
        "snapcast"
      ];
      description = ''
        List of provider names for which dependencies will be installed.
      '';
    };
  };

  config = mkIf cfg.enable {
    systemd.services.music-assistant = {
      description = "Music Assistant";
      documentation = [ "https://music-assistant.io" ];

      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];

      wantedBy = [ "multi-user.target" ];

      environment = {
        HOME = "/var/lib/music-assistant";
        PYTHONPATH =
          finalPackage.pythonPath
          + lib.optionalString (lib.elem "soundcloud" cfg.providers) ":${pkgs.soundcloudpy}/lib/python3.13/site-packages";
      };

      path =
        with pkgs;
        [
          lsof
        ]
        ++ lib.optionals (lib.elem "spotify" cfg.providers) [
          librespot-ma
        ]
        ++ lib.optionals (lib.elem "snapcast" cfg.providers) [
          snapcast
        ]
        ++ lib.optionals useYTMusic [
          deno
          ffmpeg
        ];

      serviceConfig = {
        ExecStart = utils.escapeSystemdExecArgs (
          [
            (lib.getExe cfg.package)
          ]
          ++ cfg.extraOptions
        );
        DynamicUser = true;
        StateDirectory = "music-assistant";
        AmbientCapabilities = "";
        CapabilityBoundingSet = [ "" ];
        DevicePolicy = "closed";
        LockPersonality = true;
        MemoryDenyWriteExecute = !useYTMusic;
        ProcSubset = "pid";
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_NETLINK"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged @resources"
        ]
        ++ lib.optionals useYTMusic [
          "@pkey"
        ];
        RestrictSUIDSGID = true;
        UMask = "0077";
      };
    };
  };
}
