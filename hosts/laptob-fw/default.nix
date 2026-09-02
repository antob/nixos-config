{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
with lib;
let
  secrets = config.sops.secrets;
  wgIp = "10.64.1.7";
in
{
  imports = with inputs; [
    nur.modules.nixos.default
    ./hardware.nix
  ];

  antob = {
    features = {
      common = enabled;
      laptop = enabled;
    };

    desktop = {
      niri = enabled;
      addons.keyring = enabled;
    };

    virtualisation = {
      docker.enable = true;
      podman.enable = false;
    };

    tools = {
      atuin = enabled;
      moshi = {
        enable = true;
        authorizedKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKnfv7tfiunPUyPl6xJmbzMPAOiYWYSSCANvSOLKrzSe laptob-moshi-key";
      };
    };

    cli-apps = {
      llm-agents = enabled;
      lumen = enabled;
    };

    services = {
      wireguard = {
        enable = true;
        address = "${wgIp}/24";
        privateKeyFile = secrets.wg0_private_key.path;
      };
      tailscale.enable = true;
      restic-backup = {
        enable = true;
        paths = [
          "/nix/persist/safe"
        ];
        passwordFile = secrets.restic_client_backup_password.path;
      };
      clipperd = {
        enable = true;
        bindIp = wgIp;
      };
    };

    hardware.systemd-networking = {
      enable = true;
      hostName = "laptob-fw";
      # Derived from `head -c 8 /etc/machine-id`
      hostId = "6278643e";
    };

    persistence = {
      enable = true;
      path = "/nix/persist";
      home.directories = [
        ".config/vice"
        ".RetroDebugger"
        ".C64Debugger"
        # ".nuget"
        # ".microsoft"
        # ".dotnet"
      ];
      safe.home.directories = [
        ".aws"
      ];
    };

    system.env = {
      GITHUB_COPILOT_TOKEN = "$(cat ${secrets.github_copilot_token.path})";
      OPENROUTER_API_KEY = "$(cat ${secrets.openrouter_api_key.path})";
      OPENCODE_API_KEY = "$(cat ${secrets.opencode_api_key.path})";
    };
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.amd
    mesa-demos
    s-tui
    calibre
  ];

  # Sops secrets
  sops = {
    defaultSopsFile = ../common/secrets.yaml;
    secrets = {
      wg0_private_key = {
        sopsFile = ./secrets.yaml;
        owner = "systemd-network";
      };
      restic_client_backup_password = { };
      github_copilot_token = {
        owner = "tob";
      };
      openrouter_api_key = {
        owner = "tob";
      };
      opencode_api_key = {
        owner = "tob";
      };
    };
  };

  system.stateVersion = "22.11";
}
