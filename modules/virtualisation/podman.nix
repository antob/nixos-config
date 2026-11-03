{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
in
{
  flake.modules.nixos.podman =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    let
      cfg = config.antob.podman;
    in
    {
      options.antob.podman = with types; {
        storageDriver = mkOpt str "overlay" "Podman storage driver.";
      };

      config = {
        antob.zsh.extraOhMyZshPlugins = [ "docker-compose" ];

        virtualisation.podman = {
          enable = true;
          autoPrune.enable = true;
          dockerCompat = true;
          dockerSocket.enable = true;
          # Required for containers under podman-compose to be able to talk to each other.
          defaultNetwork.settings.dns_enabled = true;
        };

        # Enable container name DNS for all Podman networks.
        networking.firewall.interfaces =
          let
            matchAll = if !config.networking.nftables.enable then "podman+" else "podman*";
          in
          {
            "${matchAll}".allowedUDPPorts = [ 53 ];
          };

        virtualisation = {
          oci-containers.backend = "podman";

          containers = {
            storage = {
              settings.storage.driver = cfg.storageDriver;
              rootful.settings.storage = {
                graphroot = "/var/lib/containers/storage";
                runroot = "/run/containers/storage";
              };
            };
            registries.settings = {
              unqualified-search-registries = [ "docker.io" ];
              registry = [
                { location = "docker.io"; }
                { location = "quay.io"; }
              ];
            };
          };
        };

        antob = {
          persistence = {
            directories = [
              "/var/lib/containers"
              "/run/containers"
            ];
            home.directories = [
              ".local/share/containers"
              ".config/containers"
            ];
          };

          user.extraGroups = [ "podman" ];
        };

        environment = {
          systemPackages = with pkgs; [
            podman-compose
          ];

          variables = {
            PODMAN_COMPOSE_WARNING_LOGS = "false";
          };

          shellAliases = {
            docker-compose = "podman compose";
          };
        };
      };
    };

}
