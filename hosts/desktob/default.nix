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
        # host = "100.64.0.8";
        # openFirewall = true;
      };
      tailscale = {
        enable = true;
        keyfile = secrets.tailscale_auth_key.path;
      };
    };

    cli-apps = {
      llama-cpp = {
        enable = true;
        package = pkgs.llama-cpp-rocm;
      };
      llm-agents = enabled;
      voxtype = {
        enable = true;
        package = pkgs.voxtype-vulkan;
      };
      lumen = enabled;
    };

    hardware = {
      systemd-networking = {
        enable = true;
        hostName = "desktob";
        # Derived from `head -c 8 /etc/machine-id`
        hostId = "672fb36e";
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
      tailscale_auth_key = { };
      github_copilot_token = {
        # The sops file can be also overwritten per secret...
        # sopsFile = ./secrets.yaml;
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
