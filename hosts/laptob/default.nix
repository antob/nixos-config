{
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
    ../../modules
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

    tools.atuin = enabled;

    cli-apps.llm-agents = enabled;

    services.tailscale = {
      enable = true;
      keyfile = secrets.tailscale_auth_key.path;
    };

    hardware.systemd-networking = {
      enable = true;
      hostName = "laptob";
      # Derived from `head -c 8 /etc/machine-id`
      hostId = "ac07b4e8";
    };

    persistence = {
      enable = true;
      home.directories = [
        ".config/vice"
        ".RetroDebugger"
        ".C64Debugger"
        ".aws"
      ];
    };

    system.env = {
      GITHUB_COPILOT_TOKEN = "$(cat ${secrets.github_copilot_token.path})";
      OPENROUTER_API_KEY = "$(cat ${secrets.openrouter_api_key.path})";
    };
  };

  # Sops secrets
  sops = {
    defaultSopsFile = ../common/secrets.yaml;
    secrets = {
      tailscale_auth_key = { };
      github_copilot_token = {
        owner = "tob";
      };
      openrouter_api_key = {
        owner = "tob";
      };
    };
  };

  system.stateVersion = "22.11";
}
