{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.antob.virtualisation.docker;
in
{
  options.antob.virtualisation.docker = with types; {
    enable = mkEnableOption "Whether or not to enable docker.";
    storageDriver = mkOpt (nullOr str) null "Docker storage driver.";
  };

  config = mkIf cfg.enable {
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
}
