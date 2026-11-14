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
        systemd-networking = {
          hostName = "desktob";
          # Derived from `head -c 8 /etc/machine-id`
          hostId = "672fb36e";
          enableWoL = true;
        };

        alacritty.fontSize = 13;

        kitty.fontSize = 13;

        rescue = {
          resticEnvFile = secrets.restic_env_file.path;
        };

        wireguard = {
          address = "${wgIp}/24";
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
          width = 3440;
          height = 1440;
          refresh = 165;
        };

        system.env = {
          OPENCODE_API_KEY = "$(cat ${secrets.opencode_api_key.path})";
          OPENAI_API_KEY = "$(cat ${secrets.openai_api_key.path})";
        };
      };

      imports = with nixos; [
        workstation
        gaming
        ddcutil
        solaar
        ollama
        llama-cpp
        voxtype
        rescue
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

      # eth0 is only a Wake-on-LAN cable to pidesk and never gets a lease.
      systemd.network.networks."10-lan".linkConfig.RequiredForOnline = mkForce "no";

      # Enable ROCm support in nixpkgs
      nixpkgs.config.rocmSupport = true;

      # Sops secrets
      sops.secrets = {
        wg0_private_key.sopsFile = ./secrets.yaml;
        restic_env_file = {
          sopsFile = ../common/secrets.yaml;
        };
        opencode_api_key = {
          owner = config.antob.user.name;
        };
        openai_api_key = {
          owner = config.antob.user.name;
        };
      };

      system.stateVersion = "22.11";
    };

  flake.nixosConfigurations.desktob = inputs.nixpkgs.lib.nixosSystem { modules = [ nixos.desktob ]; };
}
