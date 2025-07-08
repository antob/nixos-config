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
  };

  config = mkIf cfg.enable {
    virtualisation.docker.enable = true;

    antob = {
      user.extraGroups = [ "docker" ];
      tools.zsh.extraOhMyZshPlugins = [ "docker-compose" ];
      persistence.directories = [
        "/var/lib/docker"
        "/run/docker"
      ];
    };

    environment.systemPackages = [ pkgs.docker-compose ];
  };
}
