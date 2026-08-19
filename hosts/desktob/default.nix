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
      gaming = enabled;
    };

    desktop = {
      niri = enabled;
      addons.keyring = enabled;
    };

    virtualisation = {
      docker.enable = false;
      docker.storageDriver = "btrfs";

      podman.enable = true;
      podman.storageDriver = "btrfs";
    };

    tools = {
      atuin = enabled;
      alacritty.fontSize = 13;
      kitty.fontSize = 13;
    };

    services = {
      ollama = {
        enable = true;
        package = pkgs.ollama-vulkan;
        # host = "100.64.0.8";
        # openFirewall = true;
      };
      wireguard = {
        enable = true;
        address = "10.64.1.6/24";
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
      neovim.plugins = {
        copilotLua.enable = true;
        llamaVim.enable = false;
      };
    };

    hardware = {
      systemd-networking = {
        enable = true;
        hostName = "desktob";
        # Derived from `head -c 8 /etc/machine-id`
        hostId = "672fb36e";
      };
      # ddcutil = enabled;
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
  ];

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
