{ inputs, config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  flake.modules.nixos.desktob =
    {
      pkgs,
      lib,
      config,
      ...
    }:
    with lib;
    let
      inherit (config.sops) secrets;
      wgIp = "10.64.1.6";
    in
    {
      antob = {
        neovim.localConfig = true;

        systemd-networking = {
          hostName = "desktob";
          # Derived from `head -c 8 /etc/machine-id`
          hostId = "672fb36e";
          enableWoL = true;
        };

        git.dirEmails = {
          "~/Projects/obit/" = "tobias.lindholm@oborgen.se";
          "~/Projects/puzzel/" = "tobias.lindholm@puzzel.com";
        };

        alacritty.fontSize = 13;

        kitty.fontSize = 13;

        podman = {
          storageDriver = "btrfs";
        };

        rescue = {
          resticEnvFile = secrets.restic_env_file.path;
        };

        wireguard = {
          address = "${wgIp}/24";
          privateKeyFile = secrets.wg0_private_key.path;
        };

        restic-backup = {
          paths = [
            "/persist/safe"
          ];
          passwordFile = secrets.restic_client_backup_password.path;
        };

        clipperd = {
          bindIp = wgIp;
        };

        voxtype = {
          package = pkgs.voxtype-vulkan;
        };

        llama-cpp = {
          package = pkgs.llama-cpp-vulkan;
        };

        ollama = {
          package = pkgs.ollama-vulkan;
          host = "0.0.0.0";
          openFirewallInterfaces = [ "wg0" ];
        };

        gaming.display = {
          width = 2560;
          height = 1440;
          refresh = 165;
        };

        persistence = {
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

      imports = [
        inputs.nur.modules.nixos.default
        nixos.persistence
        nixos.common
        nixos.desktop
        nixos.gaming
        nixos.atuin
        nixos.checkpoint-vpn
        nixos.ddcutil
        nixos.ollama
        nixos.tailscale
        nixos.llama-cpp
        nixos.lumen
        nixos.voxtype
        nixos.clipperd
        nixos.restic-backup
        nixos.wireguard
        nixos.rescue
        nixos.podman
        nixos.llm-agents
        nixos.networkd-vpn
        nixos.systemd-networking
        nixos.hyprland
        nixos.keyring
        nixos.base
      ];

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
    };

  flake.nixosConfigurations.desktob = inputs.nixpkgs.lib.nixosSystem { modules = [ nixos.desktob ]; };
}
