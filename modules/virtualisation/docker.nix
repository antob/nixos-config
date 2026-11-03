{ config, ... }:
let
  inherit (config.flake.lib) mkOpt;
in
{
  flake.modules.nixos.docker =
    {
      config,
      lib,
      pkgs,
      ...
    }:

    with lib;
    let
      cfg = config.antob.docker;
    in
    {
      options.antob.docker = with types; {
        storageDriver = mkOpt (nullOr str) null "Docker storage driver.";
      };

      config = {
        virtualisation.docker.enable = true;
        virtualisation.docker.storageDriver = cfg.storageDriver;

        antob = {
          user.extraGroups = [ "docker" ];
          tools.zsh.extraOhMyZshPlugins = [ "docker-compose" ];
          system.env.DOCKER_CONFIG = "$XDG_CONFIG_HOME/docker";

          persistence = {
            directories = [
              "/var/lib/docker"
              "/run/docker"
            ];
            home.directories = [
              ".config/docker"
            ];
          };
        };

        environment = {
          systemPackages = with pkgs; [
            docker-compose
          ];

          shellAliases = {
            docker-compose = "docker compose";
          };
        };
      };
    };

}
