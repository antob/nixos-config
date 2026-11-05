{ inputs, config, ... }:
let
  inherit (config.aspects) nixos;
in
{
  # Shared by the personal machines (desktob, laptob).
  flake.modules.nixos.workstation =
    { config, ... }:
    let
      inherit (config.sops) secrets;
    in
    {
      imports = with nixos; [
        inputs.nur.modules.nixos.default
        common
        desktop
        persistence
        atuin
        checkpoint-vpn
        lumen
        clipperd
        restic-backup
        wireguard
        podman
        llm-agents
        networkd-vpn
        systemd-networking
        hyprland
        keyring
      ];

      antob = {
        neovim.localConfig = true;

        git.dirEmails = {
          "~/Projects/obit/" = "tobias.lindholm@oborgen.se";
          "~/Projects/puzzel/" = "tobias.lindholm@puzzel.com";
        };

        podman = {
          storageDriver = "btrfs";
        };

        wireguard = {
          privateKeyFile = secrets.wg0_private_key.path;
        };

        restic-backup = {
          paths = [
            "${config.antob.persistence.path}/safe"
          ];
          passwordFile = secrets.restic_client_backup_password.path;
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
        };
      };

      # Sops secrets; each host adds its own wg0_private_key sopsFile
      sops = {
        defaultSopsFile = ../hosts/common/secrets.yaml;
        secrets = {
          wg0_private_key = {
            owner = "systemd-network";
          };
          restic_client_backup_password = { };
          github_copilot_token = {
            owner = config.antob.user.name;
          };
          openrouter_api_key = {
            owner = config.antob.user.name;
          };
        };
      };
    };
}
