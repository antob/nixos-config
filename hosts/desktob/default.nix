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
  wgIp = "10.64.1.6";
in
{
  imports = with inputs; [
    nur.modules.nixos.default
    ./hardware.nix
  ];

  antob = {
    features = {
      common = enabled;
      desktop = enabled;
      gaming = {
        enable = true;
        display = {
          width = 2560;
          height = 1440;
          refresh = 165;
        };
      };
    };

    desktop = {
      hyprland = enabled;
      addons.keyring = enabled;
    };

    virtualisation.podman.storageDriver = "btrfs";

    tools = {
      atuin = enabled;
      alacritty.fontSize = 13;
      kitty.fontSize = 13;
      rescue = {
        enable = true;
        resticEnvFile = secrets.restic_env_file.path;
      };
      checkpoint-vpn = enabled;
    };

    services = {
      ollama = {
        enable = true;
        package = pkgs.ollama-vulkan;
        host = "0.0.0.0";
        openFirewallInterfaces = [ "wg0" ];
      };
      wireguard = {
        enable = true;
        address = "${wgIp}/24";
        privateKeyFile = secrets.wg0_private_key.path;
      };
      tailscale.enable = true;
      restic-backup = {
        enable = true;
        paths = [
          "/persist/safe"
        ];
        passwordFile = secrets.restic_client_backup_password.path;
      };
      clipperd = {
        enable = true;
        bindIp = wgIp;
      };
    };

    cli-apps = {
      llama-cpp = {
        enable = true;
        package = pkgs.llama-cpp-vulkan;
      };
      llm-agents = enabled;
      voxtype = {
        enable = true;
        package = pkgs.voxtype-vulkan;
      };
      lumen = enabled;
      neovim.localConfig = true;
    };

    hardware = {
      systemd-networking = {
        enable = true;
        hostName = "desktob";
        # Derived from `head -c 8 /etc/machine-id`
        hostId = "672fb36e";
        enableWoL = true;
      };
      ddcutil = enabled;
    };

    persistence = {
      enable = true;
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
      OPENAI_API_KEY = "$(cat ${secrets.openai_api_key.path})";
    };
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.amd
    mesa-demos
    rocmPackages.rocminfo
    s-tui
    calibre
    spotify
  ];

  # Only use 5GHz WiFi. iwd only roams on weak signal, so once it lands on
  # 2.4GHz (e.g. after resume or a router reboot) it never moves back to 5GHz.
  # Keeping off 2.4GHz also leaves that band to the Bolt/Bluetooth mouse.
  networking.wireless.iwd.settings.Rank.BandModifier2_4GHz = "0.0";

  # Enable ROCm support in nixpkgs
  nixpkgs.config.rocmSupport = true;

  # Sops secrets
  sops = {
    defaultSopsFile = ../common/secrets.yaml;
    secrets = {
      wg0_private_key = {
        sopsFile = ./secrets.yaml;
        owner = "systemd-network";
      };
      restic_client_backup_password = { };
      restic_env_file = {
        sopsFile = ../common/secrets.yaml;
      };
      github_copilot_token = {
        owner = "tob";
      };
      openrouter_api_key = {
        owner = "tob";
      };
      opencode_api_key = {
        owner = "tob";
      };
      openai_api_key = {
        owner = "tob";
      };
    };
  };

  system.stateVersion = "22.11";
}
